using System.Text;
using Google.Cloud.SecretManager.V1;

namespace FaltometroUfrgsBackend.Services;

internal interface ISecretProvider
{
    string GetDatabaseConnectionString();
}

internal class LocalDevSecretProvider : ISecretProvider
{
    public string GetDatabaseConnectionString()
    {
        var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
        var dbPort = Environment.GetEnvironmentVariable("DB_PORT");
        var dbUser = Environment.GetEnvironmentVariable("DB_USER");
        var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
        
        if (dbHost == null || dbPort == null || dbUser == null || dbPassword == null)
            throw new Exception("At least one of the Database credentials are null. Please populate .env with the " +
                                "connection details");
        
        return $"Host={dbHost};Port={dbPort};Database=faltometro_ufrgs_db;Username={dbUser};Password={dbPassword};" +
               $"Include Error Detail=true;";
    }
}

internal class ProductionSecretProvider : ISecretProvider, IHostedService
{
    private const string ProjectId = "faltometro-ufrgs";
    
    private string? _databaseConnectionString;
    
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        Console.WriteLine("Starting ProductionSecretProvider service");
        var secretManagerClient = await SecretManagerServiceClient.CreateAsync(cancellationToken);
        
        var dbCredsSecretResponse = await secretManagerClient
            .AccessSecretVersionAsync(new SecretVersionName(ProjectId, "database-creds-secret", "latest"));
        _databaseConnectionString = Encoding.UTF8.GetString(dbCredsSecretResponse.Payload.Data.ToByteArray());
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public string GetDatabaseConnectionString() => _databaseConnectionString!;
}

[TestClass]
public class SecretProviderTests
{
    public TestContext TestContext { get; set; }
    
    [TestMethod]
    public void TestLocalDevSecretsProvider()
    {
        var provider = new LocalDevSecretProvider();
        
        // First we check if it breaks if at least one of the required environment variables are not set.
        Environment.SetEnvironmentVariable("DB_HOST", null);
        Assert.Throws<Exception>(provider.GetDatabaseConnectionString);
        
        // Now we'll set the variables and hope for a correctly assembled connection string.
        Environment.SetEnvironmentVariable("DB_HOST", "DB_HOST");
        Environment.SetEnvironmentVariable("DB_PORT", "DB_PORT");
        Environment.SetEnvironmentVariable("DB_USER", "DB_USER");
        Environment.SetEnvironmentVariable("DB_PASSWORD", "DB_PASSWORD");
        const string expected = "Host=DB_HOST;Port=DB_PORT;Database=faltometro_ufrgs_db;Username=DB_USER;" +
                                "Password=DB_PASSWORD;Include Error Detail=true;";
        var retrieved = provider.GetDatabaseConnectionString();
        Assert.AreEqual(expected, retrieved);
    }
    
    // Careful: this one is going to retrieve the actual production DB connection string. This will only be possible if
    // a service account is set up in your machine.
    [TestMethod]
    public async Task TestProductionSecretProvider()
    {
        var provider = new ProductionSecretProvider();
        await provider.StartAsync(TestContext.CancellationToken);
        Assert.IsNotEmpty(provider.GetDatabaseConnectionString());
    }
}
