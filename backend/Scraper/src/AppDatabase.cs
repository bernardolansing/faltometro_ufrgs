using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace Scraper;

public class Course(string code, string title)
{
    [Key, MaxLength(8)]
    public string Code { get; init; } = code;
    
    public string Title { get; init; } = title;
}

internal class AppDatabase : DbContext
{
    internal DbSet<Course> Courses { get; init; }
    
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

    public TestContext TestContext { get; set; }
}