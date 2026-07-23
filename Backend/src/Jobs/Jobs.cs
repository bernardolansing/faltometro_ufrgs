namespace FaltometroUfrgsBackend.Jobs;

internal class Jobs(bool runningOnCloud)
{
    internal async Task RunJob(string jobName, string[] args)
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
        
        await job.ExecuteAsync();
    }

    private async Task<IConfigurationRoot> GetConfiguration()
    {
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

internal interface IExtractionJob<T> : IJob;

internal interface IJob
{
    internal Task ExecuteAsync();
}
