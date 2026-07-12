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
    public int CorrectCount { get; set; }
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

public class NewQuizViewModel
{
    public List<CourseOptionViewModel> Courses { get; set; } = new();
    public List<ModuleOptionViewModel> Modules { get; set; } = new();
    public CreatePracticeQuizRequest Form { get; set; } = new();
    public string? ErrorMessage { get; set; }
}

public class CreatePracticeQuizRequest
{
    public long CourseId { get; set; }
    public long? ModuleId { get; set; }

    [System.ComponentModel.DataAnnotations.Required]
    public string QuizName { get; set; } = "";

    [System.ComponentModel.DataAnnotations.Required]
    public string Difficulty { get; set; } = "MEDIUM";

    [System.ComponentModel.DataAnnotations.Range(1, 50)]
    public int QuestionCount { get; set; } = 10;
}

public class QuizTakingViewModel
{
    public long AttemptId { get; set; }
    public string QuizName { get; set; } = "";
    public int DurationMinutes { get; set; } = 30;
    public int CurrentIndex { get; set; }
    public List<QuizTakingQuestionViewModel> Questions { get; set; } = new();
}

public class QuizTakingQuestionViewModel
{
    public long QuestionId { get; set; }
    public int OrderNo { get; set; }
    public string Content { get; set; } = "";
    public string OptionA { get; set; } = "";
    public string OptionB { get; set; } = "";
    public string OptionC { get; set; } = "";
    public string OptionD { get; set; } = "";
    public string? SelectedOption { get; set; }
}

public class SubmitQuizRequest
{
    public long AttemptId { get; set; }
    public Dictionary<long, string> Answers { get; set; } = new();
}
}
