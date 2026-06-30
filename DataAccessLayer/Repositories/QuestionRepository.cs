using System.Collections.Generic;
using DataAccessLayer.DAOs;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public class QuestionRepository : IQuestionRepository
{
    public List<Question> GetDraftsByModuleId(long moduleId)
        => QuestionDAO.Instance.GetDraftsByModuleId(moduleId);

    public List<Module> GetAllModules()
        => QuestionDAO.Instance.GetAllModules();

    public void AddRange(List<Question> questions)
        => QuestionDAO.Instance.AddRange(questions);

    public bool Approve(long questionId, long approvedByUserId)
        => QuestionDAO.Instance.Approve(questionId, approvedByUserId);

    public bool Reject(long questionId)
        => QuestionDAO.Instance.Reject(questionId);

    public bool DeleteDraft(long questionId)
        => QuestionDAO.Instance.DeleteDraft(questionId);

    public Question? GetById(long id)
        => QuestionDAO.Instance.GetById(id);

    public void Add(Question question)
        => QuestionDAO.Instance.Add(question);

    public void Update(Question question)
        => QuestionDAO.Instance.Update(question);

    public void Delete(Question question)
        => QuestionDAO.Instance.Delete(question);

    public List<Question> GetQuestions(long? moduleId, string? difficulty, string? status, string? searchTerm)
        => QuestionDAO.Instance.GetQuestions(moduleId, difficulty, status, searchTerm);
}
