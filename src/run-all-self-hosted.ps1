#Requires -PSEdition Core
$here = Split-Path -Parent $PSCommandPath

Push-Location $here/Infrastructure

try {
    # Restart the infrastructure docker containers
    Write-Host "Restarting infrastructure containers..."
    & .\stop-all.ps1 2>&1 | Out-Null
    & .\start-all.ps1 2>&1 | Out-Null

    # wait for rabbit-mq
    Write-Host "Waiting for RabbitMQ to become ready..."
    $rabbitReady = $false
    while (!$rabbitReady) {
        $isReady = & docker logs dtc-rabbitmq | Select-String "Server startup complete"
        if (!$isReady) {
            Start-Sleep -Seconds 10
        }
        else {
            $rabbitReady = $true
        }
    }

    # Terminate any existing service instances
    Get-Process |
        Where-Object { $_.ProcessName -match "pwsh" } | 
        Select-Object Id,CommandLine | 
        Where-Object { $_.CommandLine -imatch "pwsh.*-noprofile -c .*/start-selfhosted.ps1" } |
        ForEach-Object { Stop-Process -Force $_.Id; Start-Sleep -Seconds 5 }

    # Start the vehicle registration service
    Write-Host "Starting Vehicle Registration Service"
    cd $here/VehicleRegistrationService
    dapr stop vehicleregistrationservice 2>&1 | Out-Null
    Start-Process -FilePath pwsh -ArgumentList @("-noprofile", '-c & { $host.ui.RawUI.WindowTitle=\"VRS\"; ./start-selfhosted.ps1 }')

    # Start the fine collection service
    Write-Host "Starting Fine Collection Service"
    cd $here/FineCollectionService
    dapr stop finecollectionservice 2>&1 | Out-Null
    Start-Process -FilePath pwsh -ArgumentList @("-noprofile", '-c & { $host.ui.RawUI.WindowTitle=\"FCS\"; ./start-selfhosted.ps1 }')

    # Start the traffic control service
    Write-Host "Starting Traffic Control Service"
    cd $here/TrafficControlService
    dapr stop trafficcontrolservice 2>&1 | Out-Null
    Start-Process -FilePath pwsh -ArgumentList @("-noprofile", '-c & { $host.ui.RawUI.WindowTitle=\"TCS\"; ./start-selfhosted.ps1 }')
}
finally {
    Pop-Location
}