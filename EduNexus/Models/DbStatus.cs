namespace EduNexus.Models;

/// <summary>
/// Enum values per DataBase_Guide_v3.md (section 4).
/// </summary>
public static class DbStatus
{
    public static class Question
    {
        public const string Draft = "DRAFT";
        public const string Approved = "APPROVED";
        public const string Rejected = "REJECTED";
    }

    public static class Quiz
    {
        public const string Draft = "DRAFT";
        public const string Published = "PUBLISHED";
    }

    public static class FlashcardDeck
    {
        public const string Draft = "DRAFT";
        public const string Published = "PUBLISHED";
    }

    public static class Flashcard
    {
        public const string Active = "ACTIVE";
        /// <summary>App-level staging status (no DB CHECK constraint on flashcard.status).</summary>
        public const string Staging = "DRAFT";
    }

    public static class QuizAttempt
    {
        public const string InProgress = "IN_PROGRESS";
        public const string Submitted = "SUBMITTED";
    }

    public static class MemoryState
    {
        public const string Forgot = "FORGOT";
        public const string Remembered = "REMEMBERED";
        public const string Mastered = "MASTERED";
    }

    public static class AiRequest
    {
        public const string Pending = "PENDING";
        public const string Success = "SUCCESS";
        public const string Failed = "FAILED";
        public const string Timeout = "TIMEOUT";
        public const string GenFlashcard = "GEN_FLASHCARD";
    }

    public static class LearningProgress
    {
        public const string Flashcard = "FLASHCARD";
        public const string Quiz = "QUIZ";
        public const string NotStarted = "NOT_STARTED";
        public const string InProgress = "IN_PROGRESS";
        public const string Completed = "COMPLETED";
    }
}
