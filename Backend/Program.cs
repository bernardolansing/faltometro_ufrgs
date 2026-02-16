using System.Text.Json;
using FaltometroUfrgsBackend.Services;

var builder = WebApplication.CreateBuilder(args);

var mvcBuilder = builder.Services.AddControllers();
mvcBuilder.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.AllowDuplicateProperties = false;
    options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
});
mvcBuilder.Services.AddDbContext<AppDatabase>();
mvcBuilder.Services.AddExceptionHandler<ExceptionHandler>();

var app = builder.Build();
app.UseExceptionHandler(_ => {});
app.MapControllers();
app.Run();
