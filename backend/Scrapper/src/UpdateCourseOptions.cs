using DotNetEnv;

namespace Scrapper;

public class UpdateCourseOptions : LambdaScrapperFunction
{
    public async Task Handler(string sessionId)
    {
        
    }
}

[TestClass]
public class UpdateCourseOptionsTest
{
    [TestMethod]
    public async Task ExecuteUpdateCourseOptions()
    {
        Env.TraversePath().Load();
        var sessionId = Environment.GetEnvironmentVariable("UFRGS_SESSION_ID");
        if (string.IsNullOrEmpty(sessionId))
            throw new Exception("Missing UFRGS_SESSION_ID environment variable!");
        
        var instance = new UpdateCourseOptions();
        await instance.Handler(sessionId);
    }
}