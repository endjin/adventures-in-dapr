namespace Simulation.Proxies;

using Dapr.Client;

public class DaprTrafficControlService : ITrafficControlService
{
    private readonly DaprClient _client;

    public DaprTrafficControlService(int camNumber)
    {
        var daprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3603";
        var daprGrpcPort = Environment.GetEnvironmentVariable("DAPR_GRPC_PORT") ?? "60003";
        _client = new DaprClientBuilder()
                        .UseHttpEndpoint($"http://localhost:{daprHttpPort}")
                        .UseGrpcEndpoint($"http://localhost:{daprGrpcPort}")
                        .Build();
    }

    public async Task SendVehicleEntryAsync(VehicleRegistered vehicleRegistered)
    {
        var eventJson = JsonSerializer.Serialize(vehicleRegistered);
        await _client.InvokeBindingAsync("entrycam", "create", eventJson);
    }

    public async Task SendVehicleExitAsync(VehicleRegistered vehicleRegistered)
    {
        var eventJson = JsonSerializer.Serialize(vehicleRegistered);
        await _client.InvokeBindingAsync("exitcam", "create", eventJson);
    }
}
