using FaltometroUfrgsBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Services;

public class AppDatabase(ISecretProviderService secretProviderService) : DbContext
{
    internal DbSet<Course> Courses { get; init; }
    internal DbSet<CourseOption> CourseOptions { get; init; }
    internal DbSet<CourseOptionClassSession> CourseOptionsClassSessions { get; init; }
    internal DbSet<Generation> Generations { get; init; }
    
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        Console.WriteLine("Starting AppDatabase service");
        var connectionString = secretProviderService.GetDatabaseConnectionString();
        optionsBuilder.UseNpgsql(connectionString)
            .UseSnakeCaseNamingConvention();
    }
}

[TestClass]
public class TestAppDatabase
{
    private readonly AppDatabase _db = new(new LocalDevSecretProviderService());
    
    public TestAppDatabase()
    {
        _db.Database.EnsureCreated();
        _db.Database.BeginTransaction();
    }

    ~TestAppDatabase()
    {
        _db.Database.RollbackTransaction();
    }
    
    [TestMethod]
    public void TestListCourses()
    {
        var courses = _db.Courses.ToList();
        Console.WriteLine($"Found {courses.Count} courses!");
    }

    [TestMethod]
    public void TestListGenerations()
    {
        var generations = _db.Generations.ToList();
        foreach (var generation in generations)
            Console.WriteLine($"Generation {generation.Id} -> {generation.GenerationNumber}");
    }

    [TestMethod]
    public void TestAddCourse()
    {
        var course = new Course("EXA01234", "Course example");
        _db.Courses.Add(course);
        _db.SaveChanges();
    }

    [TestMethod]
    public void TestAddCourseOption()
    {
        var classSession = new CourseOptionClassSession
        {
            Periods = 2,
            StartingTime = "13:30",
            Weekday = 3
        };
        var courseOption = new CourseOption
        {
            CourseCode = "INF01202", // Example of a course code that exists.
            OptionName = "B",
            CourseOptionsClassSessions = [classSession]
        };
        
        _db.CourseOptions.Add(courseOption);
        _db.SaveChanges();
    }
}
