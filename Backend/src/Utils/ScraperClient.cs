using System.Net;
using System.Text;
using AngleSharp.Html.Dom;
using AngleSharp.Html.Parser;

namespace FaltometroUfrgsBackend.Utils;

/// <summary>
/// Conveniences around an HTTP client. This object is designed to help making requests to UFRGS' websites, which is
/// useful when webscraping content from them.
/// </summary>
internal class ScraperClient
{
    private static readonly TimeSpan RequestTimeout = TimeSpan.FromSeconds(180);
    
    /// <summary>
    /// Byte sequence received when we access the UFRGS student dashboard with expired credentials. It's not a string,
    /// as the dashboard still uses Latin-1 as encoding format. So storing the bytes is easier.
    /// </summary>
    private static readonly byte[] ExpiredSessionHtmlStr;
    
    private readonly HttpClient _client;
    private readonly HtmlParser _parser = new();

    static ScraperClient()
    {
        ExpiredSessionHtmlStr = Encoding.Latin1.GetBytes(
            "\t\t<script language=\"javascript\">\r\n\t\t\talert(\"Sua sessão expirou.\");\r\n\t\t\t" +
            "window.open(\"http://www.ufrgs.br\",\"_parent\",\"\");\r\n\t\t</script>\r\n\t");
    }

    /// <summary>
    /// Constructor to be used when accessing only public routes.
    /// </summary>
    internal ScraperClient()
    {
        _client = new HttpClient { Timeout = RequestTimeout };
    }

    /// <summary>
    /// Constructor to be used when UFRGS student dashboard is going to be accessed. The token is going to be included
    /// in every request this client is going to make.
    /// </summary>
    /// <param name="sessionId">
    /// A valid session ID token to be shipped in every request. This constructor is not going to check the validity of
    /// the token.
    /// </param>
    internal ScraperClient(string sessionId)
    {
        var clientHandler = new HttpClientHandler
        {
            CookieContainer = new CookieContainer(),
            UseCookies = true
        };
        var cookie = new Cookie("PHPSESSID", sessionId) { Domain = "www1.ufrgs.br" };
        clientHandler.CookieContainer.Add(cookie);
        _client = new HttpClient(clientHandler) { Timeout = RequestTimeout };
    }

    internal async Task<IHtmlDocument> FetchAndParseHtml(string url)
    {
        var response = await _client.GetAsync(url);
        var responseBodyString = await GetBodyAndCheckSessionExpired(response);
        return await _parser.ParseDocumentAsync(responseBodyString);
    }

    /// <summary>
    /// Performs a POST request to the provided URL, while passing the contents of <c>formData</c> as a
    /// <i>x-www-form-urlencoded</i> body.
    /// </summary>
    /// <param name="url">Where to send the request to.</param>
    /// <param name="formData">The URL encoded form to be submitted.</param>
    /// <returns>The parsed HTML document received as response.</returns>
    internal async Task<IHtmlDocument> PostFormAndParseHtml(string url, Dictionary<string, string> formData)
    {
        var requestContent = new FormUrlEncodedContent(formData);
        var response = await _client.PostAsync(url, requestContent);
        var responseBodyString = await GetBodyAndCheckSessionExpired(response);
        return await _parser.ParseDocumentAsync(responseBodyString);
    }

    /// <summary>
    /// Transcodes the request body from Latin-1 to a C# native string while checking if the response is actually an
    /// "expired session token" message coming from UFRGS student dashboard.
    /// </summary>
    /// <param name="response">The received response to be checked.</param>
    /// <returns>The response body as a string.</returns>
    /// <exception cref="InvalidUfrgsSessionToken">
    /// Thrown if the request failed due to missing/invalid session token.
    /// </exception>
    private static async Task<string> GetBodyAndCheckSessionExpired(HttpResponseMessage response)
    {
        var responseBodyBytes = await response.Content.ReadAsByteArrayAsync();
        if (Enumerable.SequenceEqual(ExpiredSessionHtmlStr, responseBodyBytes))
            throw new InvalidUfrgsSessionToken();
        return Encoding.Latin1.GetString(responseBodyBytes);
    }
}

internal class InvalidUfrgsSessionToken : Exception;
