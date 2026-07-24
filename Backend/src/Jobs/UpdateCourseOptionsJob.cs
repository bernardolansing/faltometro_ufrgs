using System.Diagnostics;
using AngleSharp.Dom;
using AngleSharp.Html.Dom;
using AngleSharp.Html.Parser;
using FaltometroUfrgsBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Jobs;

public class UpdateCourseOptionsJob(AppDatabase db, string ufrgsSessionId) : IExtractionJob
{
    /// <summary>
    /// List of weekdays' names as they are found in the student's dashboard.
    /// </summary>
    private static readonly List<string> Weekdays = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"];

    public Type GetModelType() => typeof(CourseOption);
    
    public async Task ExecuteAsync()
    {
        const string pageUri = "https://www1.ufrgs.br/intranet/portal/public/index.php?cods=1,1,1,224";
        
        Console.WriteLine("Commencing update on course options list");
        var client = new ScraperClient(ufrgsSessionId);
        
        // This page contains a select menu with all undergrad programs. To each program is assigned an identification.
        var classOptionsPerProgramPage = await client.FetchAndParseHtml(pageUri);
        var undergradProgramsCodes = classOptionsPerProgramPage.QuerySelectorAll("#selecionado option")
            .Select(option => option.GetAttribute("value")!)
            .Skip(1); // The first option is a bogus "pick a course" that should be discarded.

        // While fetching course options, weirdly we might find options for courses that don't exist in the programs'
        // curricula. Also, the same course option may be offered to multiple different programs. To get around both
        // problems, we're going to fetch all valid course codes from DB and create a dictionary from them. For each
        // course code, we're going to add the corresponding offered options in a list.
        var coursesAndOptions = new Dictionary<string, List<CourseOption>>();
        var validCourseCodes = db.Courses.Select(course => course.Code)
            .ToAsyncEnumerable();
        await foreach (var courseCode in validCourseCodes)
            coursesAndOptions.Add(courseCode, []);
        uint validOptions = 0;
        uint invalidOptions = 0; // Invalid options refer to course codes that were found in the offered options table,
        // but were not included in the database.
        
        await Task.WhenAll(undergradProgramsCodes.Select(async programCode =>
        {
            // To access the course options for a given program, we have to send a POST request to the same endpoint
            // as before, but with a urlencoded-form specifying the undergrad program code that we want to fetch.
            var form = new Dictionary<string, string> { ["selecionado"] = programCode };
            var classOptionsPage = await client.PostFormAndParseHtml(pageUri, form);
            var programName = classOptionsPage.QuerySelector("#principal b")?.InnerHtml;
            var optionsTable = classOptionsPage.GetElementById("Horarios"); // This is a the table that contains one
            // course option per row.

            // Should we fail to find such table, it means that this program is dead, so let's skip to the next one.
            if (optionsTable == null)
            {
                if (programName == null)
                    throw new Exception("Failed to parse options for program code " + programCode);
                Console.WriteLine($"Program named \"{programName}\" seems to be discontinued");
                return;
            }

            // Every row of this table contains information on a single course option. When a course has many options,
            // they'll all come one after another. However, only the first row will actually contain the code/name of
            // the course; subsequent rows leave that cell empty. Easy enough, we just have to cache it and update
            // whenever a new course code is found.
            var allRows = optionsTable.QuerySelectorAll(".modelo1odd, .modelo1even");
            var currentCourseCode = "";
            foreach (var row in allRows)
            {
                // If filled, this cell looks like:
                // (XXX12345) COURSE NAME
                // The content between parentesis is the 8 characters long course code.
                var courseCell = row.Children[0].InnerHtml;
                if (courseCell.StartsWith('('))
                    currentCourseCode = courseCell.Substring(1, 8);

                var courseOptionName = row.Children[2].InnerHtml.Trim();

                // We've found ourselves an invalid course. Let's just ignore them, there are too few of these.
                if (!coursesAndOptions.TryGetValue(currentCourseCode, out var optionsForCurrentCourse))
                {
                    invalidOptions++;
                    continue;
                }

                // Now let's verify that we haven't already added this option before, from another program.
                if (optionsForCurrentCourse.Any(option => option.OptionName == courseOptionName))
                    continue;
                
                // A new course option is found!
                var classSessionsInfo = row.Children[8].Children[0];
                var classSessions = GetClassSessionsFromTableCell(classSessionsInfo);
                var newCourse = new CourseOption
                {
                    CourseCode = currentCourseCode,
                    OptionName = courseOptionName,
                    CourseOptionsClassSessions = classSessions
                };
                optionsForCurrentCourse.Add(newCourse);
                validOptions++;
            }
        }));

        if (validOptions == 0)
            throw new Exception("No valid course options were found, a problem must have occurred.");
        
        Console.WriteLine($"Found {validOptions} course options in total");
        Console.WriteLine("Adding them to the database now");
        Console.WriteLine($"{invalidOptions} options were invalid and will be discarded");
        var allCourseOptions = coursesAndOptions.Values
            .Aggregate(Enumerable.Empty<CourseOption>(), (acc, val) => acc.Concat(val));
        
        await db.Database.BeginTransactionAsync();
        await db.CourseOptions.ExecuteDeleteAsync();
        await db.CourseOptions.AddRangeAsync(allCourseOptions);
        await db.SaveChangesAsync();
        await db.Database.CommitTransactionAsync();
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
                        Weekday = (short) Weekdays.IndexOf(words[0]),
                        StartingTime = words[1].Split('-')[0],
                        Periods = short.Parse(words[2])
                    };
                    sessionsFound.Add(newSession);
                }
                        
                // We've found the location for the last session. Let's update it.
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
                if (text.Length == 0)
                    continue;
                Debug.Assert(sessionsFound.Last().Location == null);
                sessionsFound.Last().Location = text;
            }
        }
        
        return sessionsFound;
    }
    
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
                Weekday = 0,
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
                    Weekday = 0,
                    Periods = 2,
                    StartingTime = "7:30",
                },
                new()
                {
                    Location = "Sala de aula 062 - Campus: Centro",
                    Weekday = 3,
                    Periods = 2,
                    StartingTime = "7:30",
                },
                new()
                {
                    Location = "Sala de aula 062 - Campus: Centro",
                    Weekday = 5,
                    Periods = 2,
                    StartingTime = "7:30",
                }
            };
            var actualResponse2 = GetClassSessionsFromTableCell(ParseHtmlFragmentString(example2));
            Assert.HasCount(expectedResponse2.Count, actualResponse2);
            Assert.IsTrue(expectedResponse2.Zip(actualResponse2).All(pair => CheckEquality(pair.First, pair.Second)));
        }
        
        // [TestMethod]
        // public async Task ExecuteUpdateCourseOptions()
        // {
        //     Env.TraversePath().Load();
        //     var sessionId = Environment.GetEnvironmentVariable("UFRGS_SESSION_ID");
        //     if (string.IsNullOrEmpty(sessionId))
        //         throw new Exception("Missing UFRGS_SESSION_ID environment variable!");
        //
        //     var localSecretsService = new LocalDevSecretProviderService();
        //     var databaseService = new AppDatabase(localSecretsService);
        //     var instance = new UpdateCourseOptionsController(databaseService);
        //     await instance.RunUpdate(new RequestBody { UfrgsSessionId = sessionId });
        // }
        
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