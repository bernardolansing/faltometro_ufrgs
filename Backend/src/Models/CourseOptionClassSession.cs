using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FaltometroUfrgsBackend.Models;

public class CourseOptionClassSession
{
    public int Id { get; init; }
    
    [MaxLength(5)]
    public required string StartingTime { get; init; }
    
    public required short Weekday { get; init; }
    
    public required short Periods { get; init; }
    
    public string? Location { get; set; }
    
    [ForeignKey(nameof(CourseOption))]
    public int CourseOptionId { get; init; }
}
