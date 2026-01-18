using Amazon.Lambda.Core;

// ReSharper disable UnusedMember.Global
// ReSharper disable UnusedType.Global

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
namespace Scrapper;

internal interface ILambdaEntrypoint
{
    public void Handler();
}

public class UpdateCourses : ILambdaEntrypoint
{
    public void Handler()
    {
        Console.WriteLine("Hello from Lambda!");
    }
}