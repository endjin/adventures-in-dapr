namespace Simulation.Proxies;

using Dapr.Client;

public class DaprTrafficControlService : ITrafficControlService
{
    private readonly DaprClient _client;

    public DaprTrafficControlService(int camNumber)
    {
        _client = new DaprClientBuilder().Build();
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
