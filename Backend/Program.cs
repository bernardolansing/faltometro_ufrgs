using System.Text.Json;
using FaltometroUfrgsBackend.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

DotNetEnv.Env.TraversePath().Load(); // Load environment variables from .env file.

var runningOnCloudRun = Environment.GetEnvironmentVariable("K_SERVICE") != null; // This environment variable is set
// when we're running on production Cloud Run. You can also set it locally to pretend that we're running on cloud. This,
// however, requires a configured gcloud service account in your system and CAUTION!!!: it's going to use the production
// database.

var builder = WebApplication.CreateBuilder(args);

var mvcBuilder = builder.Services.AddControllers();
mvcBuilder.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.AllowDuplicateProperties = false;
    options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
});
SupabaseSecrets? supabaseSecrets;
if (runningOnCloudRun)
{
    var prodService = new ProductionSecretProviderService();
    await prodService.InitAsync();
    supabaseSecrets = prodService.GetSupabaseSecrets();
    mvcBuilder.Services.AddSingleton<ISecretProviderService>(prodService);
}
else
{
    var localSecretsProvider = new LocalDevSecretProviderService();
    mvcBuilder.Services.AddSingleton<ISecretProviderService>(localSecretsProvider);
    supabaseSecrets = localSecretsProvider.GetSupabaseSecrets();
}
mvcBuilder.Services.AddDbContext<AppDatabase>();
mvcBuilder.Services.AddExceptionHandler<ExceptionHandler>();
mvcBuilder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = supabaseSecrets.TokenIssuerKey,
            ValidIssuer = supabaseSecrets.GetTokenIssuerUrl(),
            ValidAudiences = SupabaseSecrets.TokenAudiences
        };
    });

var app = builder.Build();
app.UseExceptionHandler(_ => {});
app.UseAuthentication();
app.MapControllers();

// In Google Cloud Run we must serve the app in 0.0.0.0:PORT for it to work. If PORT envvar is not set, we are running
// in a local development environment, so we can use whatever is configured in the launch settings.
var port = Environment.GetEnvironmentVariable("PORT");
string? url = null;
if (port != null)
    url = "http://0.0.0.0:" + port;
app.Run(url);
