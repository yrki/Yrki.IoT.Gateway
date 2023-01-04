using Yrki.IoT.Gateway;
using Yrki.IoT.Gateway.Configuration;
using Yrki.IoT.Gateway.Services;
using Yrki.IoT.WMBus.WurthMetis;

IHost host = Host.CreateDefaultBuilder(args)
    .ConfigureServices(services =>
    {
        services.AddHostedService<Worker>();
        services.AddHttpClient();

        services.AddSingleton<MetisII>();
        services.AddSingleton<SendMessageToServerService>();
        
        services.AddOptions<GatewayConfiguration>("Yrki.IoT.Gateway");
    })
    .Build();

host.Run();
