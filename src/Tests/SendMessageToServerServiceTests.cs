using System.Net;
using System.Text;

namespace Tests;

public class SendMessageToServerServiceTests
{
    [Fact]
    public void Shall_configure_http_client_from_gateway_configuration()
    {
        // Arrange
        var handler = new CapturingHttpMessageHandler();
        var httpClient = new HttpClient(handler);
        var options = Options.Create(CreateGatewayConfiguration());

        // Act
        _ = new SendMessageToServerService(
            NullLogger<SendMessageToServerService>.Instance,
            httpClient,
            options);

        // Assert
        Assert.Equal(new Uri("http://localhost:5000"), httpClient.BaseAddress);
        Assert.True(httpClient.DefaultRequestHeaders.TryGetValues("x-api-key", out var values));
        Assert.Contains("xxxyyyzzz", values);
    }

    [Fact]
    public async Task Shall_post_serialized_message_to_server()
    {
        // Arrange
        var handler = new CapturingHttpMessageHandler();
        var httpClient = new HttpClient(handler);
        var service = new SendMessageToServerService(
            NullLogger<SendMessageToServerService>.Instance,
            httpClient,
            Options.Create(CreateGatewayConfiguration()));
        var message = new WMBusMessage
        {
            GatewayId = "gateway-1",
            HexMessage = "AA-BB-CC",
            ReceivedAt = new DateTimeOffset(2024, 01, 02, 03, 04, 05, TimeSpan.Zero)
        };

        // Act
        await service.SendMessageAsync(message);

        // Assert
        Assert.NotNull(handler.Request);
        Assert.Equal(HttpMethod.Post, handler.Request.Method);
        Assert.Equal("http://localhost:5000/", handler.Request.RequestUri?.ToString());
        Assert.True(handler.Request.Headers.TryGetValues("x-api-key", out var values));
        Assert.Contains("xxxyyyzzz", values);

        var content = await handler.Request.Content!.ReadAsStringAsync();
        Assert.Contains("\"GatewayId\":\"gateway-1\"", content);
        Assert.Contains("\"HexMessage\":\"AA-BB-CC\"", content);
        Assert.Contains("\"ReceivedAt\":\"2024-01-02T03:04:05+00:00\"", content);
    }

    private static GatewayConfiguration CreateGatewayConfiguration() =>
        new()
        {
            Port = "COM3",
            BaudRate = 9600,
            GatewayId = "TESTGATEWAY",
            ServerUrl = "http://localhost:5000",
            ApiKey = "xxxyyyzzz"
        };

    private sealed class CapturingHttpMessageHandler : HttpMessageHandler
    {
        public HttpRequestMessage? Request { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            Request = request;

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(string.Empty, Encoding.UTF8, "application/json")
            });
        }
    }
}
