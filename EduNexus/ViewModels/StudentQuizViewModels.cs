using System;
using System.Collections.Generic;

namespace EduNexus.ViewModels
{
    public class QuizResultViewModel
    {
        public long AttemptId { get; set; }
        public long QuizId { get; set; }
        public string QuizName { get; set; } = string.Empty;
        public decimal Score { get; set; }
        public int TotalQuestions { get; set; }
        public DateTimeOffset? SubmittedAt { get; set; }
    }

    public class QuizReviewQuestionViewModel
    {
        public long QuestionId { get; set; }
        public string Content { get; set; } = string.Empty;
        public string OptionA { get; set; } = string.Empty;
        public string OptionB { get; set; } = string.Empty;
        public string OptionC { get; set; } = string.Empty;
        public string OptionD { get; set; } = string.Empty;
        public string CorrectOption { get; set; } = string.Empty;
        public string SelectedOption { get; set; } = string.Empty;
        public bool IsCorrect { get; set; }
        public string? AiExplanation { get; set; }
    }

    public class QuizReviewViewModel
    {
        public long AttemptId { get; set; }
        public string QuizName { get; set; } = string.Empty;
        public decimal Score { get; set; }
        public int TotalQuestions { get; set; }
        public List<QuizReviewQuestionViewModel> Questions { get; set; } = new List<QuizReviewQuestionViewModel>();
    }
}
