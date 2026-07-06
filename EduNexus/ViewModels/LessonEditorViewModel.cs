using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace EduNexus.ViewModels
{
    public class LessonEditorViewModel
    {
        public long LessonId { get; set; }
        
        public long ModuleId { get; set; }
        
        public long CourseId { get; set; }

        [Required(ErrorMessage = "Title is required")]
        public string Title { get; set; } = null!;

        public string? Content { get; set; }

        public string? VideoUrl { get; set; }

        public IFormFile[]? Attachments { get; set; }
    }
}
