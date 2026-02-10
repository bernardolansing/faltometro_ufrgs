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

var app = builder.Build();
app.MapControllers();
app.Run();
