using System.Text;
using Google.Cloud.SecretManager.V1;

namespace FaltometroUfrgsBackend;

/// <summary>
/// Helper class for Google Secrets Manager. It is entirely async, and can be used with or without ASP.NET context.
/// Before anything, await <c>InitAsync()</c> for the secrets to be loaded from GSM. For ASP-less usage, call getter
/// methods like <c ref="GetDbConnectionString">GetDbConnectionString()</c>. For ASP.NET servers, bind it to the app
/// configuration using <c>builder.Configuration.AddGoogleSecretsManager()</c>. Secrets are then going to be exposed in
/// app config. 
/// </summary>
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
    
    /// <summary>
    /// Populates ASP.NET app configuration with secrets coming from Secrets Manager.
    /// 
    /// <list type="bullet">
    ///     <item>Database connection string -> ConnectionString:DefaultConnection</item>
    /// </list>
    /// </summary>
    internal static IConfigurationBuilder AddGoogleSecretsManager(this IConfigurationBuilder builder)
    {
        var secretsToAdd = new Dictionary<string, string?>
        {
            ["ConnectionStrings:DefaultConnection"] = _dbConnectionString
        };
        builder.AddInMemoryCollection(secretsToAdd);
        
        return builder;
    }

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
        var config = new ConfigurationBuilder()
            .AddGoogleSecretsManager()
            .Build();
        Assert.IsNotNull(config.GetConnectionString("DefaultConnection"));
    }
}