using System.Text.Json;
using FaltometroUfrgsBackend;
using FaltometroUfrgsBackend.Jobs;
using FaltometroUfrgsBackend.Models;
using Microsoft.EntityFrameworkCore;

var jobName = Environment.GetEnvironmentVariable("JOB"); // If a job is to be run, we'll run it and quit the program.
// Otherwise, the server ASP.NET app is going to be built and run.
if (jobName != null)
{
    await Jobs.RunJob(jobName, args);
    return;
}

var runningOnCloudRun = Environment.GetEnvironmentVariable("K_SERVICE") != null; // This environment variable is set
// when we're running on production Cloud Run. You can also set it locally to pretend that we're running on cloud. This,
// however, requires a configured gcloud service account in your system and CAUTION!!!: it's going to use the production
// database.

var builder = WebApplication.CreateBuilder(args);

if (runningOnCloudRun)
{
    await GSecretsManagerService.InitAsync();
    builder.Configuration.AddGoogleSecretsManager();
}

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.AllowDuplicateProperties = false;
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
});

builder.Services.AddDbContext<AppDatabase>();
builder.Services.AddExceptionHandler<ExceptionHandler>();

var app = builder.Build();

app.MapGet("/courses", (AppDatabase db) => db.Courses.ToArrayAsync())
    .AddEndpointFilter<CacheFilter<Course>>();
app.MapGet("/course_options", (AppDatabase db) => db.CourseOptions.ToArrayAsync())
    .AddEndpointFilter<CacheFilter<CourseOption>>();

app.UseExceptionHandler(_ => {});

// In Google Cloud Run we must serve the app in 0.0.0.0:PORT for it to work. If PORT envvar is not set, we are running
// in a local development environment, so we can use whatever is configured in the launch settings.
var port = Environment.GetEnvironmentVariable("PORT");
string? url = null;
if (port != null)
    url = "http://0.0.0.0:" + port;
app.Run(url);
