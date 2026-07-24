using FaltometroUfrgsBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend;

public class AppDatabase(IConfiguration config) : DbContext
{
    internal DbSet<Course> Courses { get; init; }
    internal DbSet<CourseOption> CourseOptions { get; init; }
    internal DbSet<CourseOptionClassSession> CourseOptionsClassSessions { get; init; }
    internal DbSet<Extraction> Extractions { get; init; }
    
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        Console.WriteLine("Starting AppDatabase service");
        optionsBuilder.UseNpgsql(config.GetConnectionString("DefaultConnection"))
            .UseSnakeCaseNamingConvention();
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Extraction>()
            .Property(e => e.ExtractionDate)
            .HasDefaultValueSql("current_timestamp")
            .ValueGeneratedOnAdd();
    }
}

[TestClass]
public class TestAppDatabase
{
    private readonly AppDatabase _db;
    
    public TestAppDatabase()
    {
        var config = new ConfigurationBuilder()
            .AddUserSecrets<AppDatabase>()
            .Build();
        _db = new AppDatabase(config);
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
