using System.Collections.Generic;

namespace EduNexus.ViewModels
{
    public class AllCoursesViewModel
    {
        public string SearchQuery { get; set; } = string.Empty;
        public List<CourseItemViewModel> Courses { get; set; } = new List<CourseItemViewModel>();
        public string StudentName { get; set; } = "Student";
        public bool IsGuest { get; set; } = false;
    }

    public class CourseItemViewModel
    {
        public long Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string InstructorName { get; set; } = string.Empty;
        public string ThumbnailUrl { get; set; } = string.Empty;
        public int Version { get; set; }
        public string CourseGroupName { get; set; } = string.Empty;
        public long? FirstLessonId { get; set; }
    }
}
