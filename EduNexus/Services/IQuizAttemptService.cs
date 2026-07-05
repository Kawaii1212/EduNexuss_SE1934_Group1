using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Services;

public interface IQuizAttemptService
{
    List<QuizAttempt> GetHistoryForStudent(long studentId);
    EduNexus.ViewModels.QuizResultViewModel? GetQuizResultViewModel(long attemptId);
    EduNexus.ViewModels.QuizReviewViewModel? GetQuizReviewViewModel(long attemptId);
    System.Threading.Tasks.Task<string?> AnalyzeAttemptAsync(long attemptId);
}
