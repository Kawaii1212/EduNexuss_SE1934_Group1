using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Services;

public interface IQuizAttemptService
{
    List<QuizAttempt> GetHistoryForStudent(long studentId);
    EduNexus.ViewModels.QuizResultViewModel? GetQuizResultViewModel(long attemptId);
    EduNexus.ViewModels.QuizReviewViewModel? GetQuizReviewViewModel(long attemptId);
    System.Threading.Tasks.Task<string?> AnalyzeAttemptAsync(long attemptId);
    EduNexus.ViewModels.NewQuizViewModel GetNewQuizViewModel(long? courseId);
    long CreatePracticeQuiz(EduNexus.ViewModels.CreatePracticeQuizRequest request, long studentId);
    EduNexus.ViewModels.QuizTakingViewModel? GetTakingViewModel(long attemptId);
    long SubmitQuiz(long attemptId, Dictionary<long, string> answers);
}
