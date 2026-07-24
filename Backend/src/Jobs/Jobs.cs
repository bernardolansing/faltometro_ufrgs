using System.Diagnostics;
using FaltometroUfrgsBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Jobs;

internal class Jobs
{
    internal static async Task RunJob(string jobName, string[] args)
    {
        var config = await GetConfiguration();
        var database = new AppDatabase(config);

        IJob job;
        switch (jobName)
        {
            case "UpdateCourses":
                job = new UpdateCoursesJob(database);
                break;
            case "UpdateCourseOptions":
                var ufrgsSessionId = args.FirstOrDefault();
                if (ufrgsSessionId == null)
                    throw new ArgumentException("Missing UFRGS session ID argument");
                job = new UpdateCourseOptionsJob(database, ufrgsSessionId);
                break;
            default:
                throw new Exception($"Unrecognized job name '{jobName}'");
        }
        
        var stopwatch = new Stopwatch();
        bool success;
        try
        {
            stopwatch.Start();
            await job.ExecuteAsync();
            success = true;
        }
        catch (Exception error)
        {
            await Console.Error.WriteLineAsync($"Error while executing job {jobName}: {error.Message}");
            await Console.Error.WriteLineAsync(error.StackTrace);
            success = false;
        }
            
        await Console.Out.WriteLineAsync($"Job execution time: {stopwatch.Elapsed.TotalSeconds} seconds");
        
        if (job is IExtractionJob extractionJob)
        {
            await Console.Out.WriteLineAsync($"Registering new {(success ? "successful" : "failed")} extraction entry");
            var entityType = database.Model.FindEntityType(extractionJob.GetModelType())!;
            var resourceName = entityType.GetTableName()!;
            await database.Extractions.AddAsync(new Extraction { Resource = resourceName, Successful = success });
            await database.SaveChangesAsync();
        }
    }

    private static async Task<IConfigurationRoot> GetConfiguration()
    {
        var runningOnCloud = Environment.GetEnvironmentVariable("CLOUD_RUN_JOB") != null;
        var configBuilder = new ConfigurationBuilder();
        if (runningOnCloud)
        {
            await GSecretsManagerService.InitAsync();
            configBuilder.AddGoogleSecretsManager();
        }
        else
        {
            configBuilder.AddUserSecrets<Jobs>();
        }
        
        return configBuilder.Build();
    }
}

internal interface IExtractionJob : IJob
{
    internal Type GetModelType();
}

internal interface IJob
{
    internal Task ExecuteAsync();
}
