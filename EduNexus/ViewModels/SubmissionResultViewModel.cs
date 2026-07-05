using System;
using System.Collections.Generic;

namespace EduNexus.ViewModels
{
    public class SubmissionResultViewModel
    {
        public long SubmissionId { get; set; }
        public string AssignmentTitle { get; set; } = string.Empty;
        public string StudentName { get; set; } = string.Empty;
        public decimal? FinalScore { get; set; }
        public decimal? AiScore { get; set; }
        public string? Feedback { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTimeOffset SubmittedAt { get; set; }
        
        public List<CriterionScoreViewModel> CriterionScores { get; set; } = new List<CriterionScoreViewModel>();
    }

    public class CriterionScoreViewModel
    {
        public string CriterionName { get; set; } = string.Empty;
        public decimal MaxScore { get; set; }
        public decimal WeightPercent { get; set; }
        public decimal? AiScore { get; set; }
        public decimal? FinalScore { get; set; }
        public string? AiFeedback { get; set; }
        public string? TeacherFeedback { get; set; }
    }
}
