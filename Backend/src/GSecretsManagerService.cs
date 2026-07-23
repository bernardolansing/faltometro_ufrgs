using System.Text;
using Google.Cloud.SecretManager.V1;

namespace FaltometroUfrgsBackend;

internal static class GSecretsManagerService
{
    private const string ProjectId = "faltometro-ufrgs";
    
    private static SecretManagerServiceClient? _client;
    private static string _dbConnectionString = null!;

    internal static async Task InitAsync()
    {
        _client = await SecretManagerServiceClient.CreateAsync();
        _dbConnectionString = await GetSecretAsync("database-creds-secret");
    }
    
    internal static IConfigurationBuilder AddGoogleSecretsManager(this IConfigurationBuilder builder)
    {
        builder.Properties.Add("ConnectionString:DefaultConnection", _dbConnectionString);
        
        return builder;
    }

    internal static string GetDbConnectionString() => _dbConnectionString;

    private static async Task<string> GetSecretAsync(string secretName)
    {
        var secretVersion = new SecretVersionName(ProjectId, secretName, "latest");
        var response = await _client!.AccessSecretVersionAsync(secretVersion);
        return Encoding.UTF8.GetString(response.Payload.Data.ToByteArray());
    }
}

[TestClass]
public class GSecretsManagerServiceTests
{
    [TestMethod]
    public async Task TestSecretsRetrieval()
    {
        // This test fetches the production secrets, be careful.
        // Obviously, it'll only work if you have a working and authorized Google credential available in the
        // environment.
        await GSecretsManagerService.InitAsync();
        Console.WriteLine("DB connection string: " + GSecretsManagerService.GetDbConnectionString());
    }
}