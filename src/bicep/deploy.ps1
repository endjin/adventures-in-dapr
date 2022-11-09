#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="5.1.0" }

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)]
    [string] $ResourcePrefix,

    [Parameter(Mandatory=$true)]
    [string] $Location = "northeurope",

    [switch] $SkipProvision
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 4.0
$here = Split-Path -Parent $PSCommandPath

if (!(Get-AzContext)) {
    Write-Host "Login to Azure PowerShell before continuing"
    Connect-AzAccount
}

Get-AzContext | Format-List | Out-String | Write-Host
Read-Host "Press <RETURN> to confirm deployment into the above Azure subscription, or <CTRL-C> to cancel"
$tenantId = (Get-AzContext).Tenant.Id

# Setup a service principal with a short-lived password
$spName = "$ResourcePrefix-adventures-in-dapr-sp"
$servicePrincipal = Get-AzADServicePrincipal -DisplayName $spName
if (!$servicePrincipal) {
    Write-Host "Creating service principal"
    $servicePrincipal = New-AzADServicePrincipal -DisplayName $spName -EndDate ([datetime]::Now.AddMinutes(120))
    $env:AZURE_CLIENT_SECRET = $servicePrincipal.PasswordCredentials[0].SecretText
}
else {
    Write-Host "Refreshing service principal secret"
    $servicePrincipal.PasswordCredentials | ForEach-Object {
        Remove-AzADServicePrincipalCredential -ObjectId $servicePrincipal.Id -KeyId $_.KeyId -Verbose
    }
    $newSpCred = $servicePrincipal | New-AzADServicePrincipalCredential -EndDate ([datetime]::Now.AddMinutes(120)) -Verbose
    $env:AZURE_CLIENT_SECRET = $newSpCred.SecretText
}
$env:AZURE_CLIENT_ID = $servicePrincipal.appId
$env:AZURE_TENANT_ID = $tenantId
$env:AZURE_CLIENT_OBJECTID = $servicePrincipal.id

if (!$SkipProvision) {
    $timestamp = Get-Date -f yyyyMMddTHHmmssZ
    $armParams = @{
        keyVaultAccessObjectId = $env:AZURE_CLIENT_OBJECTID
        location = $Location
        prefix = $ResourcePrefix
        timestamp = $timestamp
    }
    $res = New-AzSubscriptionDeployment -Name "deploy-aind-ep03-$timestamp" `
                                        -TemplateFile $here/main.bicep `
                                        -TemplateParameterObject $armParams `
                                        -Location $armParams.location `
                                        -Verbose `
                                        -WhatIf:$WhatIfPreference

    Write-Host "`nARM provisioning completed successfully"

    $tenantFqdn = Get-AzTenant | ? { $_.Id -eq $tenantId } | Select -ExpandProperty Domains | Select -First 1
    Write-Host "`nPortal Link: https://portal.azure.com/#@$tenantFqdn/resource/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourcePrefix-adventures-in-dapr/overview"
    Write-Host "`nKey Vault Name: $($res.Outputs.keyVaultName.Value)"
    Write-Host "`nServiceBus Connection String Secret Name: $($res.Outputs.serviceBusConnectionStringSecretName.Value)"
    Write-Host "`nStorage Account Access Key Secret Name: $($res.Outputs.storageAccountAccessKeySecretName.Value)"
}

