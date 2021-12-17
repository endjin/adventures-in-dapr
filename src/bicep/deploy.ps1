[CmdletBinding()]
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

$timestamp = Get-Date -f yyyyMMddTHHmmssZ
$armParams = @{
    location = $Location
    prefix = $ResourcePrefix
    timestamp = $timestamp
}
$res = New-AzSubscriptionDeployment -Name "deploy-aind-ep01-$timestamp" `
                                     -TemplateFile $here/main.bicep `
                                     -TemplateParameterObject $armParams `
                                     -Location $armParams.location `
                                     -Verbose

Write-Host "`nARM provisioning completed successfully"

$tenantFqdn = Get-AzTenant | ? { $_.Id -eq (Get-AzContext).Tenant.Id } | Select -ExpandProperty Domains | Select -First 1
Write-Host "`nPortal Link: https://portal.azure.com/#@$tenantFqdn/resource/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourcePrefix-adventures-in-dapr/overview"
Write-Host "`nService Bus Connection String: $($res.Outputs.servicebus_connection_string.Value)"
