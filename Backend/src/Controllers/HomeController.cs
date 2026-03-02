using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace FaltometroUfrgsBackend.Controllers;

[ApiController]
[Route("/")]
public class HomeController : Controller
{
    [HttpGet]
    public string Get()
    {
        var userEmail = User.FindFirst(ClaimTypes.Email);
        var greet = "Hello from Faltômetro UFRGS backend! ";
        if (userEmail == null)
            greet += "You are currently not signed in.";
        else
            greet += $"You are currently signed in as {userEmail.Value}.";
        
        return greet;
    }
}