using System.ComponentModel.DataAnnotations;

namespace FaltometroUfrgsBackend.Models;

public class Course(string code, string title)
{
    [Key, MaxLength(8)]
    public string Code { get; init; } = code;
    
    public string Title { get; init; } = title;
}
