using FaltometroUfrgsBackend.Services;
using Microsoft.EntityFrameworkCore;

namespace FaltometroUfrgsBackend;

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