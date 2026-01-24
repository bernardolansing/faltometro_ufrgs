using System.Collections.Concurrent;
using System.Text;
using System.Text.RegularExpressions;
using Amazon.Lambda.Core;
using AngleSharp.Dom;
using AngleSharp.Text;
using Microsoft.EntityFrameworkCore;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
namespace Scrapper;

public partial class UpdateCourses : LambdaScrapperFunction
{
    private static readonly Regex CourseCodeRegex = CourseCodeRegexGen();
    
    public async Task Handler()
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        
        var graduationProgramsPage = await FetchAndParseHtml("https://www.ufrgs.br/site/ensino/graduacao/"); // Fetch
        // a list of UFRGS graduation programs.
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
                var programPage = await FetchAndParseHtml(programPageUrl); // This is a page that
                // displays different curriculum options for a program. As far as I'm aware, a curriculum is just a
                // different selecion of mandatory courses among the courses offered by a program.

                // So, as our goal is to obtain a list of all courses that exists, we can just grab the first curriculum
                // that we find and scrap data from there.
                var curriculumUrl = programPage.QuerySelector("iframe")!.GetAttribute("src")!;

                var curriculumPage = await FetchAndParseHtml(curriculumUrl); // Now we can finnaly extract some courses
                // data.
                var tableRows = curriculumPage.QuerySelectorAll(".modelo1even, .modelo1odd"); // Selects the body table
                // rows. Not all of them are courses, but we can me the distinction.
                var coursesForThisProgram = tableRows.Select(ParseTableRowCandidate)
                    .Where(candidate => candidate != null);
                foreach (var course in coursesForThisProgram)
                {
                    var (courseCode, courseTitle) = course!.Value;
                    courses.TryAdd(courseCode, courseTitle);
                }
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
            var transaction = await Db.Database.BeginTransactionAsync();
            await Db.Courses.ExecuteDeleteAsync();
            await Db.Courses.AddRangeAsync(courses.Select(pair => new Course(pair.Key, pair.Value)));
            await Db.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        else
        {
            await Console.Error.WriteLineAsync($"Scraping failed for {errors} programs");
            await Console.Error.WriteLineAsync("Aborting upload to database as errors ocurred");
        }
            
        Console.WriteLine($"Execution took {stopwatch.Elapsed.TotalSeconds}s");
    }

    private static (string, string)? ParseTableRowCandidate(IElement row)
    {
        var courseCode = row.Children[0].InnerHtml;
        
        // If the first cell of the row doesn't match the pattern of a course code, then this row is something else
        // and we should discard it.
        if (!CourseCodeRegex.IsMatch(courseCode))
            return null;
        
        // There's a little bit of work required to extract the course title, as most of the times there's some HTML
        // and extra whitespaces after the title text itself. So we're using a string builder to concatenate each
        // character until we find some HTML tag or extra whitespaces.
        var courseTitleBuilder = new StringBuilder();
        var lastCharWasWhitespace = false;
        foreach (var character in row.Children[1].InnerHtml)
        {
            if (character.IsWhiteSpaceCharacter())
            {
                if (lastCharWasWhitespace)
                    break;
                lastCharWasWhitespace = true;
            }
            else if (character == '<')
                break;
            else
            {
                if (lastCharWasWhitespace)
                {
                    courseTitleBuilder.Append(' ');
                    lastCharWasWhitespace = false;
                }
                courseTitleBuilder.Append(character);
            }
        }
        
        return (courseCode, courseTitleBuilder.ToString());
    }

    [GeneratedRegex("^[A-Z]{3}\\d{5}$")]
    private static partial Regex CourseCodeRegexGen();
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