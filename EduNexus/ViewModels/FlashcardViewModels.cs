using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace EduNexus.ViewModels;

public class FlashcardItemViewModel
{
    public long Id { get; set; }
    public string FrontText { get; set; } = "";
    public string BackText { get; set; } = "";
}

public class FlashcardEditorViewModel
{
    public long DeckId { get; set; }
    public long CourseId { get; set; }
    public long ModuleId { get; set; }

    [Required(ErrorMessage = "Tên bộ thẻ là bắt buộc")]
    [MaxLength(255)]
    public string Name { get; set; } = "";

    [MaxLength(100)]
    public string Category { get; set; } = "";

    public string Status { get; set; } = "DRAFT";
    public List<FlashcardItemViewModel> Cards { get; set; } = new();
    public List<ModuleOptionViewModel> Modules { get; set; } = new();
}

public class ModuleOptionViewModel
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
}

public class FlashcardStagingViewModel
{
    public long DeckId { get; set; }
    public string DeckName { get; set; } = "";
    public long CourseId { get; set; }
    public long ModuleId { get; set; }
    public GenerateFlashcardsRequest Form { get; set; } = new();
    public List<FlashcardItemViewModel> StagedCards { get; set; } = new();
    public string? SuccessMessage { get; set; }
    public string? ErrorMessage { get; set; }
    public int? LastTokensUsed { get; set; }
}

public class GenerateFlashcardsRequest
{
    public long DeckId { get; set; }

    [Required(ErrorMessage = "Chủ đề là bắt buộc")]
    [MinLength(3, ErrorMessage = "Chủ đề tối thiểu 3 ký tự")]
    public string Topic { get; set; } = "";

    [Range(1, 30)]
    public int CardCount { get; set; } = 10;

    public string? SourceMaterial { get; set; }
}

public class FlashcardLibraryViewModel
{
    public long? CourseId { get; set; }
    public string? Search { get; set; }
    public string? Category { get; set; }
    public List<FlashcardDeckSummaryViewModel> Decks { get; set; } = new();
    public List<CourseOptionViewModel> Courses { get; set; } = new();
}

public class FlashcardDeckSummaryViewModel
{
    public long DeckId { get; set; }
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public string CourseName { get; set; } = "";
    public int TotalCards { get; set; }
    public int MasteredCards { get; set; }
    public int DueCards { get; set; }
    public int MasteryPercent { get; set; }
}

public class CourseOptionViewModel
{
    public long Id { get; set; }
    public string Title { get; set; } = "";
}

public class FlashcardPracticeViewModel
{
    public long DeckId { get; set; }
    public string DeckName { get; set; } = "";
    public int TotalCards { get; set; }
    public int MasteredCards { get; set; }
    public List<FlashcardPracticeCardViewModel> Cards { get; set; } = new();
}

public class FlashcardPracticeCardViewModel
{
    public long FlashcardId { get; set; }
    public string FrontText { get; set; } = "";
    public string BackText { get; set; } = "";
    public string MemoryState { get; set; } = "NEW";
}

public class FlashcardPracticeSummaryViewModel
{
    public long DeckId { get; set; }
    public string MemoryState { get; set; } = "";
    public int RemainingCards { get; set; }
    public int MasteredCards { get; set; }
    public int TotalCards { get; set; }
    public bool IsComplete { get; set; }
}

public class SmeFlashcardListViewModel
{
    public long CourseId { get; set; }
    public string CourseTitle { get; set; } = "";
    public long? ModuleId { get; set; }
    public string? Search { get; set; }
    public List<ModuleOptionViewModel> Modules { get; set; } = new();
    public List<FlashcardDeckListItemViewModel> Decks { get; set; } = new();
}

public class FlashcardDeckListItemViewModel
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
    public string? Category { get; set; }
    public string Status { get; set; } = "";
    public int CardCount { get; set; }
    public string? ModuleName { get; set; }
}
