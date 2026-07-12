using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using EduNexus.Models;
using EduNexus.Repositories;
using EduNexus.ViewModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace EduNexus.Services;

public interface IFlashcardService
{
    FlashcardEditorViewModel GetEditorViewModel(long? deckId, long courseId, long? moduleId);
    long SaveDeck(FlashcardEditorViewModel model, long userId, bool publish);
    void DeleteDeck(long deckId);

    Task<(List<Flashcard> Cards, int TokensUsed)> GenerateDraftCardsAsync(
        long deckId, string topic, int count, string? sourceMaterial, long requesterId);

    List<Flashcard> GetDraftCards(long deckId);
    bool ApproveCard(long cardId);
    bool RejectCard(long cardId);
    int ApproveAllDrafts(long deckId);

    FlashcardLibraryViewModel GetLibraryForStudent(long studentId, long? courseId, string? search, string? category);
    FlashcardPracticeViewModel GetPracticeViewModel(long deckId, long studentId);
    FlashcardPracticeSummaryViewModel RecordReview(long deckId, long flashcardId, long studentId, bool remembered);
}

public class FlashcardService : IFlashcardService
{
    private readonly IFlashcardRepository _repo;
    private readonly GeminiService _gemini;
    private readonly EduNexusContext _context;
    private readonly string _geminiModel;

    public FlashcardService(IFlashcardRepository repo, GeminiService gemini, EduNexusContext context, IConfiguration config)
    {
        _repo = repo;
        _gemini = gemini;
        _context = context;
        _geminiModel = config["Gemini:Model"] ?? "gemini-2.0-flash";
    }

    public FlashcardEditorViewModel GetEditorViewModel(long? deckId, long courseId, long? moduleId)
    {
        var vm = new FlashcardEditorViewModel
        {
            CourseId = courseId,
            ModuleId = moduleId ?? 0
        };

        if (deckId.HasValue && deckId.Value > 0)
        {
            var deck = _repo.GetDeckWithCards(deckId.Value);
            if (deck != null)
            {
                vm.DeckId = deck.Id;
                vm.Name = deck.Name;
                vm.Category = deck.Category ?? "";
                vm.ModuleId = deck.ModuleId ?? 0;
                vm.Status = deck.Status;
                vm.Cards = deck.Flashcards
                    .Where(c => c.Status != DbStatus.Flashcard.Staging)
                    .OrderBy(c => c.Id)
                    .Select(c => new FlashcardItemViewModel
                    {
                        Id = c.Id,
                        FrontText = c.FrontText,
                        BackText = c.BackText
                    }).ToList();
            }
        }

        if (vm.Cards.Count == 0)
            vm.Cards.Add(new FlashcardItemViewModel());

        return vm;
    }

    public long SaveDeck(FlashcardEditorViewModel model, long userId, bool publish)
    {
        var validCards = model.Cards
            .Where(c => !string.IsNullOrWhiteSpace(c.FrontText) && !string.IsNullOrWhiteSpace(c.BackText))
            .ToList();

        FlashcardDeck deck;
        if (model.DeckId > 0)
        {
            deck = _repo.GetDeckWithCards(model.DeckId) ?? throw new InvalidOperationException("Deck không tồn tại.");
            deck.Name = model.Name.Trim();
            deck.Category = string.IsNullOrWhiteSpace(model.Category) ? null : model.Category.Trim();
            deck.ModuleId = model.ModuleId > 0 ? model.ModuleId : null;
            if (publish && validCards.Count >= 5)
                deck.Status = DbStatus.FlashcardDeck.Published;
            else if (!publish)
                deck.Status = DbStatus.FlashcardDeck.Draft;
            _repo.UpdateDeck(deck);
        }
        else
        {
            deck = new FlashcardDeck
            {
                CourseId = model.CourseId,
                ModuleId = model.ModuleId > 0 ? model.ModuleId : null,
                Name = model.Name.Trim(),
                Category = string.IsNullOrWhiteSpace(model.Category) ? null : model.Category.Trim(),
                Status = publish && validCards.Count >= 5 ? DbStatus.FlashcardDeck.Published : DbStatus.FlashcardDeck.Draft,
                CreatedBy = userId,
                CreatedAt = DateTimeOffset.UtcNow
            };
            _repo.AddDeck(deck);
        }

        var entities = validCards.Select(c => new Flashcard
        {
            Id = c.Id,
            DeckId = deck.Id,
            FrontText = c.FrontText.Trim(),
            BackText = c.BackText.Trim(),
            Status = DbStatus.Flashcard.Active,
            CreatedAt = DateTimeOffset.UtcNow
        }).ToList();

        _repo.ReplaceCards(deck.Id, entities);
        return deck.Id;
    }

    public void DeleteDeck(long deckId) => _repo.DeleteDeck(deckId);

    public async Task<(List<Flashcard> Cards, int TokensUsed)> GenerateDraftCardsAsync(
        long deckId, string topic, int count, string? sourceMaterial, long requesterId)
    {
        var deck = _repo.GetDeckWithCards(deckId);
        if (deck == null) throw new InvalidOperationException("Deck không tồn tại.");

        await EnsureAiQuotaAsync(requesterId);

        var aiRequest = new AiRequest
        {
            RequesterId = requesterId,
            TaskType = DbStatus.AiRequest.GenFlashcard,
            SourceRefType = "FLASHCARD_DECK",
            SourceRefId = deckId,
            Status = DbStatus.AiRequest.Pending,
            CreatedAt = DateTimeOffset.UtcNow
        };
        _context.AiRequests.Add(aiRequest);
        await _context.SaveChangesAsync();

        var sw = Stopwatch.StartNew();
        try
        {
            var prompt = BuildFlashcardPrompt(topic, count, sourceMaterial);
            var rawText = await _gemini.GenerateTextAsync(prompt);
            var parsed = ParseFlashcardResponse(rawText);

            if (parsed.Count == 0)
                throw new Exception("AI không sinh được flashcard. Vui lòng thử lại.");

            var tokens = _gemini.EstimateTokens(prompt, rawText);
            var cards = parsed.Select(item => new Flashcard
            {
                DeckId = deckId,
                FrontText = item.FrontText,
                BackText = item.BackText,
                Status = DbStatus.Flashcard.Staging,
                CreatedAt = DateTimeOffset.UtcNow
            }).ToList();

            _repo.AddCards(cards);

            aiRequest.Status = DbStatus.AiRequest.Success;
            _context.AiResponses.Add(new AiResponse
            {
                AiRequestId = aiRequest.Id,
                Model = _geminiModel,
                GeneratedContent = JsonSerializer.Serialize(parsed),
                TokenConsumed = tokens,
                ProcessingTimeMs = (int)sw.ElapsedMilliseconds,
                CreatedAt = DateTimeOffset.UtcNow
            });
            await IncrementAiQuotaAsync(requesterId);
            await _context.SaveChangesAsync();

            return (cards, tokens);
        }
        catch (TimeoutException)
        {
            aiRequest.Status = DbStatus.AiRequest.Timeout;
            await _context.SaveChangesAsync();
            throw;
        }
        catch (Exception)
        {
            aiRequest.Status = DbStatus.AiRequest.Failed;
            await _context.SaveChangesAsync();
            throw;
        }
    }

    public List<Flashcard> GetDraftCards(long deckId) => _repo.GetDraftCards(deckId);

    public bool ApproveCard(long cardId)
    {
        var card = _repo.GetCardById(cardId);
        if (card == null || card.Status != DbStatus.Flashcard.Staging) return false;
        card.Status = DbStatus.Flashcard.Active;
        _repo.UpdateCard(card);
        return true;
    }

    public bool RejectCard(long cardId)
    {
        _repo.DeleteCard(cardId);
        return true;
    }

    public int ApproveAllDrafts(long deckId)
    {
        var drafts = _repo.GetDraftCards(deckId);
        foreach (var card in drafts)
        {
            card.Status = DbStatus.Flashcard.Active;
            _repo.UpdateCard(card);
        }
        return drafts.Count;
    }

    public FlashcardLibraryViewModel GetLibraryForStudent(long studentId, long? courseId, string? search, string? category)
    {
        var decks = _repo.GetPublishedDecks(courseId, search, category);
        var vm = new FlashcardLibraryViewModel { Search = search, Category = category, CourseId = courseId };

        foreach (var deck in decks)
        {
            var activeCards = deck.Flashcards.Where(c => c.Status == DbStatus.Flashcard.Active).ToList();
            if (activeCards.Count == 0) continue;

            var cardIds = activeCards.Select(c => c.Id);
            var logs = _repo.GetReviewLogs(studentId, cardIds);
            var mastered = logs.Count(l => l.MemoryState == "MASTERED");
            var due = activeCards.Count - mastered;

            vm.Decks.Add(new FlashcardDeckSummaryViewModel
            {
                DeckId = deck.Id,
                Name = deck.Name,
                Category = deck.Category ?? "General",
                CourseName = deck.Course?.Title ?? "",
                TotalCards = activeCards.Count,
                MasteredCards = mastered,
                DueCards = due,
                MasteryPercent = activeCards.Count > 0 ? (int)Math.Round(100.0 * mastered / activeCards.Count) : 0
            });
        }

        return vm;
    }

    public FlashcardPracticeViewModel GetPracticeViewModel(long deckId, long studentId)
    {
        var deck = _repo.GetDeckWithCards(deckId);
        if (deck == null || deck.Status != DbStatus.FlashcardDeck.Published)
            throw new InvalidOperationException("Bộ flashcard không khả dụng.");

        var cards = deck.Flashcards.Where(c => c.Status == DbStatus.Flashcard.Active).ToList();
        var cardIds = cards.Select(c => c.Id).ToList();
        var logs = _repo.GetReviewLogs(studentId, cardIds);
        var logByCard = logs.GroupBy(l => l.FlashcardId)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(x => x.ReviewedAt).First());

        var ordered = cards
            .OrderBy(c =>
            {
                if (!logByCard.TryGetValue(c.Id, out var log)) return 0;
                return log.MemoryState switch { "FORGOT" => 0, "REMEMBERED" => 1, "MASTERED" => 2, _ => 1 };
            })
            .ThenBy(c => c.Id)
            .Select(c => new FlashcardPracticeCardViewModel
            {
                FlashcardId = c.Id,
                FrontText = c.FrontText,
                BackText = c.BackText,
                MemoryState = logByCard.TryGetValue(c.Id, out var log) ? log.MemoryState : "NEW"
            }).ToList();

        return new FlashcardPracticeViewModel
        {
            DeckId = deck.Id,
            DeckName = deck.Name,
            Cards = ordered,
            TotalCards = ordered.Count,
            MasteredCards = ordered.Count(c => c.MemoryState == "MASTERED")
        };
    }

    public FlashcardPracticeSummaryViewModel RecordReview(long deckId, long flashcardId, long studentId, bool remembered)
    {
        var latest = _repo.GetLatestReviewLog(studentId, flashcardId);
        var newState = ComputeNextState(latest?.MemoryState, remembered);

        _repo.AddReviewLog(new FlashcardReviewLog
        {
            FlashcardId = flashcardId,
            StudentId = studentId,
            MemoryState = newState,
            ReviewedAt = DateTimeOffset.UtcNow,
            NextReviewAt = newState == DbStatus.MemoryState.Mastered
                ? DateTimeOffset.UtcNow.AddDays(7)
                : DateTimeOffset.UtcNow.AddHours(remembered ? 24 : 1)
        });

        UpsertFlashcardProgress(studentId, deckId);

        var practice = GetPracticeViewModel(deckId, studentId);
        return new FlashcardPracticeSummaryViewModel
        {
            DeckId = deckId,
            MemoryState = newState,
            RemainingCards = practice.Cards.Count(c => c.MemoryState != "MASTERED"),
            MasteredCards = practice.MasteredCards,
            TotalCards = practice.TotalCards,
            IsComplete = practice.Cards.All(c => c.MemoryState == "MASTERED")
        };
    }

    private async Task EnsureAiQuotaAsync(long userId)
    {
        var monthYear = DateTimeOffset.UtcNow.ToString("yyyy-MM");
        var quota = await _context.AiQuota
            .FirstOrDefaultAsync(q => q.UserId == userId && q.MonthYear == monthYear);

        if (quota != null && quota.UsedCount >= quota.QuotaLimit)
            throw new InvalidOperationException("Bạn đã đạt hạn mức AI quota tháng này (GB-02).");
    }

    private async Task IncrementAiQuotaAsync(long userId)
    {
        var monthYear = DateTimeOffset.UtcNow.ToString("yyyy-MM");
        var quota = await _context.AiQuota
            .FirstOrDefaultAsync(q => q.UserId == userId && q.MonthYear == monthYear);

        if (quota == null)
        {
            _context.AiQuota.Add(new AiQuotum
            {
                UserId = userId,
                MonthYear = monthYear,
                QuotaLimit = 100,
                UsedCount = 1
            });
        }
        else
        {
            quota.UsedCount += 1;
        }
    }

    private void UpsertFlashcardProgress(long studentId, long deckId)
    {
        var deck = _repo.GetDeckWithCards(deckId);
        if (deck == null) return;

        var progress = _context.LearningProgresses
            .FirstOrDefault(p => p.StudentId == studentId
                && p.ActivityType == DbStatus.LearningProgress.Flashcard
                && p.LessonId == null
                && p.ClassId == null);

        var activeCount = deck.Flashcards.Count(c => c.Status == DbStatus.Flashcard.Active);
        var mastered = _repo.GetReviewLogs(studentId, deck.Flashcards.Select(c => c.Id))
            .Count(l => l.MemoryState == "MASTERED");

        if (progress == null)
        {
            _context.LearningProgresses.Add(new LearningProgress
            {
                StudentId = studentId,
                ActivityType = DbStatus.LearningProgress.Flashcard,
                CompletionStatus = mastered >= activeCount && activeCount > 0
                    ? DbStatus.LearningProgress.Completed
                    : DbStatus.LearningProgress.InProgress,
                TimeSpentSeconds = 60,
                AttemptCount = 1,
                LastActiveAt = DateTimeOffset.UtcNow
            });
        }
        else
        {
            progress.CompletionStatus = mastered >= activeCount && activeCount > 0
                ? DbStatus.LearningProgress.Completed
                : DbStatus.LearningProgress.InProgress;
            progress.AttemptCount += 1;
            progress.TimeSpentSeconds += 60;
            progress.LastActiveAt = DateTimeOffset.UtcNow;
        }

        _context.SaveChanges();
    }

    private static string ComputeNextState(string? current, bool remembered)
    {
        if (!remembered) return DbStatus.MemoryState.Forgot;
        return current switch
        {
            null or "NEW" or _ when current == DbStatus.MemoryState.Forgot => DbStatus.MemoryState.Remembered,
            _ when current == DbStatus.MemoryState.Remembered => DbStatus.MemoryState.Mastered,
            _ => DbStatus.MemoryState.Mastered
        };
    }

    private static string BuildFlashcardPrompt(string topic, int count, string? sourceMaterial)
    {
        var src = string.IsNullOrWhiteSpace(sourceMaterial)
            ? ""
            : $"\nTài liệu tham khảo:\n{sourceMaterial}\n";

        return $@"Bạn là chuyên gia giáo dục. Hãy sinh {count} cặp thuật ngữ-định nghĩa flashcard về chủ đề: ""{topic}"".{src}
Chỉ trả về JSON array thuần, KHÔNG markdown:
[
  {{ ""frontText"": ""Thuật ngữ"", ""backText"": ""Định nghĩa ngắn gọn"" }}
]";
    }

    private static List<FlashcardAiItem> ParseFlashcardResponse(string raw)
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
            return JsonSerializer.Deserialize<List<FlashcardAiItem>>(text,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new List<FlashcardAiItem>();
        }
        catch
        {
            return new List<FlashcardAiItem>();
        }
    }

    private class FlashcardAiItem
    {
        public string FrontText { get; set; } = "";
        public string BackText { get; set; } = "";
    }
}
