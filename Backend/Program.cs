using System.Text.Json;
using FaltometroUfrgsBackend.Services;

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
if (runningOnCloudRun)
{
    var prodService = new ProductionSecretProviderService();
    await prodService.InitAsync();
    mvcBuilder.Services.AddSingleton<ISecretProviderService>(prodService);
}
else
    mvcBuilder.Services.AddSingleton<ISecretProviderService, LocalDevSecretProviderService>();
mvcBuilder.Services.AddDbContext<AppDatabase>();
mvcBuilder.Services.AddExceptionHandler<ExceptionHandler>();

var app = builder.Build();
app.UseExceptionHandler(_ => {});
app.MapControllers();

// In Google Cloud Run we must serve the app in 0.0.0.0:PORT for it to work. If PORT envvar is not set, we are running
// in a local development environment, so we can use whatever is configured in the launch settings.
var port = Environment.GetEnvironmentVariable("PORT");
string? url = null;
if (port != null)
    url = "http://0.0.0.0:" + port;
app.Run(url);
