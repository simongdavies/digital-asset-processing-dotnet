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
            this.cosmosClient = new CosmosClient(_endpointUrl, _primaryKey);
            this.database = this.cosmosClient.CreateDatabaseIfNotExistsAsync(_databaseId).Result;
            this.container = this.database.CreateContainerIfNotExistsAsync(_containerId, "/filePath").Result;
        }

        [HttpGet]
        public MyData Get()
        {
            var rng = new Random();
            var myData =  new MyData
            {
                id = Guid.NewGuid().ToString("N"),
                filePath = "media.mp3"
            };

            ItemResponse<MyData> myDataFile = this.container.CreateItemAsync<MyData>(myData, new PartitionKey(myData.filePath)).Result;
            return myData;
        }

        [HttpPost]
        public async Task<IActionResult> UploadFile(IFormFile myFile)
        {
            using (var fileContentStream = new MemoryStream())
            {  
                await myFile.CopyToAsync(fileContentStream);
                await System.IO.File.WriteAllBytesAsync(Path.Combine(folderPath, myFile.FileName), fileContentStream.ToArray());
            }  

            return Ok($"File is uploaded Successfully");
        }
    }
}
