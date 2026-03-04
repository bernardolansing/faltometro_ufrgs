using System.Text.Json;
using FaltometroUfrgsBackend.Models;
using FaltometroUfrgsBackend.Services;
using Google.Rpc.Context;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Controllers;

[ApiController]
[Route("download-courses")]
public class DownloadCoursesController(AppDatabase db)
{
    [HttpGet]
    public async Task<ActionResult<string>> Get([FromQuery] uint? generation)
    {
        // User has submitted a generation number, we must check if it matches with the most recent generation.
        if (generation != null)
        {
            var result = await db.Generations.Where(g => g.Id == Generation.CoursesGenerationId)
                .Select(g => g.GenerationNumber)
                .ToListAsync();
            // User already has the most recent courses downloaded:
            if (generation == result.First())
                return new NoContentResult();
        }
        
        var allCourses = await db.Courses.ToArrayAsync();
        return string.Join("\n", allCourses.Select(course => JsonSerializer.Serialize(course)));
    }
}