using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Repositories;

public interface IQuizAttemptRepository
{
    List<QuizAttempt> GetByStudentId(long studentId);
    QuizAttempt? GetAttemptForResult(long attemptId);
    QuizAttempt? GetAttemptForReviewAndAnalysis(long attemptId);
}
