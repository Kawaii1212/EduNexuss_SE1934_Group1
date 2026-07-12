using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using EduNexus.Models;

namespace EduNexus.DAOs;

public class QuizDAO : BaseDAO<Quiz>
{
    private const string ApprovedQuestionStatus = DbStatus.Question.Approved;
    private const string PublishedQuizStatus = DbStatus.Quiz.Published;
    private static QuizDAO? _instance;
    private static readonly object InstanceLock = new();

    private QuizDAO() { }

    public static new QuizDAO Instance
    {
        get
        {
            lock (InstanceLock)
            {
                return _instance ??= new QuizDAO();
            }
        }
    }

    public List<Question> GetPublishedQuestions(long courseId, long? moduleId, string difficulty, int count)
    {
        using var context = GetContext();
        var query = context.Questions
            .Include(q => q.Module)
            .Where(q => q.Module.CourseId == courseId && q.Status == ApprovedQuestionStatus);

        if (moduleId.HasValue && moduleId.Value > 0)
            query = query.Where(q => q.ModuleId == moduleId);

        if (!string.IsNullOrWhiteSpace(difficulty) && difficulty.ToUpper() != "ALL")
            query = query.Where(q => q.Difficulty == difficulty.ToUpper());

        var all = query.ToList();
        return all.OrderBy(_ => Guid.NewGuid()).Take(Math.Min(count, all.Count)).ToList();
    }

    public Quiz CreatePracticeQuiz(long courseId, string name, string difficulty, int questionCount, long studentId, List<Question> questions)
    {
        using var context = GetContext();
        var normalizedDifficulty = string.IsNullOrWhiteSpace(difficulty) || difficulty.ToUpper() == "ALL"
            ? "MEDIUM"
            : difficulty.ToUpper();
        var quiz = new Quiz
        {
            CourseId = courseId,
            Name = name,
            Difficulty = normalizedDifficulty,
            QuestionCount = questions.Count,
            Status = PublishedQuizStatus,
            IsPracticeGenerated = true,
            CreatedBy = studentId,
            CreatedAt = DateTimeOffset.UtcNow
        };
        context.Quizzes.Add(quiz);
        context.SaveChanges();

        for (var i = 0; i < questions.Count; i++)
        {
            context.QuizQuestions.Add(new QuizQuestion
            {
                QuizId = quiz.Id,
                QuestionId = questions[i].Id,
                OrderNo = i + 1
            });
        }

        context.SaveChanges();
        return quiz;
    }

    public QuizAttempt CreateAttempt(long quizId, long studentId)
    {
        using var context = GetContext();
        var attempt = new QuizAttempt
        {
            QuizId = quizId,
            StudentId = studentId,
            StartTime = DateTimeOffset.UtcNow,
            Status = "IN_PROGRESS"
        };
        context.QuizAttempts.Add(attempt);
        context.SaveChanges();
        return attempt;
    }

    public QuizAttempt? GetAttemptForTaking(long attemptId)
    {
        using var context = GetContext();
        return context.QuizAttempts
            .Include(a => a.Quiz)
                .ThenInclude(q => q.QuizQuestions)
                    .ThenInclude(qq => qq.Question)
            .FirstOrDefault(a => a.Id == attemptId);
    }

    public void SubmitAttempt(long attemptId, Dictionary<long, string> answers)
    {
        using var context = GetContext();
        var attempt = context.QuizAttempts
            .Include(a => a.Quiz)
                .ThenInclude(q => q.QuizQuestions)
                    .ThenInclude(qq => qq.Question)
            .FirstOrDefault(a => a.Id == attemptId);

        if (attempt == null || attempt.Status != DbStatus.QuizAttempt.InProgress) return;

        var correct = 0;
        foreach (var qq in attempt.Quiz.QuizQuestions.OrderBy(x => x.OrderNo))
        {
            answers.TryGetValue(qq.QuestionId, out var selected);
            var isCorrect = !string.IsNullOrEmpty(selected) &&
                            string.Equals(selected.Trim(), qq.Question.CorrectOption.Trim(),
                                StringComparison.OrdinalIgnoreCase);
            if (isCorrect) correct++;

            context.QuizAttemptAnswers.Add(new QuizAttemptAnswer
            {
                AttemptId = attemptId,
                QuestionId = qq.QuestionId,
                SelectedOption = selected,
                IsCorrect = isCorrect
            });
        }

        var total = attempt.Quiz.QuizQuestions.Count;
        attempt.Score = total > 0 ? Math.Round((decimal)correct / total * 100, 2) : 0;
        attempt.SubmitTime = DateTimeOffset.UtcNow;
        attempt.Status = DbStatus.QuizAttempt.Submitted;

        context.LearningProgresses.Add(new LearningProgress
        {
            StudentId = attempt.StudentId,
            ActivityType = DbStatus.LearningProgress.Quiz,
            CompletionStatus = DbStatus.LearningProgress.Completed,
            Score = attempt.Score,
            TimeSpentSeconds = (int)Math.Max(0, (attempt.SubmitTime.Value - attempt.StartTime).TotalSeconds),
            AttemptCount = 1,
            LastActiveAt = DateTimeOffset.UtcNow
        });

        context.SaveChanges();
    }
}
