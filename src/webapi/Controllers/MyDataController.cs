using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.IO;  
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace webapi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class MyDataController : ControllerBase
    {

        /// The Azure Cosmos DB endpoint for running this GetStarted sample.
        private string _endpointUrl;

        /// The primary key for the Azure DocumentDB account.
        private string _primaryKey;

        // The Cosmos client instance
        private CosmosClient cosmosClient;

        // The database we will create
        private Database database;

        // The container we will create.
        private Container container;

        // The name of the database and container we will create
        private string _databaseId;
        private string _containerId;

        private string _storageConnectionString;
        private readonly ILogger<MyDataController> _logger;
        private readonly IConfiguration _configuration;
        const String folderName = "files";
        readonly String folderPath = Path.Combine(Directory.GetCurrentDirectory(), folderName);
        public MyDataController(ILogger<MyDataController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            _endpointUrl = _configuration["Cosmos:EndpointUrl"];
            _primaryKey = _configuration["Cosmos:PrimaryKey"];
            _databaseId = _configuration["Cosmos:DatabaseId"];
            _containerId = _configuration["Cosmos:ContainerId"];
            _storageConnectionString = $"DefaultEndpointsProtocol=https;AccountName={ _configuration["Storage:AccountName"] };AccountKey={ _configuration["Storage:PrimaryKey"] };EndpointSuffix=core.windows.net";
            this.cosmosClient = new CosmosClient(_endpointUrl, _primaryKey);
            this.database = this.cosmosClient.CreateDatabaseIfNotExistsAsync(_databaseId).Result;
            this.container = this.database.CreateContainerIfNotExistsAsync(_containerId, "/id").Result;
        }

        [HttpGet]
        public MyData Get(string id)
        {
            ItemResponse<MyData> myData = this.container.ReadItemAsync<MyData>(id, new PartitionKey(id)).Result;
            return myData;
        }

        [HttpPost]
        public async Task<IActionResult> Post(string name, IFormFile myFile)
        {
            var rng = new Random();
            var myData =  new MyData
            {
                id = Guid.NewGuid().ToString("N"),
                displayName = name,
                filePath = myFile.FileName
            };

            ItemResponse<MyData> myDataFile = this.container.CreateItemAsync<MyData>(myData, new PartitionKey(myData.id)).Result;

            return Ok($"Record with id: {myData.id} created.");
        }
    }
}
