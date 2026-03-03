namespace FaltometroUfrgsBackend.Models;

public class Generation
{
    internal const string CoursesGenerationId = "courses";
    internal const string CourseOptionsGenerationId = "course_options";
    
    public string Id { get; init; }
    
    public int GenerationNumber { get; init; }
}
