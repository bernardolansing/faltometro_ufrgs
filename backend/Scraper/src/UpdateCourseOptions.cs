using System.Diagnostics;
using AngleSharp.Dom;
using AngleSharp.Html.Dom;
using AngleSharp.Html.Parser;
using DotNetEnv;

namespace Scraper;

public class UpdateCourseOptions
{
    public async Task Handler(string sessionId)
    {
        const string pageUri = "https://www1.ufrgs.br/intranet/portal/public/index.php?cods=1,1,1,224";
        
        var client = new ScraperClient(sessionId);
        
        // This page contains a select menu with all graduation programs. To each program is assigned an identification.
        var classOptionsPerProgramPage = await client.FetchAndParseHtml(pageUri);
        var graduationProgramsCodes = classOptionsPerProgramPage.QuerySelectorAll("#selecionado option")
            .Select(option => option.GetAttribute("value")!)
            .Skip(1); // The first option is a bogus "pick a course" that doesn't do a thing.
        
        foreach (var programCode in graduationProgramsCodes)
        {
            // To access the course options for a given program, we have to send a POST request to the same endpoint
            // as before, but with a urlencoded-form specifying the graduation program code that we want to fetch.
            var form = new Dictionary<string, string> { ["selecionado"] = programCode };
            var classOptionsPage = await client.PostFormAndParseHtml(pageUri, form);
            var programName = classOptionsPage.QuerySelector("#principal b")?.InnerHtml;
            var optionsTable = classOptionsPage.GetElementById("Horarios"); // This a the table that contains one
            // course option per row.

            // Should we fail to find such table, it means that this program is dead, so let's skip to the next one.
            if (optionsTable == null)
            {
                if (programName == null)
                    throw new Exception("Failed to parse options for program code " + programCode);
                Console.WriteLine($"Program named \"{programName}\" seems to be discontinued");
                continue;
            }
            
            // Every row of this table contains information on a single course option. When a course has many options,
            // they'll all come in a sequence. However, only the first row will actually contain the code/name of the
            // course. Easy enough, we just have to cache it and update whenever a new course code is found.
            var allRows = optionsTable.QuerySelectorAll(".modelo1odd, .modelo1even");
            var currentCourseCode = "";
            var optionsForThisProgram = new List<CourseOption>();
            foreach (var row in allRows)
            {
                var courseCell = row.Children[0].InnerHtml;
                if (courseCell.StartsWith('('))
                    currentCourseCode = courseCell.Substring(1, 8);
                
                var courseOptionName = row.Children[2].InnerHtml.Trim();
                var classSessionsInfo = row.Children[8].Children[0];
                var classSessions = GetClassSessionsFromTableCell(classSessionsInfo);
                var newCourse = new CourseOption
                {
                    CourseCode = currentCourseCode,
                    OptionName = courseOptionName,
                    CourseOptionsClassSessions = classSessions
                };
                optionsForThisProgram.Add(newCourse);
            }
            
            if (programName != null)
                Console.WriteLine($"Found {optionsForThisProgram.Count} course options for program {programName}");
        }
    }

    /// <summary>
    /// Every row that represents a course option contains one cell that lists all class sessions for that option. This
    /// method is for parsing that cell.
    /// </summary>
    /// <param name="tableCell">The <c>ul</c> HTML element describing the class sessions for a course option.</param>
    /// <returns>A list of the serialized <c>CourseOptionClassSession</c> objects found in the cell.</returns>
    private static List<CourseOptionClassSession> GetClassSessionsFromTableCell(IElement tableCell)
    {
        var sessionsFound = new List<CourseOptionClassSession>();
        
        /*
         * This one is a little tricky. Most of the cells that you're going to find are like this:
         * <ul>
         *   <li class="hor"> Terça 18:30-20:10 2 </li>
         *   <a href="..."> (location name) </a>
         *   <li class="hor"> Terça 18:30-20:10 2 </li>
         *   <a href=" (hyperlink to a map) "> (location name) </a>
         * </ul>
         * You see that the li with class "hor" will always give us the weekday, starting time and periods count for
         * each class session, there's no exception for that.
         * 
         * Then, there's the location. Things start to get messy here, because sometimes the location is an anchor
         * element with the reference pointing to a map where the student can see where is the place. However, this map
         * is not always available; for locations without map we get a raw text node, like this:
         * <ul>
         *   <li class="hor"> Terça 18:30-20:10 2 </li>
         *   (location name)
         *   <li class="hor"> Terça 18:30-20:10 2 </li>
         *   (location name)
         * </ul>
         *
         * And, to get worse, sometimes the location is simply not provided. Well, let's make it step by step.
         */
        
        foreach (var info in tableCell.ChildNodes)
        {
            if (info is IElement element)
            {
                // If it is an element node with class "hor", we've just found the beginning of a new class session
                // description.
                if (element.ClassName == "hor")
                {
                    // Parse the content and serialize it to a new session object. Then, let's add it to the end of the
                    // list.
                    var words = element.InnerHtml.Split(' ');
                    var newSession = new CourseOptionClassSession
                    {
                        Weekday = WeekdayFromString(words[0]),
                        StartingTime = words[1].Split('-')[0],
                        Periods = short.Parse(words[2])
                    };
                    sessionsFound.Add(newSession);
                }
                        
                // We've found the location for the last session. Let's append it.
                else if (info is IHtmlAnchorElement)
                {
                    Debug.Assert(sessionsFound.Last().Location == null);
                    sessionsFound.Last().Location = info.Text().Trim();
                }
            }

            // We've found a text node. It might be either a text filled with whitespaces or the location for the
            // session object previously added to the list.
            else
            {
                var text = info.Text().Trim();
                if (text == "")
                    continue;
                Debug.Assert(sessionsFound.Last().Location == null);
                sessionsFound.Last().Location = info.Text().Trim();
            }
        }
        
        return sessionsFound;
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

    [TestClass]
    public class UpdateCourseOptionsTest
    {
        private readonly HtmlParser _parser = new();
        
        [TestMethod]
        public void TestGetClassSessionsFromTableCell()
        {
            const string example1 = @"
            <ul>
                <li class=""hor"">Segunda 18:30-21:50 4</li>
                <a class=""clicavel"" href=""http://mapa.ufrgs.br/index.php?verb=pan&amp;building=8"" target=""_blank"">
                    310 SALA DE AULA - Campus: Saúde                    
                </a>
            </ul>
            ";
            var expectedResponse = new CourseOptionClassSession
            {
                Weekday = Weekday.Mon,
                StartingTime = "18:30",
                Periods = 4,
                Location = "310 SALA DE AULA - Campus: Saúde"
            };
            var actualResponse = GetClassSessionsFromTableCell(ParseHtmlFragmentString(example1));
            Assert.HasCount(1, actualResponse);
            Assert.IsTrue(CheckEquality(expectedResponse, actualResponse[0]));

            const string example2 = @"
            <ul>
                <li class=""hor"">Segunda 7:30-9:10 2</li>
                Sala de aula 062 - Campus: Centro
                <li class=""hor"">Quarta 7:30-9:10 2</li>
                Sala de aula 062 - Campus: Centro
                <li class=""hor"">Sexta 7:30-9:10 2</li>
                Sala de aula 062 - Campus: Centro
            </ul>";
            var expectedResponse2 = new List<CourseOptionClassSession>
            {
                new()
                {
                    Location = "Sala de aula 062 - Campus: Centro",
                    Weekday = Weekday.Mon,
                    Periods = 2,
                    StartingTime = "7:30",
                },
                new()
                {
                    Location = "Sala de aula 062 - Campus: Centro",
                    Weekday = Weekday.Wed,
                    Periods = 2,
                    StartingTime = "7:30",
                },
                new()
                {
                    Location = "Sala de aula 062 - Campus: Centro",
                    Weekday = Weekday.Fri,
                    Periods = 2,
                    StartingTime = "7:30",
                }
            };
            var actualResponse2 = GetClassSessionsFromTableCell(ParseHtmlFragmentString(example2));
            Assert.HasCount(expectedResponse2.Count, actualResponse2);
            Assert.IsTrue(expectedResponse2.Zip(actualResponse2).All(pair => CheckEquality(pair.First, pair.Second)));
        }
        
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
        
        /// <summary>
        /// AngleSharp doesn't quite support parsing HTML fragments. It is only designed to parse documents. So if you
        /// try to parse a fragment with it, it'll automatically add the core HTML tags. This helper method extracts
        /// the desired fragment from the generated document. 
        /// </summary>
        /// <param name="html">The string containing the HTML fragment to be serialized.</param>
        /// <returns>The <c>IElement</c> corresponding to the fragment.</returns>
        private IElement ParseHtmlFragmentString(string html)
        {
            var doc = _parser.ParseDocument(html); // doc will wrap the fragment this way:
            // <html>
            //   <head></head>
            //   <body> <your fragment> </body>
            // </html>
            // So we get the HTML element -> body element -> child (the fragment).
            return doc.DocumentElement.Children[1].Children[0];
        }

        private static bool CheckEquality(CourseOptionClassSession x, CourseOptionClassSession y) =>
            x.Location == y.Location
            && x.Weekday == y.Weekday
            && x.Periods == y.Periods
            && x.StartingTime == y.StartingTime;
    }
}
