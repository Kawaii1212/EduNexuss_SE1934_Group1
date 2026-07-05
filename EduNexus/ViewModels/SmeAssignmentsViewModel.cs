using System;
using System.Collections.Generic;

namespace EduNexus.ViewModels
{
    public class SmeAssignmentsViewModel
    {
        public long CourseId { get; set; }
        public string CourseTitle { get; set; } = string.Empty;
        public string SmeName { get; set; } = string.Empty;
        public List<SmeAssignmentItemViewModel> Assignments { get; set; } = new List<SmeAssignmentItemViewModel>();
        
        // Statistics
        public int TotalAssignments => Assignments.Count;
        public int ActiveAssignments { get; set; }
        public int DraftAssignments { get; set; }
    }

    public class SmeAssignmentItemViewModel
    {
        public long Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string ClassName { get; set; } = string.Empty;
        public decimal MaxScore { get; set; }
        public DateTimeOffset DueDate { get; set; }
        public string Status { get; set; } = string.Empty; // DRAFT, PUBLISHED, CLOSED
        public int SubmissionCount { get; set; }
    }
}
