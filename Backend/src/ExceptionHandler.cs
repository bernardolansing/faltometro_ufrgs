using System.Net;
using Microsoft.AspNetCore.Diagnostics;

namespace FaltometroUfrgsBackend;

public class ExceptionHandler(ILogger<ExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancelToken)
    {
        HttpStatusCode statusCode;
        
        string message;
        var errorCode = exception.GetType().Name;
        var serverError = false;

        switch (exception)
        {
            default:
                Console.WriteLine($"Unhandled exception: {exception}"); // TODO: turn this into a error log.
                serverError = true;
                statusCode = HttpStatusCode.InternalServerError;
                errorCode = "InternalServerError";
                message = "Internal server error.";
                break;
        }
        
        if (serverError)
            logger.LogError("Unhandled exception/internal server error: {Exception}", exception);
        
        context.Response.StatusCode = (int) statusCode;
        var body = new Dictionary<string, string>
        {
            ["code"] = errorCode,
            ["message"] = message
        };
        await context.Response.WriteAsJsonAsync(body, cancelToken);
        
        return true;
    }
}