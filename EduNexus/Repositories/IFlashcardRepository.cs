using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Repositories;

public interface IFlashcardRepository
{
    List<FlashcardDeck> GetDecksByCourse(long courseId, long? moduleId = null, string? search = null);
    FlashcardDeck? GetDeckWithCards(long deckId);
    List<FlashcardDeck> GetPublishedDecks(long? courseId, string? search = null, string? category = null);
    void AddDeck(FlashcardDeck deck);
    void UpdateDeck(FlashcardDeck deck);
    void DeleteDeck(long deckId);
    void ReplaceCards(long deckId, List<Flashcard> cards);
    void AddCards(List<Flashcard> cards);
    void UpdateCard(Flashcard card);
    void DeleteCard(long cardId);
    List<Flashcard> GetDraftCards(long deckId);
    Flashcard? GetCardById(long cardId);
    List<FlashcardReviewLog> GetReviewLogs(long studentId, IEnumerable<long> flashcardIds);
    FlashcardReviewLog? GetLatestReviewLog(long studentId, long flashcardId);
    void AddReviewLog(FlashcardReviewLog log);
}
