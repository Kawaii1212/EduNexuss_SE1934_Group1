using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using DataAccessLayer.Models;
using DataAccessLayer.Repositories;

namespace DataAccessLayer.Services;

// ─────────────────────────────────────────────
// Interface
// ─────────────────────────────────────────────
public interface IQuestionService
{
    Task<(List<Question> Questions, int TokensUsed)> GenerateAndSaveAsync(
        long moduleId, string topic, string difficulty, int count, long requesterId);

    List<Question> GetDraftsByModule(long moduleId);
    List<Module> GetAllModules();
    bool Approve(long questionId, long approvedByUserId);
    bool Reject(long questionId);
    bool DeleteDraft(long questionId);
    Question? GetById(long id);
    void Add(Question question);
    void AddRange(List<Question> questions);
    void Update(Question question);
    void Delete(Question question);
    List<Question> GetQuestions(long? moduleId, string? difficulty, string? status, string? searchTerm);
}

// ─────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────
public class QuestionService : IQuestionService
{
    private readonly IQuestionRepository _repo;
    private readonly GeminiService _gemini;

    public QuestionService(IQuestionRepository repo, GeminiService gemini)
    {
        _repo = repo;
        _gemini = gemini;
    }

    public async Task<(List<Question> Questions, int TokensUsed)> GenerateAndSaveAsync(
        long moduleId, string topic, string difficulty, int count, long requesterId)
    {
        var prompt = BuildPrompt(topic, difficulty, count);
        var rawText = await _gemini.GenerateTextAsync(prompt);
        var parsed = ParseResponse(rawText);

        if (parsed.Count == 0)
            throw new Exception("AI không sinh được câu hỏi. Vui lòng thử lại với chủ đề khác.");

        var questions = new List<Question>();
        foreach (var item in parsed)
        {
            questions.Add(new Question
            {
                ModuleId = moduleId,
                Content = item.Content,
                OptionA = item.OptionA,
                OptionB = item.OptionB,
                OptionC = item.OptionC,
                OptionD = item.OptionD,
                CorrectOption = item.CorrectOption.ToUpper(),
                Difficulty = difficulty.ToUpper(),
                AiExplanation = item.Explanation,
                Source = "AI_GENERATED",
                Status = "DRAFT",
                CreatedBy = requesterId,
                CreatedAt = DateTimeOffset.UtcNow
            });
        }

        _repo.AddRange(questions);
        return (questions, _gemini.EstimateTokens(prompt, rawText));
    }

    public List<Question> GetDraftsByModule(long moduleId)
        => _repo.GetDraftsByModuleId(moduleId);

    public List<Module> GetAllModules()
        => _repo.GetAllModules();

    public bool Approve(long questionId, long approvedByUserId)
        => _repo.Approve(questionId, approvedByUserId);

    public bool Reject(long questionId)
        => _repo.Reject(questionId);

    public bool DeleteDraft(long questionId)
        => _repo.DeleteDraft(questionId);

    public Question? GetById(long id)
        => _repo.GetById(id);

    public void Add(Question question)
        => _repo.Add(question);

    public void AddRange(List<Question> questions)
        => _repo.AddRange(questions);

    public void Update(Question question)
        => _repo.Update(question);

    public void Delete(Question question)
    {
        var q = _repo.GetById(question.Id);
        if (q != null)
        {
            _repo.Delete(q);
        }
    }

    public List<Question> GetQuestions(long? moduleId, string? difficulty, string? status, string? searchTerm)
        => _repo.GetQuestions(moduleId, difficulty, status, searchTerm);

    // ── Helpers ──────────────────────────────

    private static string BuildPrompt(string topic, string difficulty, int count)
    {
        return "Bạn là chuyên gia giáo dục. Hãy sinh " + count + " câu hỏi trắc nghiệm 4 đáp án về: \"" + topic + "\".\n"
             + "Độ khó: " + difficulty + ".\n\n"
             + "Chỉ trả về JSON array thuần, KHÔNG có markdown, KHÔNG có backtick:\n"
             + "[\n"
             + "  {\n"
             + "    \"content\": \"Nội dung câu hỏi?\",\n"
             + "    \"optionA\": \"Đáp án A\",\n"
             + "    \"optionB\": \"Đáp án B\",\n"
             + "    \"optionC\": \"Đáp án C\",\n"
             + "    \"optionD\": \"Đáp án D\",\n"
             + "    \"correctOption\": \"A\",\n"
             + "    \"explanation\": \"Giải thích ngắn gọn.\"\n"
             + "  }\n"
             + "]";
    }

    private static List<GeminiItem> ParseResponse(string raw)
    {
        var text = raw.Trim();
        if (text.StartsWith("```"))
        {
            var start = text.IndexOf('\n') + 1;
            var end = text.LastIndexOf("```");
            if (end > start) text = text[start..end].Trim();
        }
        try
        {
            Console.WriteLine($">>> [QuestionService] Đang parse JSON ({text.Length} kí tự)...");
            var items = JsonSerializer.Deserialize<List<GeminiItem>>(text,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
                ?? new List<GeminiItem>();
            Console.WriteLine($">>> [QuestionService] Parse thành công. Số câu: {items.Count}");
            return items;
        }
        catch (Exception ex)
        {
            Console.WriteLine($">>> [QuestionService] LỖI PARSE JSON: {ex.Message}");
            Console.WriteLine($">>> [QuestionService] Nội dung JSON lỗi: {text}");
            return new List<GeminiItem>();
        }
    }

    private class GeminiItem
    {
        public string Content { get; set; } = "";
        public string OptionA { get; set; } = "";
        public string OptionB { get; set; } = "";
        public string OptionC { get; set; } = "";
        public string OptionD { get; set; } = "";
        public string CorrectOption { get; set; } = "";
        public string Explanation { get; set; } = "";
    }
}
