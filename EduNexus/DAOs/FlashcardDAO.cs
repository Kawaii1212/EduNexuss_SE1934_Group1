using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using EduNexus.Models;

namespace EduNexus.DAOs;

public class FlashcardDAO : BaseDAO<FlashcardDeck>
{
    private static FlashcardDAO? _instance;
    private static readonly object InstanceLock = new();

    private FlashcardDAO() { }

    public static new FlashcardDAO Instance
    {
        get
        {
            lock (InstanceLock)
            {
                return _instance ??= new FlashcardDAO();
            }
        }
    }

    public List<FlashcardDeck> GetDecksByCourse(long courseId, long? moduleId = null, string? search = null)
    {
        using var context = GetContext();
        var query = context.FlashcardDecks
            .Include(d => d.Flashcards)
            .Include(d => d.Module)
            .Where(d => d.CourseId == courseId);

        if (moduleId.HasValue && moduleId.Value > 0)
            query = query.Where(d => d.ModuleId == moduleId);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(d =>
                d.Name.ToLower().Contains(term) ||
                (d.Category != null && d.Category.ToLower().Contains(term)));
        }

        return query.OrderByDescending(d => d.CreatedAt).ToList();
    }

    public FlashcardDeck? GetDeckWithCards(long deckId)
    {
        using var context = GetContext();
        return context.FlashcardDecks
            .Include(d => d.Flashcards)
            .Include(d => d.Course)
            .Include(d => d.Module)
            .FirstOrDefault(d => d.Id == deckId);
    }

    public List<FlashcardDeck> GetPublishedDecks(long? courseId, string? search = null, string? category = null)
    {
        using var context = GetContext();
        var query = context.FlashcardDecks
            .Include(d => d.Flashcards)
            .Include(d => d.Course)
            .Include(d => d.Module)
            .Where(d => d.Status == DbStatus.FlashcardDeck.Published);

        if (courseId.HasValue && courseId.Value > 0)
            query = query.Where(d => d.CourseId == courseId);

        if (!string.IsNullOrWhiteSpace(category) && category != "all")
            query = query.Where(d => d.Category == category);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(d => d.Name.ToLower().Contains(term));
        }

        return query.OrderBy(d => d.Name).ToList();
    }

    public void AddDeck(FlashcardDeck deck)
    {
        using var context = GetContext();
        context.FlashcardDecks.Add(deck);
        context.SaveChanges();
    }

    public void UpdateDeck(FlashcardDeck deck)
    {
        using var context = GetContext();
        context.FlashcardDecks.Update(deck);
        context.SaveChanges();
    }

    public void DeleteDeck(long deckId)
    {
        using var context = GetContext();
        var deck = context.FlashcardDecks
            .Include(d => d.Flashcards)
            .FirstOrDefault(d => d.Id == deckId);
        if (deck == null) return;

        var cardIds = deck.Flashcards.Select(f => f.Id).ToList();
        var logs = context.FlashcardReviewLogs.Where(l => cardIds.Contains(l.FlashcardId)).ToList();
        context.FlashcardReviewLogs.RemoveRange(logs);
        context.Flashcards.RemoveRange(deck.Flashcards);
        context.FlashcardDecks.Remove(deck);
        context.SaveChanges();
    }

    public void ReplaceCards(long deckId, List<Flashcard> cards)
    {
        using var context = GetContext();
        var keepIds = cards.Where(c => c.Id > 0).Select(c => c.Id).ToHashSet();
        var toRemove = context.Flashcards
            .Where(f => f.DeckId == deckId && f.Status != DbStatus.Flashcard.Staging && !keepIds.Contains(f.Id))
            .ToList();
        context.Flashcards.RemoveRange(toRemove);

        foreach (var card in cards)
        {
            if (card.Id > 0)
            {
                var existing = context.Flashcards.Find(card.Id);
                if (existing != null)
                {
                    existing.FrontText = card.FrontText;
                    existing.BackText = card.BackText;
                }
            }
            else
            {
                card.DeckId = deckId;
                card.Status = DbStatus.Flashcard.Active;
                card.CreatedAt = DateTimeOffset.UtcNow;
                context.Flashcards.Add(card);
            }
        }

        context.SaveChanges();
    }

    public void AddCards(List<Flashcard> cards)
    {
        using var context = GetContext();
        context.Flashcards.AddRange(cards);
        context.SaveChanges();
    }

    public void UpdateCard(Flashcard card)
    {
        using var context = GetContext();
        context.Flashcards.Update(card);
        context.SaveChanges();
    }

    public void DeleteCard(long cardId)
    {
        using var context = GetContext();
        var card = context.Flashcards.Find(cardId);
        if (card == null) return;
        var logs = context.FlashcardReviewLogs.Where(l => l.FlashcardId == cardId).ToList();
        context.FlashcardReviewLogs.RemoveRange(logs);
        context.Flashcards.Remove(card);
        context.SaveChanges();
    }

    public List<Flashcard> GetDraftCards(long deckId)
    {
        using var context = GetContext();
        return context.Flashcards
            .Where(f => f.DeckId == deckId && f.Status == DbStatus.Flashcard.Staging)
            .OrderBy(f => f.Id)
            .ToList();
    }

    public Flashcard? GetCardById(long cardId)
    {
        using var context = GetContext();
        return context.Flashcards.Find(cardId);
    }

    public List<FlashcardReviewLog> GetReviewLogs(long studentId, IEnumerable<long> flashcardIds)
    {
        using var context = GetContext();
        var ids = flashcardIds.ToList();
        if (ids.Count == 0) return new List<FlashcardReviewLog>();

        return context.FlashcardReviewLogs
            .Where(l => l.StudentId == studentId && ids.Contains(l.FlashcardId))
            .ToList();
    }

    public FlashcardReviewLog? GetLatestReviewLog(long studentId, long flashcardId)
    {
        using var context = GetContext();
        return context.FlashcardReviewLogs
            .Where(l => l.StudentId == studentId && l.FlashcardId == flashcardId)
            .OrderByDescending(l => l.ReviewedAt)
            .FirstOrDefault();
    }

    public void AddReviewLog(FlashcardReviewLog log)
    {
        using var context = GetContext();
        context.FlashcardReviewLogs.Add(log);
        context.SaveChanges();
    }
}
