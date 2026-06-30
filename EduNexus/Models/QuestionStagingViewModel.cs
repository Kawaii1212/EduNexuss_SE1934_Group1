using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using DataAccessLayer.Models;

namespace EduNexus.Models;

public class GenerateQuestionsRequest
{
    [Required(ErrorMessage = "Vui lòng chọn Module")]
    public long ModuleId { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập chủ đề")]
    [StringLength(300, ErrorMessage = "Chủ đề không quá 300 ký tự")]
    public string Topic { get; set; } = "";

    [Required]
    public string Difficulty { get; set; } = "MEDIUM";

    [Range(1, 20, ErrorMessage = "Số câu từ 1 đến 20")]
    public int Count { get; set; } = 5;
}

public class QuestionStagingViewModel
{
    public List<Question> StagedQuestions { get; set; } = new();
    public List<DataAccessLayer.Models.Module> Modules { get; set; } = new();
    public GenerateQuestionsRequest Form { get; set; } = new();
    public string? SuccessMessage { get; set; }
    public string? ErrorMessage { get; set; }
    public int LastTokensUsed { get; set; }
}
