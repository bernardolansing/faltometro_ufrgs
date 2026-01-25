using AngleSharp.Dom;
using AngleSharp.Html.Dom;
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

            if (optionsTable == null)
            {
                var programName = classOptionsPage.QuerySelector("#principal b")?.InnerHtml;
                if (programName == null)
                    throw new Exception("Failed to parse options for program code " + programCode);
                Console.WriteLine($"Program named \"{programName}\" seems to be discontinued");
                continue;
            }

            var allRows = optionsTable.QuerySelectorAll(".modelo1odd, .modelo1even");
            string currentCourseCode;
            foreach (var row in allRows)
            {
                var courseCell = row.Children[0].InnerHtml;
                if (courseCell.StartsWith('('))
                    currentCourseCode = courseCell.Substring(1, 8);
                var courseOptionName = row.Children[2].InnerHtml.Trim();

                var classSessionsInfo = row.Children[8].Children[0];
                foreach (var info in classSessionsInfo.ChildNodes)
                {
                    if (info is IElement element)
                    {
                        if (element.ClassName == "hor")
                        {
                            var words = element.InnerHtml.Split(' ');
                            var classSession = new CourseOptionClassSession
                            {
                                Weekday = WeekdayFromString(words[0]),
                                StartingTime = words[1].Split(':')[0],
                                Periods = short.Parse(words[2])
                            };
                        }
                        
                        else if (info is IHtmlAnchorElement)
                        {
                            // TODO: handle location with Maps link
                        }
                    }

                    else
                    {
                        // TODO: handle location without Maps link
                    }
                }
            }
        }
    }

    private static Weekday WeekdayFromString(string weekdayStr) => weekdayStr switch
    {
        "Segunda" => Weekday.Mon,
        "Terça" => Weekday.Tue,
        "Quarta" => Weekday.Wed,
        "Quinta" => Weekday.Thu,
        "Sexta" => Weekday.Fri,
        "Sábado" => Weekday.Sat,
        _ => throw new Exception("Tried to deserialize unknown weekday name: " + weekdayStr)
    };

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