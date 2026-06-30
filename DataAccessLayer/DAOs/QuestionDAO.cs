using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using DataAccessLayer.Models;

namespace DataAccessLayer.DAOs;

public class QuestionDAO : BaseDAO<Question>
{
    private static QuestionDAO? instance = null;
    private static readonly object instanceLock = new object();

    private QuestionDAO() { }

    public static new QuestionDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                    instance = new QuestionDAO();
                return instance;
            }
        }
    }

    public List<Question> GetDraftsByModuleId(long moduleId)
    {
        using var context = GetContext();
        return context.Questions
            .Include(q => q.Module)
            .Where(q => q.ModuleId == moduleId && q.Status == "DRAFT")
            .OrderByDescending(q => q.CreatedAt)
            .ToList();
    }

    public void AddRange(List<Question> questions)
    {
        using var context = GetContext();
        context.Questions.AddRange(questions);
        context.SaveChanges();
    }

    public bool Approve(long questionId, long approvedByUserId)
    {
        using var context = GetContext();
        var q = context.Questions.Find(questionId);
        if (q == null) return false;
        q.Status = "APPROVED";
        q.ApprovedBy = approvedByUserId;
        context.SaveChanges();
        return true;
    }

    public bool Reject(long questionId)
    {
        using var context = GetContext();
        var q = context.Questions.Find(questionId);
        if (q == null) return false;
        q.Status = "REJECTED";
        context.SaveChanges();
        return true;
    }

    public bool DeleteDraft(long questionId)
    {
        using var context = GetContext();
        var q = context.Questions.Find(questionId);
        if (q == null || q.Status != "DRAFT") return false;
        context.Questions.Remove(q);
        context.SaveChanges();
        return true;
    }

    public List<Module> GetAllModules()
    {
        using var context = GetContext();
        return context.Modules
            .Include(m => m.Course)
            .OrderBy(m => m.CourseId)
            .ThenBy(m => m.OrderNo)
            .ToList();
    }

    public Question? GetById(long id)
    {
        using var context = GetContext();
        return context.Questions
            .Include(q => q.Module)
            .ThenInclude(m => m.Course)
            .Include(q => q.CreatedByNavigation)
            .FirstOrDefault(q => q.Id == id);
    }

    public List<Question> GetQuestions(long? moduleId, string? difficulty, string? status, string? searchTerm)
    {
        using var context = GetContext();
        var query = context.Questions
            .Include(q => q.Module)
            .ThenInclude(m => m.Course)
            .AsQueryable();

        if (moduleId.HasValue && moduleId.Value > 0)
        {
            query = query.Where(q => q.ModuleId == moduleId.Value);
        }

        if (!string.IsNullOrEmpty(difficulty))
        {
            query = query.Where(q => q.Difficulty == difficulty.ToUpper());
        }

        if (!string.IsNullOrEmpty(status))
        {
            query = query.Where(q => q.Status == status.ToUpper());
        }

        if (!string.IsNullOrEmpty(searchTerm))
        {
            query = query.Where(q => q.Content.Contains(searchTerm));
        }

        return query.OrderByDescending(q => q.CreatedAt).ToList();
    }
}
