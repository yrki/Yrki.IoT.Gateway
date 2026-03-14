using Microsoft.Extensions.Configuration;

using Yrki.IoT.Gateway.Configuration;

namespace Tests;

public class GatewayConfigurationTests
{
    [Fact]
    public void Shall_bind_gateway_configuration_from_appsettings()
    {
        // Arrange
        var settingsPath = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory,
            "..",
            "..",
            "..",
            "..",
            "Yrki.IoT.Gateway",
            "appsettings.json"));

        var configuration = new ConfigurationBuilder()
            .AddJsonFile(settingsPath)
            .Build();

        // Act
        var gatewayConfiguration = configuration
            .GetSection("Yrki.IoT.Gateway")
            .Get<GatewayConfiguration>();

        // Assert
        Assert.NotNull(gatewayConfiguration);
        Assert.Equal("COM3", gatewayConfiguration.Port);
        Assert.Equal(9600, gatewayConfiguration.BaudRate);
        Assert.Equal("TESTGATEWAY", gatewayConfiguration.GatewayId);
        Assert.Equal("http://localhost:5000", gatewayConfiguration.ServerUrl);
        Assert.Equal("xxxyyyzzz", gatewayConfiguration.ApiKey);
    }
}
