using System.Linq;
using Microsoft.EntityFrameworkCore;
using EduNexus.Models;

namespace EduNexus.DAOs;

public class SubmissionDAO : BaseDAO<Submission>
{
    private static SubmissionDAO? instance = null;
    private static readonly object instanceLock = new object();

    private SubmissionDAO() { }

    public static new SubmissionDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                {
                    instance = new SubmissionDAO();
                }
                return instance;
            }
        }
    }

    public Submission? GetByAssignmentAndStudent(long assignmentId, long studentId)
    {
        using var context = GetContext();
        return context.Submissions
            .FirstOrDefault(s => s.AssignmentId == assignmentId && s.StudentId == studentId);
    }

    public Submission? GetByIdWithDetails(long submissionId)
    {
        using var context = GetContext();
        return context.Submissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
            .FirstOrDefault(s => s.Id == submissionId);
    }

    public Submission? GetResultWithDetails(long submissionId)
    {
        using var context = GetContext();
        return context.Submissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
            .Include(s => s.SubmissionCriterionScores)
                .ThenInclude(scs => scs.Criterion)
            .FirstOrDefault(s => s.Id == submissionId);
    }

    public List<Submission> GetAllWithDetails()
    {
        using var context = GetContext();
        return context.Submissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
            .OrderByDescending(s => s.SubmittedAt)
            .ToList();
    }

    public List<AssignmentRubricCriterion> GetAssignmentRubrics(long assignmentId)
    {
        using var context = GetContext();
        return context.AssignmentRubricCriteria
            .Where(r => r.AssignmentId == assignmentId)
            .ToList();
    }

    public void UpdateAiEvaluation(Submission submission, List<SubmissionCriterionScore> newScores)
    {
        using var context = GetContext();
        // Update submission fields
        context.Submissions.Update(submission);
        
        // Handle SubmissionCriterionScores
        foreach (var score in newScores)
        {
            var existing = context.SubmissionCriterionScores
                .FirstOrDefault(s => s.SubmissionId == score.SubmissionId && s.CriterionId == score.CriterionId);
            
            if (existing != null)
            {
                existing.AiScore = score.AiScore;
                existing.AiFeedback = score.AiFeedback;
                context.SubmissionCriterionScores.Update(existing);
            }
            else
            {
                context.SubmissionCriterionScores.Add(score);
            }
        }
        
        context.SaveChanges();
    }
}
