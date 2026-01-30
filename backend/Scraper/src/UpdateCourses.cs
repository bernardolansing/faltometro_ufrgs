using System.Collections.Concurrent;
using System.Text;
using System.Text.RegularExpressions;
using Amazon.Lambda.Core;
using AngleSharp.Dom;
using AngleSharp.Html.Dom;
using AngleSharp.Text;
using Microsoft.EntityFrameworkCore;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
namespace Scraper;

public class UpdateCourses
{
    private static readonly Regex CourseCodeRegex = new("^[A-Z]{3}\\d{5}$");
    
    public async Task Handler()
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        var client = new ScraperClient();
        var db = new AppDatabase();
        
        // Fetch a list of UFRGS graduation programs.
        var graduationProgramsPage = await client.FetchAndParseHtml("https://www.ufrgs.br/site/ensino/graduacao/");
        var gProgramCards = graduationProgramsPage.QuerySelectorAll(".card-course"); // Clickable cards, one for each
        // graduation program.
        
        // Now we're going to access each graduation program specific website in parallel. Let's use a
        // ConcurrentDictionary for this.
        const int initialCapacity = 6500; // A guess about how many courses we're going to find at most.
        const int concurrencyLevel = 1; // The estimated amount of threads that'll update the dictionary. We're only
        // using one thread for now.
        var courses = new ConcurrentDictionary<string, string>(concurrencyLevel, initialCapacity); // This dictionary
        // is safe to use in parallel code.

        ushort errors = 0;
        await Task.WhenAll(gProgramCards.Select(async gProgramCard =>
        {
            var programPageUrl = gProgramCard.GetAttribute("href")!;
            try
            {
                var programPage = await client.FetchAndParseHtml(programPageUrl); // This is a page that
                // displays different variations for the same program. We'll have to scan each one of the variations'
                // curriculums.
                var curriculumUrls = GetCurriculumUrlForEachProgramVariant(programPage);

                await Task.WhenAll(curriculumUrls.Select(async currUrl =>
                {
                    var curriculumPage = await client.FetchAndParseHtml(currUrl); // Load the curriculum.
                    var tableRows = curriculumPage.QuerySelectorAll(".modelo1even, .modelo1odd"); // Selects the body
                    // table rows. Not all of them are courses, but we can me the distinction.
                    
                    // Extract all courses found for this curriculum, then try to add them to the dictionary.
                    var coursesForThisProgram = tableRows.Select(ParseTableRowCandidate)
                        .Where(candidate => candidate != null);
                    foreach (var course in coursesForThisProgram)
                    {
                        var (courseCode, courseTitle) = course!.Value;
                        courses.TryAdd(courseCode, courseTitle);
                    }
                }));
            }
            catch (Exception error)
            {
                errors++;
                await Console.Error.WriteLineAsync($"Failed to parse courses coming from page {programPageUrl}");
                await Console.Error.WriteLineAsync(error.Message);
                await Console.Error.WriteLineAsync(error.StackTrace);
            }
        }));
        Console.WriteLine($"Found {courses.Count} courses across {gProgramCards.Count - errors} programs.");

        // Now, if no errors ocurred, we're going to clear the courses table from the database and populate it again
        // with the updated list of courses.
        if (errors == 0)
        {
            Console.WriteLine("Repopulating courses table in database");
            var transaction = await db.Database.BeginTransactionAsync();
            await db.Courses.ExecuteDeleteAsync();
            await db.Courses.AddRangeAsync(courses.Select(pair => new Course(pair.Key, pair.Value)));
            await db.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        else
        {
            await Console.Error.WriteLineAsync($"Scraping failed for {errors} programs");
            await Console.Error.WriteLineAsync("Aborting upload to database as errors ocurred");
        }
            
        Console.WriteLine($"Execution took {stopwatch.Elapsed.TotalSeconds}s");
    }

    /// <summary>
    /// For a given undergraduate program website, returns a URL for the curriculum of each of its variants.
    /// </summary>
    /// <param name="programPage">The serialized HTML document for the program's webpage.</param>
    /// <returns>A list of URLs corresponding to the curriculums of the program's variations.</returns>
    private static List<string> GetCurriculumUrlForEachProgramVariant(IHtmlDocument programPage)
    {
        var allIframes = programPage.QuerySelectorAll("iframe");
        var urls = new List<string>();
        for (var i = 0; i < allIframes.Length; i += 2)
            urls.Add(allIframes[i].GetAttribute("src")!);
        return urls;
    }

    private static (string, string)? ParseTableRowCandidate(IElement row)
    {
        var courseCode = row.Children[0].InnerHtml;
        
        // If the first cell of the row doesn't match the pattern of a course code, then this row is something else
        // and we should discard it.
        if (!CourseCodeRegex.IsMatch(courseCode))
            return null;
        
        // There's a little bit of work required to extract the course title, as most of the times there's some HTML
        // and extra whitespaces after the title text itself. Sometimes, words are split by multiple spaces as well.
        // So we're using a string builder to concatenate each character until we find some HTML tag and then get rid
        // of whitespaces.
        var courseTitleBuilder = new StringBuilder();
        var lastCharWasWhitespace = false;
        foreach (var character in row.Children[1].InnerHtml)
        {
            // We've detected the start of an HTML tag, so there's nothing relevant beyond this point.
            if (character == '<')
                break;
            
            // If the character is a non-whitespace that is not a HTML tag opening, we should include it.
            if (!character.IsWhiteSpaceCharacter())
            {
                courseTitleBuilder.Append(character);
                lastCharWasWhitespace = false;
            }
            
            // Now if it is a whitespace, we only want to include it if the last character wasn't. This ensures that
            // there'll be only one space between every word.
            else if (!lastCharWasWhitespace)
            {
                courseTitleBuilder.Append(' ');
                lastCharWasWhitespace = true;
            }
        }
        
        return (courseCode, courseTitleBuilder.ToString().Trim());
    }
}

[TestClass]
public class UpdateCoursesTest
{
    [TestMethod]
    public async Task ExecuteUpdateCourses()
    {
        var instance = new UpdateCourses();
        await instance.Handler();
    }
}