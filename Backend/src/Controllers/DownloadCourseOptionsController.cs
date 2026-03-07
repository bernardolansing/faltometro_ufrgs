using System.Text;
using System.Text.Json;
using FaltometroUfrgsBackend.Models;
using FaltometroUfrgsBackend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Controllers;

[ApiController]
[Route("download-course-options")]
public class DownloadCourseOptionsController(AppDatabase db) : Controller
{
    /// <summary>
    /// Streams (if necessary) the list of course options from the database.
    ///
    /// First of all, if the provided generation number is updated, the response is a no-body 200. Otherwise, the
    /// response is a stream of JSON lines (JSONL, in other words each line is a serialized JSON object), each one
    /// corresponding to a course option. This allows the consumer to process data on-the-fly.
    /// </summary>
    /// <param name="generation">The courses list generation number that the consumer currently has downloaded. If
    /// updated, there'll be no need for a response.</param>
    [HttpGet]
    public async Task Get(uint? generation)
    {
        // User has submitted a generation number, we must check if it matches with the most recent generation.
        if (generation != null)
        {
            var result = await db.Generations.Where(g => g.Id == Generation.CourseOptionsGenerationId)
                .Select(g => g.GenerationNumber)
                .ToListAsync();
            // User already has the most recent courses downloaded:
            if (generation == result.First())
                return;
        }

        var enumerable = db.CourseOptions.Include(p => p.CourseOptionsClassSessions)
            .AsAsyncEnumerable();
        await foreach (var course in enumerable)
        {
            var line = JsonSerializer.Serialize(course) + '\n';
            var mem = new ReadOnlyMemory<byte>(Encoding.UTF8.GetBytes(line));
            await Response.BodyWriter.WriteAsync(mem);
        }
    }
}