using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FaltometroUfrgsBackend.Models;

public class CourseOption
{
    public int Id { get; init; }
    
    [ForeignKey(nameof(Course))]
    public required string CourseCode { get; init; }
    
    [MaxLength(2)]
    public required string OptionName { get; init; }
    
    public required List<CourseOptionClassSession> CourseOptionsClassSessions { get; init; }
}