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

$armParams = @{
    location = $Location
    prefix = $ResourcePrefix
}

New-AzSubscriptionDeployment -Name "deploy-aind-ep01" `
                                     -TemplateFile $here/main.bicep `
                                     -TemplateParameterObject $armParams `
                                     -Location $armParams.location `
                                     -Verbose
