using Microsoft.AspNetCore.Mvc;

namespace FaltometroUfrgsBackend.Controllers;

[ApiController]
[Route("example")]
public class ExampleController
{
    [HttpGet]
    public string Get()
    {
        return "Hello World!";
    }
}