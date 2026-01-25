using System.Net;
using System.Text;
using AngleSharp.Html.Dom;
using AngleSharp.Html.Parser;

namespace Scraper;

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