using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Storage.Blobs;

namespace Nest.App
{
    public class Program
    {
        private static void Main()
        {
            MainAsync().GetAwaiter().GetResult();
        }

        private static async Task MainAsync()
        {
            Console.WriteLine("!!! HI FROM DOTNET !!!");

            try
            {
                while (true)
                {
                    var client = await CreateContainer();
                    await CreateBlob(client);

                    await Task.Delay(10000);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);

                if(ex.InnerException != null) 
                {
                    Console.WriteLine(ex.InnerException.Message);
                }
            }
        }

        private static async Task<Azure.Response<BlobContainerClient>> CreateContainer()
        {
            var connectionString = await GetSecret();

            // Create a BlobServiceClient object which will be used to create a container client
            var blobServiceClient = new BlobServiceClient(connectionString.Value);

            //Create a unique name for the container
            string containerName = "quickstartblobs" + Guid.NewGuid().ToString();

            // Create the container and return a container client object
            var containerClient = await blobServiceClient.CreateBlobContainerAsync(containerName);
            return containerClient;
        }

        private static async Task CreateBlob(BlobContainerClient client)
        {
            // Create a local file in the ./data/ directory for uploading and downloading
            var fileName = "quickstart" + Guid.NewGuid().ToString() + ".txt";

            // Write text to the file
            await File.WriteAllTextAsync(fileName, "Hello, World!");

            // Get a reference to a blob
            var blobClient = client.GetBlobClient(fileName);

            Console.WriteLine("Uploading to Blob storage as blob:\n\t {0}\n", blobClient.Uri);

            // Upload data from the local file
            await blobClient.UploadAsync(fileName, true);
        }

        private static async Task<KeyVaultSecret> GetSecret()
        {
            var keyVaultName = Environment.GetEnvironmentVariable("KEY_VAULT_NAME");
            var kvUri = "https://" + keyVaultName + ".vault.azure.net";
            var client = new SecretClient(new Uri(kvUri), new DefaultAzureCredential());
            var secret = await client.GetSecretAsync("storage-account-connection-string");

            return secret.Value;
        }
    }
}
