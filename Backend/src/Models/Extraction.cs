namespace FaltometroUfrgsBackend.Models;

public class Extraction
{
    public int Id { get; init; }
    public required string Resource { get; init; }
    public required bool Successful { get; init; }
    public DateTime ExtractionDate { get; init; }
}