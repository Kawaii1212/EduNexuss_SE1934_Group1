using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using EduNexus.Models;

namespace EduNexus.DAOs;

public class QuizAttemptDAO : BaseDAO<QuizAttempt>
{
    private static QuizAttemptDAO? instance = null;
    private static readonly object instanceLock = new object();

    private QuizAttemptDAO() { }

    public static new QuizAttemptDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                {
                    instance = new QuizAttemptDAO();
                }
                return instance;
            }
        }
    }

    public List<QuizAttempt> GetByStudentIdWithDetails(long studentId)
    {
        using var context = GetContext();
        return context.QuizAttempts
            .Include(qa => qa.Quiz)
            .ThenInclude(q => q.Course)
            .Include(qa => qa.QuizAttemptAnswers)
            .Where(qa => qa.StudentId == studentId)
            .OrderByDescending(qa => qa.StartTime)
            .ToList();
    }
    public QuizAttempt? GetAttemptForResult(long attemptId)
    {
        using var context = GetContext();
        return context.QuizAttempts
            .Include(a => a.Quiz)
            .ThenInclude(q => q.QuizQuestions)
            .Include(a => a.QuizAttemptAnswers)
            .FirstOrDefault(a => a.Id == attemptId);
    }

    public QuizAttempt? GetAttemptForReviewAndAnalysis(long attemptId)
    {
        using var context = GetContext();
        return context.QuizAttempts
            .Include(a => a.Quiz)
            .Include(a => a.QuizAttemptAnswers)
                .ThenInclude(aa => aa.Question)
            .FirstOrDefault(a => a.Id == attemptId);
    }
}
