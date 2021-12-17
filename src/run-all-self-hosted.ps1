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

    # Start the vehicle registration service
    Write-Host "Starting Vehicle Registration Service"
    cd $here/VehicleRegistrationService
    dapr stop vehicleregistrationservice 2>&1 | Out-Null
    & cmd.exe --% /c start "VRS" pwsh.exe -noexit -noprofile -f ./start-selfhosted.ps1

    # Start the fine collection service
    Write-Host "Starting Fine Collection Service"
    cd $here/FineCollectionService
    dapr stop finecollectionservice 2>&1 | Out-Null
    & cmd.exe --% /c start "FCS" pwsh.exe -noexit -noprofile -f ./start-selfhosted.ps1

    # Start the traffic control service
    Write-Host "Starting Traffic Control Service"
    cd $here/TrafficControlService
    dapr stop trafficcontrolservice 2>&1 | Out-Null
    & cmd.exe --% /c start "TCS" pwsh.exe -noexit -noprofile -f ./start-selfhosted.ps1
}
finally {
    Pop-Location
}