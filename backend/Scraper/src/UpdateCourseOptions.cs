using DotNetEnv;

namespace Scraper;

public class UpdateCourseOptions
{
    public async Task Handler(string sessionId)
    {
        const string pageUri = "https://www1.ufrgs.br/intranet/portal/public/index.php?cods=1,1,1,224";
        
        var client = new ScraperClient(sessionId);
        
        var classOptionsPerProgramPage = await client.FetchAndParseHtml(pageUri);
        var graduationProgramsCodes = classOptionsPerProgramPage.QuerySelectorAll("#selecionado option")
            .Select(option => option.GetAttribute("value")!)
            .Skip(1);
        
        foreach (var programCode in graduationProgramsCodes)
        {
            var form = new Dictionary<string, string> { ["selecionado"] = programCode };
            var classOptionsPage = await client.PostFormAndParseHtml(pageUri, form);
            var optionsTable = classOptionsPage.GetElementById("Horarios");

            if (optionsTable != null)
            {
                // TODO: parse the table.
            }
            else
            {
                var programName = classOptionsPage.QuerySelector("#principal b")?.InnerHtml;
                if (programName == null)
                    throw new Exception("Failed to parse options for program code " + programCode);
                Console.WriteLine($"Program named \"{programName}\" seems to be discontinued");
            }
        }
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