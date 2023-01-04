namespace Yrki.IoT.Gateway;

using Microsoft.Extensions.Options;

using Yrki.IoT.Contracts;
using Yrki.IoT.Gateway.Configuration;
using Yrki.IoT.Gateway.Services;
using Yrki.IoT.WMBus.WurthMetis;
public class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;
    private readonly MetisII _metisII;
    private readonly SendMessageToServerService _sendMessageToServerService;
    private GatewayConfiguration _gatewayConfiguration;

    public Worker(ILogger<Worker> logger, 
                  IOptions<GatewayConfiguration> options,
                  MetisII metisII,
                  SendMessageToServerService sendMessageToServerService)
    {
        _logger = logger;
        _metisII = metisII;
        _sendMessageToServerService = sendMessageToServerService;
        _metisII.MessageReceived += MetisII_MessageReceived;

        _gatewayConfiguration = options.Value;
    }

    private async void MetisII_MessageReceived(object? sender, byte[] bytes)
    {
        _logger.LogDebug(BitConverter.ToString(bytes));

        var message = new WMBusMessage{
            GatewayId = _gatewayConfiguration.GatewayId,
            HexMessage = BitConverter.ToString(bytes, 2), // Start on byte 2, since the two first bytes are the wurth prefix.
            ReceivedAt = DateTimeOffset.UtcNow
        };
        
        await _sendMessageToServerService.SendMessageAsync(message);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _metisII.ListenToMessages(_gatewayConfiguration.Port, _gatewayConfiguration.BaudRate, stoppingToken);
    }
}
