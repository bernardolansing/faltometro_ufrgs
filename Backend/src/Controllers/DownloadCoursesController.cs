using System.Text;
using System.Text.Json;
using FaltometroUfrgsBackend.Models;
using FaltometroUfrgsBackend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Controllers;

[ApiController]
[Route("download-courses")]
public class DownloadCoursesController(AppDatabase db) : Controller
{
    [HttpGet]
    public async Task Get([FromQuery] uint? generation)
    {
        // User has submitted a generation number, we must check if it matches with the most recent generation.
        if (generation != null)
        {
            var result = await db.Generations.Where(g => g.Id == Generation.CoursesGenerationId)
                .Select(g => g.GenerationNumber)
                .ToListAsync();
            // User already has the most recent courses downloaded:
            if (generation == result.First())
                return;
        }

        await foreach (var course in db.Courses.AsAsyncEnumerable())
        {
            var line = JsonSerializer.Serialize(course) + '\n';
            var mem = new ReadOnlyMemory<byte>(Encoding.UTF8.GetBytes(line));
            await Response.BodyWriter.WriteAsync(mem);
        }
    }
}