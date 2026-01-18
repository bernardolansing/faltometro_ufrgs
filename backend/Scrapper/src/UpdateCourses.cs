using System.Text;
using System.Text.RegularExpressions;
using Amazon.Lambda.Core;
using AngleSharp.Dom;
using AngleSharp.Text;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
namespace Scrapper;

public partial class UpdateCourses : LambdaScrapperFunction
{
    private static readonly Regex CourseCodeRegex = CourseCodeRegexGen();
    
    public static async Task Main()
    {
        await new UpdateCourses().Handler();
    }
    
    public async Task Handler()
    {
        var graduationProgramsPage = await FetchAndParseHtml("https://www.ufrgs.br/site/ensino/graduacao/");
        var gProgramCards = graduationProgramsPage.QuerySelectorAll(".card-course"); // Clickable cards, one for each
        // graduation program.

        foreach (var gProgramCard in gProgramCards)
        {
            var programPage = await FetchAndParseHtml(gProgramCard.GetAttribute("href")!); // This is a page that
            // displays different curriculum options for a program. As far as I'm aware, a curriculum is just a
            // different selecion of mandatory courses among the courses offered by a program.
            
            // So, as our goal is to obtain a list of all courses that exists, we can just grab the first curriculum
            // that we find and scrap data from there.
            var curriculumUrl = programPage.QuerySelector("iframe")!.GetAttribute("src")!;

            var curriculumPage = await FetchAndParseHtml(curriculumUrl); // Now we can finnaly extract some courses
            // data.
            var tableRows = curriculumPage.QuerySelectorAll(".modelo1even, .modelo1odd"); // Selects the body table
            // rows. Not all of them are courses, but we can me the distinction.
            foreach (var courseRow in tableRows)
            {
                Console.WriteLine(ParseTableRowCandidate(courseRow));
            }
            
        }
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