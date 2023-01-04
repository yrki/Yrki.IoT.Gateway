namespace Yrki.IoT.Gateway.Configuration
{
    public class GatewayConfiguration
    {
        /// <summary>
        /// The COM-port to connect to
        /// </summary>
        public required string Port { get; set; }
        
        /// <summary>
        /// The modules baud rate
        /// </summary>
        public required int BaudRate { get; set; }
        
        /// <summary>
        /// Unique Id of this gateway
        /// </summary>
        public required string GatewayId { get; set; }

        /// <summary>
        /// The url to post the messages to
        /// </summary>
        public required string ServerUrl { get; set; }

        /// <summary>
        /// The API-key for the receiving server
        /// </summary>
        /// <value></value>
        public required string ApiKey { get; set; }
    }
}