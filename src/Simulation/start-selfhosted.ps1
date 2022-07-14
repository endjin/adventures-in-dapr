dapr run `
    --app-id simulation `
    --dapr-http-port 3603 `
    --dapr-grpc-port 60003 `
    --config ../dapr/config/config.yaml `
    --components-path ../dapr/components `
    dotnet run