using System.Text;
using System.Text.Json;

using Microsoft.Extensions.Options;

using Yrki.IoT.Contracts;
using Yrki.IoT.Gateway.Configuration;

namespace Yrki.IoT.Gateway.Services;

public class SendMessageToServerService
{
    private readonly ILogger<SendMessageToServerService> _logger;
    private readonly HttpClient _httpClient;

    public SendMessageToServerService(ILogger<SendMessageToServerService> logger, 
                                     HttpClient httpClient, 
                                     IOptions<GatewayConfiguration> options)
    {
        _logger = logger;
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri(options.Value.ServerUrl);
        _httpClient.DefaultRequestHeaders.Add("x-api-key", options.Value.ApiKey);
    }

    /// <summary>
    /// Send a message to the server with HTTP Post.
    /// </summary>
    public async Task SendMessageAsync(IMessage message)
    {
        _logger.LogInformation("Sending message to server");
        var serializedMessage = JsonSerializer.Serialize(message);
        
        await _httpClient.PostAsync("", new StringContent(serializedMessage, Encoding.UTF8, "application/json"));
    }
}