using System.Text.Encodings.Web;
using System.Text.Json;
using FaltometroUfrgsBackend.Models;
using FaltometroUfrgsBackend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Controllers;

[ApiController]
[Route("DownloadCourseOptions")]
public class DownloadCourseOptionsController(AppDatabase db) : Controller
{
    /// <summary>
    /// Streams (if necessary) the list of course options from the database.
    ///
    /// First of all, if the provided generation number is updated, the response is a no-body 200. If the generation
    /// number is not provided or is outdated, the response is going to be a stream of lines in which:
    /// -> The first line ever is the updated generation number as a string.
    /// -> Every subsequent line is a valid JSON object representing a course option object (JSONL format).
    /// This design allows the consumer to process data on-the-fly.
    /// </summary>
    /// <param name="generation">The courses list generation number that the consumer currently has downloaded. If
    /// updated, there'll be no need for a response.</param>
    [HttpGet]
    public async Task Get(uint? generation)
    {
        var updatedGenerationNumber = await db.Generations.Where(g => g.Id == Generation.CourseOptionsGenerationId)
            .Select(g => g.GenerationNumber)
            .FirstAsync();

        // Check if the user has the updated generation downloaded. If so, we can just finish this request.
        if (generation == updatedGenerationNumber)
            return;
        
        // Otherwise, we'll stream the course options. But first, let's configure the headers and send the updated
        // generation number.
        Response.Headers.Append("Content-Type", "text/plain; charset=utf-8");
        await Response.WriteAsync($"{updatedGenerationNumber}\n");

        // This option is required so JsonSerializer won't escape non-ASCII characters to \u sequences.
        var serializerOptions = new JsonSerializerOptions { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };
        var enumerable = db.CourseOptions.Include(p => p.CourseOptionsClassSessions)
            .AsAsyncEnumerable();
        await foreach (var course in enumerable)
        {
            var line = JsonSerializer.Serialize(course, serializerOptions) + '\n';
            await Response.WriteAsync(line);
        }
    }
}