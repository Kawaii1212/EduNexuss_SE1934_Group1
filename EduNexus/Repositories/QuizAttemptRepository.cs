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
}
