using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Text;
using AngleSharp.Html.Dom;
using AngleSharp.Html.Parser;
using Microsoft.EntityFrameworkCore;

namespace Scraper;

public abstract class LambdaScraperFunction
{
    protected readonly AppDatabase Db = new();
}

internal class ScraperClient
{
    private static readonly byte[] ExpiredSessionHtmlStr;
    
    private readonly HttpClient _client;
    private readonly HtmlParser _parser = new();

    static ScraperClient()
    {
        ExpiredSessionHtmlStr = Encoding.Latin1.GetBytes(
            "\t\t<script language=\"javascript\">\r\n\t\t\talert(\"Sua sessão expirou.\");\r\n\t\t\t" +
            "window.open(\"http://www.ufrgs.br\",\"_parent\",\"\");\r\n\t\t</script>\r\n\t");
    }

    internal ScraperClient()
    {
        _client = new HttpClient { Timeout = TimeSpan.FromSeconds(180) };
    }

    internal ScraperClient(string sessionId)
    {
        var clientHandler = new HttpClientHandler
        {
            CookieContainer = new CookieContainer(),
            UseCookies = true
        };
        var cookie = new Cookie("PHPSESSID", sessionId) { Domain = "www1.ufrgs.br" };
        clientHandler.CookieContainer.Add(cookie);
        _client = new HttpClient(clientHandler) { Timeout = TimeSpan.FromSeconds(180) };
    }

    internal async Task<IHtmlDocument> FetchAndParseHtml(string url)
    {
        var response = await _client.GetAsync(url);
        var responseBodyBytes = await response.Content.ReadAsByteArrayAsync();
        if (Enumerable.SequenceEqual(ExpiredSessionHtmlStr, responseBodyBytes))
            throw new Exception("Provided session ID token is expired");
        var responseBodyString = Encoding.Latin1.GetString(responseBodyBytes);
        return await _parser.ParseDocumentAsync(responseBodyString);
    }
}

public class Course(string code, string title)
{
    [Key, MaxLength(8)]
    public string Code { get; init; } = code;
    
    public string Title { get; init; } = title;
}

public class AppDatabase : DbContext
{
    public DbSet<Course> Courses { get; init; }
    
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
