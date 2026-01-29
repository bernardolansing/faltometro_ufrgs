using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Scraper;

public class Course(string code, string title)
{
    [Key, MaxLength(8)]
    public string Code { get; init; } = code;
    
    public string Title { get; init; } = title;
}

public class CourseOption
{
    public int Id { get; init; }
    
    [ForeignKey(nameof(Course))]
    public required string CourseCode { get; init; }
    
    [MaxLength(2)]
    public required string OptionName { get; init; }
    
    public required List<CourseOptionClassSession> CourseOptionsClassSessions { get; init; }
}

public class CourseOptionClassSession
{
    public int Id { get; init; }
    
    [MaxLength(5)]
    public required string StartingTime { get; init; }
    
    public required short Weekday { get; init; }
    
    public required short Periods { get; init; }
    
    public string? Location { get; set; }
    
    [ForeignKey(nameof(CourseOption))]
    public int CourseOptionId { get; init; }
}

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
                               $"Password={dbPassword};";
        optionsBuilder.UseNpgsql(connectionString)
            .UseSnakeCaseNamingConvention();
    }
}

[TestClass]
public class TestAppDatabase
{
    [TestMethod]
    public async Task TestListCourses()
    {
        var db = new AppDatabase();
        await db.Database.EnsureCreatedAsync(TestContext.CancellationToken);
        var courses = await db.Courses.ToListAsync(TestContext.CancellationToken);
        Console.WriteLine($"Found {courses.Count} courses!");
    }

    [TestMethod]
    public async Task TestListCourseOptionsClassSessions()
    {
        var db = new AppDatabase();
        var sessions = await db.CourseOptionsClassSessions.ToListAsync(TestContext.CancellationToken);
        Console.WriteLine($"Found {sessions.Count} sessions!");
    }

    [TestMethod]
    public async Task TestListCourseOptions()
    {
        var db = new AppDatabase();
        var options = await db.CourseOptions.ToListAsync(TestContext.CancellationToken);
        Console.WriteLine($"Found {options.Count} course options!");
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

        var db = new AppDatabase();
        
        var transaction = db.Database.BeginTransaction();
        db.CourseOptions.Add(courseOption);
        db.SaveChanges();
        transaction.Rollback();
    }

    public TestContext TestContext { get; set; }
}