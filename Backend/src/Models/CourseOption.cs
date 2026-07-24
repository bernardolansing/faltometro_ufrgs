using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FaltometroUfrgsBackend.Models;

/// <summary>
/// Option for enrollment in a given <c ref="Course">Course</c>.
/// </summary>
public class CourseOption
{
    public int Id { get; init; }
    
    [ForeignKey(nameof(Course))]
    public required string CourseCode { get; init; }
    
    [MaxLength(2)]
    public required string OptionName { get; init; }
    
    public required List<CourseOptionClassSession> CourseOptionsClassSessions { get; init; }
}