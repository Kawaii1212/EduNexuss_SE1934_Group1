using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.ViewModels
{
    public class LessonViewModel
    {
        public Lesson CurrentLesson { get; set; } = null!;
        public Course Course { get; set; } = null!;
        public List<Module> Modules { get; set; } = new List<Module>();
        public bool IsPreview { get; set; }
        public bool IsGuest { get; set; }
        public bool IsCompleted { get; set; }
        public decimal ProgressPercent { get; set; }
    }
}
