using FaltometroUfrgsBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend.Services;

internal class AppDatabase : DbContext
{
    internal DbSet<Course> Courses { get; init; }
    internal DbSet<CourseOption> CourseOptions { get; init; }
    internal DbSet<CourseOptionClassSession> CourseOptionsClassSessions { get; init; }
    
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        DotNetEnv.Env.TraversePath().Load();
        var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
        var dbPort = Environment.GetEnvironmentVariable("DB_PORT");
        var dbUser = Environment.GetEnvironmentVariable("DB_USER");
        var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
        if (dbHost == null || dbPort == null || dbUser == null || dbPassword == null)
            throw new Exception("At least one of the Database credentials are null. Please populate .env with the " +
                                "connection details");
        
        var connectionString = $"Host={dbHost};Port={dbPort};Database=faltometro_ufrgs_db;Username={dbUser};" +
                               $"Password={dbPassword};Include Error Detail=true;";
        optionsBuilder.UseNpgsql(connectionString)
            .UseSnakeCaseNamingConvention();
    }
}

[TestClass]
public class TestAppDatabase
{
    private readonly AppDatabase _db = new();
    
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
