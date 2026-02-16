using System.Text.Json;
using FaltometroUfrgsBackend.Services;

var builder = WebApplication.CreateBuilder(args);

var mvcBuilder = builder.Services.AddControllers();
mvcBuilder.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.AllowDuplicateProperties = false;
    options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
});
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
