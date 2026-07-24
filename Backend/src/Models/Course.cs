using System.ComponentModel.DataAnnotations;

namespace FaltometroUfrgsBackend.Models;

/// <summary>
/// A course that exists in at least one program's curriculum. It may or may not be available for enrollment. It it is,
/// <c>CourseOption</c>s bind the Course to its enrollment options.
/// </summary>
public class Course(string code, string title)
{
    /// <summary>
    /// Eight characters long course code. Uniquely identifies the course. Normally it starts with three letters that
    /// indicate which school ministers the course, but that's not a rule.
    /// </summary>
    [Key, MaxLength(8)]
    public string Code { get; init; } = code;
    
    /// <summary>
    /// Presentable name for the course.
    /// </summary>
    public string Title { get; init; } = title;
}
