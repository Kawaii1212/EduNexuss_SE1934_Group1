using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using EduNexus.Models;
using EduNexus.Repositories;
using EduNexus.ViewModels;

namespace EduNexus.Services;

public class QuizAttemptService : IQuizAttemptService
{
    private readonly IQuizAttemptRepository _quizAttemptRepository;
    private readonly GeminiService _geminiService;

    public QuizAttemptService(IQuizAttemptRepository quizAttemptRepository, GeminiService geminiService)
    {
        _quizAttemptRepository = quizAttemptRepository;
        _geminiService = geminiService;
    }

    public List<QuizAttempt> GetHistoryForStudent(long studentId)
    {
        return _quizAttemptRepository.GetByStudentId(studentId);
    }

    public QuizResultViewModel? GetQuizResultViewModel(long attemptId)
    {
        var attempt = _quizAttemptRepository.GetAttemptForResult(attemptId);
        if (attempt == null) return null;

        return new QuizResultViewModel
        {
            AttemptId = attempt.Id,
            QuizId = attempt.QuizId,
            QuizName = attempt.Quiz.Name,
            Score = attempt.Score ?? 0,
            TotalQuestions = attempt.Quiz.QuizQuestions.Count,
            SubmittedAt = attempt.SubmitTime
        };
    }

    public QuizReviewViewModel? GetQuizReviewViewModel(long attemptId)
    {
        var attempt = _quizAttemptRepository.GetAttemptForReviewAndAnalysis(attemptId);
        if (attempt == null) return null;

        return new QuizReviewViewModel
        {
            AttemptId = attempt.Id,
            QuizName = attempt.Quiz.Name,
            Score = attempt.Score ?? 0,
            TotalQuestions = attempt.Quiz.QuestionCount,
            Questions = attempt.QuizAttemptAnswers.Select(aa => new QuizReviewQuestionViewModel
            {
                QuestionId = aa.QuestionId,
                Content = aa.Question.Content,
                OptionA = aa.Question.OptionA,
                OptionB = aa.Question.OptionB,
                OptionC = aa.Question.OptionC,
                OptionD = aa.Question.OptionD,
                CorrectOption = aa.Question.CorrectOption,
                SelectedOption = aa.SelectedOption ?? "",
                IsCorrect = aa.IsCorrect ?? false,
                AiExplanation = aa.Question.AiExplanation
            }).ToList()
        };
    }

    public async Task<string?> AnalyzeAttemptAsync(long attemptId)
    {
        var attempt = _quizAttemptRepository.GetAttemptForReviewAndAnalysis(attemptId);
        if (attempt == null) return null;

        var correctAnswers = attempt.QuizAttemptAnswers
            .Where(aa => aa.IsCorrect == true)
            .Select(aa => aa.Question.Content)
            .ToList();

        var incorrectAnswers = attempt.QuizAttemptAnswers
            .Where(aa => aa.IsCorrect == false)
            .Select(aa => aa.Question.Content)
            .ToList();

        if (!correctAnswers.Any() && !incorrectAnswers.Any())
        {
            return "Chưa có đủ dữ liệu để phân tích kết quả của bạn.";
        }

        var prompt = $@"
Dóng vai là một giáo viên chuyên môn, hãy phân tích điểm mạnh, điểm yếu của sinh viên sau khi làm bài kiểm tra '{attempt.Quiz.Name}'.
Dưới đây là các câu hỏi sinh viên đã trả lời ĐÚNG:
{string.Join("\n- ", correctAnswers.Take(10))}

Dưới đây là các câu hỏi sinh viên đã trả lời SAI:
{string.Join("\n- ", incorrectAnswers.Take(10))}

Hãy viết một đoạn phân tích ngắn (khoảng 3-4 dòng) về kết quả này và đưa ra 1-2 lời khuyên cụ thể để sinh viên cải thiện. Trả lời bằng Markdown gọn gàng.
Nếu có quá nhiều câu, tôi chỉ liệt kê tối đa 10 câu mỗi loại để bạn phân tích.
";

        return await _geminiService.GenerateTextAsync(prompt);
    }
}
