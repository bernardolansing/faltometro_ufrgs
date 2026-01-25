using DotNetEnv;

namespace Scrapper;

public class UpdateCourseOptions : LambdaScrapperFunction
{
    public async Task Handler(string sessionId)
    {
        var client = new ScraperClient(sessionId);
        
        var classOptionsPerProgramPage = await client.FetchAndParseHtml(
            "https://www1.ufrgs.br/intranet/portal/public/index.php?cods=1,1,1,224");
        var graduationPrograms = classOptionsPerProgramPage.QuerySelectorAll("#selecionado option");
        Console.WriteLine(graduationPrograms.Count);
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