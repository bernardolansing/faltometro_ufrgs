using System.Text;
using Google.Cloud.SecretManager.V1;
using Microsoft.IdentityModel.Tokens;
using JsonSerializer = System.Text.Json.JsonSerializer;

namespace FaltometroUfrgsBackend.Services;

public interface ISecretProviderService
{
    string GetDatabaseConnectionString();
    
    SupabaseSecrets GetSupabaseSecrets();
}

public class LocalDevSecretProviderService : ISecretProviderService
{
    public LocalDevSecretProviderService()
    {
        DotNetEnv.Env.TraversePath().Load();
        Console.WriteLine("Starting LocalDevSecretProvider service");
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

    public SupabaseSecrets GetSupabaseSecrets()
    {
        var supabaseProjectId = Environment.GetEnvironmentVariable("SUPABASE_PROJECT_ID");
        var supabaseKey = Environment.GetEnvironmentVariable("SUPABASE_KEY");
        var adminUserId = Environment.GetEnvironmentVariable("ADMIN_USER_ID");
        var supabaseJwkStr = Environment.GetEnvironmentVariable("SUPABASE_JWK_STR");
        
        if (supabaseProjectId == null || supabaseKey == null || adminUserId == null || supabaseJwkStr == null)
            throw new Exception("At least one of the Supabase fields was not provided. Please populate .env with" +
                                "Supabase credentials");

        return new SupabaseSecrets
        {
            ProjectId = supabaseProjectId,
            Key = supabaseKey,
            AdminUserId = adminUserId,
            TokenIssuerKey = new JsonWebKey(supabaseJwkStr)
        };
    }
}

public class ProductionSecretProviderService : ISecretProviderService
{
    private const string ProjectId = "faltometro-ufrgs";
    
    private string? _databaseConnectionString;
    private SupabaseSecrets? _supabaseSecrets;

    internal async Task InitAsync()
    {
        Console.WriteLine("Starting ProductionSecretProvider service");
        var secretManagerClient = await SecretManagerServiceClient.CreateAsync();
        
        var dbSecretVersion = new SecretVersionName(ProjectId, "database-creds-secret", "latest");
        var dbSecretTask = secretManagerClient.AccessSecretVersionAsync(dbSecretVersion);

        var supabaseSecretVersion = new SecretVersionName(ProjectId, "supabase-secrets", "latest");
        var supabaseSecretTask = secretManagerClient.AccessSecretVersionAsync(supabaseSecretVersion);
        
        await Task.WhenAll(dbSecretTask, supabaseSecretTask);
        var dbCredsResponse = dbSecretTask.Result;
        var supabaseCredsResponse = supabaseSecretTask.Result;
        
        _databaseConnectionString = Encoding.UTF8.GetString(dbCredsResponse.Payload.Data.ToByteArray());
        _supabaseSecrets = JsonSerializer
            .Deserialize<SupabaseSecrets>(supabaseCredsResponse.Payload.Data.ToByteArray());
    }

    public string GetDatabaseConnectionString() => _databaseConnectionString!;
    
    public SupabaseSecrets GetSupabaseSecrets() => _supabaseSecrets!;
}

public class SupabaseSecrets
{
    public static readonly string[] TokenAudiences = ["authenticated"];
    
    public required string ProjectId { get; init; }
    public required string Key { get; init; }
    public required string AdminUserId { get; init; }
    public required JsonWebKey TokenIssuerKey { get; init; }

    internal string GetProjectUrl() => $"https://{ProjectId}.supabase.com";

    internal string GetTokenIssuerUrl() => $"https://{ProjectId}.supabase.co/auth/v1";
}

[TestClass]
public class SecretProviderTests
{
    [TestMethod]
    public void TestLocalDevSecretsProvider()
    {
        var provider = new LocalDevSecretProviderService();
        
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

        provider.GetSupabaseSecrets(); // Just to see if it's not going to throw any exception.
    }
    
    // Careful: this one is going to retrieve the actual production DB connection string. This will only be possible if
    // a service account is set up in your machine.
    [TestMethod]
    public async Task TestProductionSecretProvider()
    {
        var provider = new ProductionSecretProviderService();
        await provider.InitAsync();
        Assert.IsNotEmpty(provider.GetDatabaseConnectionString());
    }
}
