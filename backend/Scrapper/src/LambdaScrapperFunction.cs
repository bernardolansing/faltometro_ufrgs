using AngleSharp.Html.Dom;
using AngleSharp.Html.Parser;

namespace Scrapper;

public abstract class LambdaScrapperFunction
{
    private readonly HttpClient _client = new() { Timeout = TimeSpan.FromSeconds(180) };
    private readonly HtmlParser _parser = new();

    protected async Task<IHtmlDocument> FetchAndParseHtml(string url)
    {
        var htmlPage = await _client.GetStringAsync(url);
        return await _parser.ParseDocumentAsync(htmlPage);
    }
}