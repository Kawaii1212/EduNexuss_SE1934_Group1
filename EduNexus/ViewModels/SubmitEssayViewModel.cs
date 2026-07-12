using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace EduNexus.ViewModels;

public class SubmitEssayViewModel
{
    [Required]
    public long AssignmentId { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập nội dung bài làm.")]
    public string Content { get; set; } = string.Empty;

    public IFormFile? AttachedFile { get; set; }

    public long? LessonId { get; set; }
}
