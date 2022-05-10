[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)]
    [string] $ResourcePrefix,

    [Parameter(Mandatory=$true)]
    [string] $Location = "northeurope"
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
if ([string]::IsNullOrEmpty($env:AZURE_CLIENT_SECRET)) {
    $servicePrincipal = Get-AzADServicePrincipal -DisplayName $spName
    if (!$servicePrincipal) {
        $servicePrincipal = New-AzADServicePrincipal -DisplayName $spName -EndDate ([datetime]::Now.AddMinutes(60)) -SkipAssignment
        $env:AZURE_CLIENT_SECRET = $servicePrincipal.Secret | ConvertFrom-SecureString -AsPlainText
    }
    else {
        $newSpCred = $servicePrincipal | New-AzADServicePrincipalCredential -EndDate ([datetime]::Now.AddMinutes(60))
        $env:AZURE_CLIENT_SECRET = $newSpCred.Secret | ConvertFrom-SecureString -AsPlainText
    }
    $env:AZURE_CLIENT_ID = $servicePrincipal.ApplicationId
    $env:AZURE_TENANT_ID = $tenantId
    $env:AZURE_CLIENT_OBJECTID = $servicePrincipal.Id
}

$timestamp = Get-Date -f yyyyMMddTHHmmssZ
$armParams = @{
    keyVaultAccessObjectId = $env:AZURE_CLIENT_OBJECTID
    location = $Location
    prefix = $ResourcePrefix
    timestamp = $timestamp
}
$res = New-AzSubscriptionDeployment -Name "deploy-aind-ep02-$timestamp" `
                                     -TemplateFile $here/main.bicep `
                                     -TemplateParameterObject $armParams `
                                     -Location $armParams.location `
                                     -Verbose `
                                     -WhatIf:$WhatIfPreference

Write-Host "`nARM provisioning completed successfully"

$tenantFqdn = Get-AzTenant | ? { $_.Id -eq $tenantId } | Select -ExpandProperty Domains | Select -First 1
Write-Host "`nPortal Link: https://portal.azure.com/#@$tenantFqdn/resource/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourcePrefix-adventures-in-dapr/overview"
Write-Host "`nKey Vault Name: $($res.Outputs.keyVaultName.Value)"
Write-Host "`nKey Vault Name: $($res.Outputs.keyVaultSecretName.Value)"

Write-Host "`nSet the following environment variables in the console(s) used to launch the services:"
Write-Host "`$env:AZURE_CLIENT_ID = `"$($env:AZURE_CLIENT_ID)`""
Write-Host "`$env:AZURE_CLIENT_SECRET = `"$($env:AZURE_CLIENT_SECRET)`""
Write-Host "`$env:AZURE_TENANT_ID = `"$($env:AZURE_TENANT_ID)`""
