using System.Collections.Generic;

namespace EduNexus.ViewModels
{
    public class SmeCoursesViewModel
    {
        public string SmeName { get; set; } = string.Empty;
        public List<SmeCourseItemViewModel> Courses { get; set; } = new List<SmeCourseItemViewModel>();
    }

    public class SmeCourseItemViewModel
    {
        public long Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string CourseGroupName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public int ModuleCount { get; set; }
        public int ClassCount { get; set; }
    }

    public class SmeCourseStructureViewModel
    {
        public long CourseId { get; set; }
        public string CourseTitle { get; set; } = string.Empty;
        public string CourseGroupName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public List<SmeModuleItemViewModel> Modules { get; set; } = new List<SmeModuleItemViewModel>();
    }

    public class SmeModuleItemViewModel
    {
        public long Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int OrderNo { get; set; }
        public List<SmeLessonItemViewModel> Lessons { get; set; } = new List<SmeLessonItemViewModel>();
        public int QuestionCount { get; set; }
        public int AssignmentCount { get; set; }
        public int FlashcardCount { get; set; }
        public int QuizCount { get; set; }
    }

    public class SmeLessonItemViewModel
    {
        public long Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public int OrderNo { get; set; }
    }
}
