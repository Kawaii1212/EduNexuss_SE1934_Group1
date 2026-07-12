using System.Collections.Generic;
using EduNexus.DAOs;
using EduNexus.Models;

namespace EduNexus.Repositories;

public class QuizAttemptRepository : IQuizAttemptRepository
{
    public List<QuizAttempt> GetByStudentId(long studentId)
    {
        return QuizAttemptDAO.Instance.GetByStudentIdWithDetails(studentId);
    }

    public QuizAttempt? GetAttemptForResult(long attemptId)
    {
        return QuizAttemptDAO.Instance.GetAttemptForResult(attemptId);
    }

    public QuizAttempt? GetAttemptForReviewAndAnalysis(long attemptId)
    {
        return QuizAttemptDAO.Instance.GetAttemptForReviewAndAnalysis(attemptId);
    }

    public List<Question> GetPublishedQuestions(long courseId, long? moduleId, string difficulty, int count)
        => QuizDAO.Instance.GetPublishedQuestions(courseId, moduleId, difficulty, count);

    public Quiz CreatePracticeQuiz(long courseId, string name, string difficulty, int questionCount, long studentId, List<Question> questions)
        => QuizDAO.Instance.CreatePracticeQuiz(courseId, name, difficulty, questionCount, studentId, questions);

    public QuizAttempt CreateAttempt(long quizId, long studentId)
        => QuizDAO.Instance.CreateAttempt(quizId, studentId);

    public QuizAttempt? GetAttemptForTaking(long attemptId)
        => QuizDAO.Instance.GetAttemptForTaking(attemptId);

    public void SubmitAttempt(long attemptId, Dictionary<long, string> answers)
        => QuizDAO.Instance.SubmitAttempt(attemptId, answers);
}
