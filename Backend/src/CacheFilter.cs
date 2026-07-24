using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend;

/// <summary>
/// Intercepts a GET request towards a given resource, reads (if present) the If-Modified-Since header and checks if the
/// client's copy is updated. If it is, immediately returns a response with code 304 (not modified). Otherwise, forwards
/// the request to the filtered endpoint.
/// </summary>
/// <typeparam name="T">The type of the resource to be cached.</typeparam>
internal class CacheFilter<T>(AppDatabase db, ILogger<CacheFilter<T>> logger) : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var modifiedSinceArg = context.HttpContext.Request.Headers.IfModifiedSince.FirstOrDefault();
        if (modifiedSinceArg != null && DateTime.TryParse(modifiedSinceArg, out var modifiedSince))
        {
            var entityType = db.Model.FindEntityType(typeof(T));
            var tableName = entityType!.GetTableName()!;
            var mostRecentExtraction = await db.Extractions.Where(ex => ex.Resource == tableName && ex.Successful)
                .OrderByDescending(ex => ex.ExtractionDate)
                .FirstOrDefaultAsync();
            if (mostRecentExtraction != null && mostRecentExtraction.ExtractionDate < modifiedSince)
            {
                logger.LogInformation("Received updated If-Modified-Since header, skipping download");
                context.HttpContext.Response.StatusCode = StatusCodes.Status304NotModified;
                return ValueTask.CompletedTask;
            }
            
            logger.LogInformation("Received outdated If-Modified-Since header, proceeding to download");
        }

        return await next(context);
    }
}