using System.Collections.Generic;

namespace EduNexus.Models
{
    public class PersonalProgressViewModel
    {
        public int CoursesEnrolled { get; set; }
        public int CoursesCompleted { get; set; }
        public int LearningHours { get; set; }
        public int CurrentStreak { get; set; }
        
        public List<OngoingCourseViewModel> OngoingCourses { get; set; } = new List<OngoingCourseViewModel>();
    }

    public class OngoingCourseViewModel
    {
        public long CourseId { get; set; }
        public string CourseName { get; set; } = string.Empty;
        public string CurrentModuleOrLesson { get; set; } = string.Empty;
        public decimal ProgressPercent { get; set; }
        
        // Mock icons for UI flair
        public string IconClass { get; set; } = "fa-book";
        public string IconColorHex { get; set; } = "var(--primary)";
    }
}
