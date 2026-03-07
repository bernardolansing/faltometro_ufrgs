using System.Net;
using FaltometroUfrgsBackend.Utils;
using Microsoft.AspNetCore.Diagnostics;

namespace FaltometroUfrgsBackend.Services;

public class ExceptionHandler : IExceptionHandler
{
    public ExceptionHandler()
    {
        Console.WriteLine("Starting ExceptionHandler service");
    }
    
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancelToken)
    {
        HttpStatusCode statusCode;
        string message;
        var serverError = false;

        switch (exception)
        {
            case InvalidUfrgsSessionToken:
                statusCode = HttpStatusCode.Unauthorized;
                message = "Missing/invalid UFRGS dashboard session token";
                break;
            default:
                Console.WriteLine($"Unhandled exception: {exception}"); // TODO: turn this into a error log.
                serverError = true;
                statusCode = HttpStatusCode.InternalServerError;
                message = "Internal server error.";
                break;
        }
        
        // TODO: turn this into a error log, rather than just a println.
        if (serverError)
            Console.WriteLine($"Unhandled exception/internal server error: {exception}");
        context.Response.ContentType = "application/text";
        context.Response.StatusCode = (int) statusCode;
        await context.Response.WriteAsync(message, cancelToken);
        return !serverError; // Return whether the exception was handled. We consider the exception to be handled if it
        // is due to a client error, instead of a server error.
    }
}