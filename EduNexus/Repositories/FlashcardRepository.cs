using System.Collections.Generic;
using EduNexus.DAOs;
using EduNexus.Models;

namespace EduNexus.Repositories;

public class FlashcardRepository : IFlashcardRepository
{
    public List<FlashcardDeck> GetDecksByCourse(long courseId, long? moduleId = null, string? search = null)
        => FlashcardDAO.Instance.GetDecksByCourse(courseId, moduleId, search);

    public FlashcardDeck? GetDeckWithCards(long deckId)
        => FlashcardDAO.Instance.GetDeckWithCards(deckId);

    public List<FlashcardDeck> GetPublishedDecks(IReadOnlyCollection<long> allowedCourseIds, long? courseId, string? search = null, string? category = null)
        => FlashcardDAO.Instance.GetPublishedDecks(allowedCourseIds, courseId, search, category);

    public void AddDeck(FlashcardDeck deck) => FlashcardDAO.Instance.AddDeck(deck);
    public void UpdateDeck(FlashcardDeck deck) => FlashcardDAO.Instance.UpdateDeck(deck);
    public void DeleteDeck(long deckId) => FlashcardDAO.Instance.DeleteDeck(deckId);
    public void ReplaceCards(long deckId, List<Flashcard> cards) => FlashcardDAO.Instance.ReplaceCards(deckId, cards);
    public void AddCards(List<Flashcard> cards) => FlashcardDAO.Instance.AddCards(cards);
    public void UpdateCard(Flashcard card) => FlashcardDAO.Instance.UpdateCard(card);
    public void DeleteCard(long cardId) => FlashcardDAO.Instance.DeleteCard(cardId);
    public List<Flashcard> GetDraftCards(long deckId) => FlashcardDAO.Instance.GetDraftCards(deckId);
    public Flashcard? GetCardById(long cardId) => FlashcardDAO.Instance.GetCardById(cardId);
    public List<FlashcardReviewLog> GetReviewLogs(long studentId, IEnumerable<long> flashcardIds)
        => FlashcardDAO.Instance.GetReviewLogs(studentId, flashcardIds);
    public FlashcardReviewLog? GetLatestReviewLog(long studentId, long flashcardId)
        => FlashcardDAO.Instance.GetLatestReviewLog(studentId, flashcardId);
    public void AddReviewLog(FlashcardReviewLog log) => FlashcardDAO.Instance.AddReviewLog(log);
}
