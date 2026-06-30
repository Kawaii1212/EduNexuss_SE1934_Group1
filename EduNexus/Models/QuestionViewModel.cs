using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DataAccessLayer.Models;
using Microsoft.AspNetCore.Http;

namespace EduNexus.Models;

public class QuestionBankViewModel
{
    public List<Question> Questions { get; set; } = new();
    public List<Module> Modules { get; set; } = new();
    public long? SelectedModuleId { get; set; }
    public string? SelectedDifficulty { get; set; }
    public string? SelectedStatus { get; set; }
    public string? SearchTerm { get; set; }
}

public class QuestionFormViewModel
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn Module")]
    public long ModuleId { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập nội dung câu hỏi")]
    [MinLength(5, ErrorMessage = "Nội dung câu hỏi phải có ít nhất 5 ký tự")]
    public string Content { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng nhập đáp án A")]
    public string OptionA { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng nhập đáp án B")]
    public string OptionB { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng nhập đáp án C")]
    public string OptionC { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng nhập đáp án D")]
    public string OptionD { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng chọn đáp án đúng")]
    [RegularExpression("^[A-D]$", ErrorMessage = "Đáp án đúng phải là A, B, C hoặc D")]
    public string CorrectOption { get; set; } = "A";

    [Required(ErrorMessage = "Vui lòng chọn độ khó")]
    public string Difficulty { get; set; } = "MEDIUM";

    public string? AiExplanation { get; set; }

    public List<Module>? Modules { get; set; }
}

public class QuestionImportViewModel
{
    [Required(ErrorMessage = "Vui lòng chọn Module để nhập câu hỏi")]
    public long ModuleId { get; set; }

    public IFormFile? File { get; set; }

    public string? CsvText { get; set; }

    public List<Module>? Modules { get; set; }

    public List<string>? ImportErrors { get; set; }

    public int? SuccessCount { get; set; }
}
