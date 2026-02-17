using System.Text;
using Google.Cloud.SecretManager.V1;

namespace FaltometroUfrgsBackend.Services;

internal interface ISecretProvider
{
    string GetDatabaseConnectionString();
}

internal class LocalDevSecretProvider : ISecretProvider
{
    internal LocalDevSecretProvider()
    {
        DotNetEnv.Env.TraversePath().Load();
    }

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
            .AccessSecretVersionAsync(new SecretVersionName(ProjectId, "database-creds-version", "latest"));
        _databaseConnectionString = Encoding.UTF8.GetString(dbCredsSecretResponse.Payload.Data.ToByteArray());
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public string GetDatabaseConnectionString() => _databaseConnectionString!;
}
