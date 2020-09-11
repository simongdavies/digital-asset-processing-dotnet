using System;
using System.Collections.Generic;
using Microsoft.Azure.Documents;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace function
{
    public static class CosmosDBTrigger
    {
        [FunctionName("CosmosDBTrigger")]
        public static void Run([CosmosDBTrigger(
            databaseName: "media",
            collectionName: "metadata",
            ConnectionStringSetting = "AzureWebJobsStorage",
            LeaseCollectionName = "leases",
            CreateLeaseCollectionIfNotExists=true)]IReadOnlyList<Document> input, ILogger log)
        {
            if (input != null && input.Count > 0)
            {
                log.LogInformation("Documents modified " + input.Count);
                log.LogInformation("First document Id " + input[0].Id);
            }

            // The documents fetched from CosmosDB are availabel in the 'input' list of type 'Document'

        }
    }
}
