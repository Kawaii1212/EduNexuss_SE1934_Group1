using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Repositories;

public interface IQuizAttemptRepository
{
    List<QuizAttempt> GetByStudentId(long studentId);
    QuizAttempt? GetAttemptForResult(long attemptId);
    QuizAttempt? GetAttemptForReviewAndAnalysis(long attemptId);
    List<Question> GetPublishedQuestions(long courseId, long? moduleId, string difficulty, int count);
    Quiz CreatePracticeQuiz(long courseId, string name, string difficulty, int questionCount, long studentId, List<Question> questions);
    QuizAttempt CreateAttempt(long quizId, long studentId);
    QuizAttempt? GetAttemptForTaking(long attemptId);
    void SubmitAttempt(long attemptId, Dictionary<long, string> answers);
}
