using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using EduNexus.Models;
using EduNexus.Services;
using EduNexus.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Controllers;

public class FlashcardController : Controller
{
    private readonly IFlashcardService _flashcardService;
    private readonly EduNexusContext _context;

    public FlashcardController(IFlashcardService flashcardService, EduNexusContext context)
    {
        _flashcardService = flashcardService;
        _context = context;
    }

    private long GetCurrentUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (claim != null) return long.Parse(claim.Value);
        return _context.Users.FirstOrDefault()?.Id ?? 1;
    }

    private void ResolveSmeCourseContext(long courseId)
    {
        var course = _context.Courses.Find(courseId);
        if (course == null) return;
        ViewBag.ActiveCourseId = course.Id;
        ViewBag.ActiveCourseTitle = course.Title;
        ViewData["ActiveMenu"] = "MyCourses";
        ViewData["ActiveSubMenu"] = "Flashcards";
    }

    // SME: danh sách deck theo course
    [HttpGet]
    public IActionResult Index(long courseId, long? moduleId, string? search)
    {
        ResolveSmeCourseContext(courseId);
        var allDecks = _context.FlashcardDecks
            .Include(d => d.Module)
            .Include(d => d.Flashcards)
            .Where(d => d.CourseId == courseId);

        if (moduleId.HasValue && moduleId > 0)
            allDecks = allDecks.Where(d => d.ModuleId == moduleId);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            allDecks = allDecks.Where(d => d.Name.ToLower().Contains(term));
        }

        var vm = new SmeFlashcardListViewModel
        {
            CourseId = courseId,
            CourseTitle = _context.Courses.Find(courseId)?.Title ?? "",
            ModuleId = moduleId,
            Search = search,
            Modules = _context.Modules.Where(m => m.CourseId == courseId)
                .OrderBy(m => m.OrderNo)
                .Select(m => new ModuleOptionViewModel { Id = m.Id, Name = m.Title })
                .ToList(),
            Decks = allDecks.OrderByDescending(d => d.CreatedAt)
                .ToList()
                .Select(d => new FlashcardDeckListItemViewModel
                {
                    Id = d.Id,
                    Name = d.Name,
                    Category = d.Category,
                    Status = d.Status,
                    CardCount = d.Flashcards.Count(c => c.Status == DbStatus.Flashcard.Active),
                    ModuleName = d.Module?.Title
                }).ToList()
        };

        return View(vm);
    }

    // SME: Flashcard Editor
    [HttpGet]
    public IActionResult Editor(long courseId, long? deckId, long? moduleId)
    {
        ResolveSmeCourseContext(courseId);
        var vm = _flashcardService.GetEditorViewModel(deckId, courseId, moduleId);
        vm.Modules = _context.Modules.Where(m => m.CourseId == courseId)
            .OrderBy(m => m.OrderNo)
            .Select(m => new ModuleOptionViewModel { Id = m.Id, Name = m.Title })
            .ToList();
        ViewData["Title"] = deckId.HasValue ? "Chỉnh sửa Flashcard" : "Tạo Flashcard";
        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Editor(FlashcardEditorViewModel model, string action)
    {
        ResolveSmeCourseContext(model.CourseId);
        model.Modules = _context.Modules.Where(m => m.CourseId == model.CourseId)
            .OrderBy(m => m.OrderNo)
            .Select(m => new ModuleOptionViewModel { Id = m.Id, Name = m.Title })
            .ToList();

        if (!ModelState.IsValid)
            return View(model);

        var publish = action == "publish";
        var validCount = model.Cards.Count(c =>
            !string.IsNullOrWhiteSpace(c.FrontText) && !string.IsNullOrWhiteSpace(c.BackText));

        if (publish && validCount < 5)
        {
            ModelState.AddModelError("", "Cần ít nhất 5 thẻ hợp lệ để publish.");
            return View(model);
        }

        var deckId = _flashcardService.SaveDeck(model, GetCurrentUserId(), publish);
        TempData["SuccessMessage"] = publish ? "Đã publish bộ flashcard." : "Đã lưu bản nháp.";
        return RedirectToAction(nameof(Editor), new { courseId = model.CourseId, deckId, moduleId = model.ModuleId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult DeleteDeck(long deckId, long courseId)
    {
        _flashcardService.DeleteDeck(deckId);
        TempData["SuccessMessage"] = "Đã xóa bộ flashcard.";
        return RedirectToAction(nameof(Index), new { courseId });
    }

    // SME: AI Flashcard Staging
    [HttpGet]
    public IActionResult Staging(long deckId)
    {
        var deck = _context.FlashcardDecks.Include(d => d.Course).FirstOrDefault(d => d.Id == deckId);
        if (deck == null) return NotFound();

        ResolveSmeCourseContext(deck.CourseId);
        return View(BuildStagingViewModel(deckId));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Generate([Bind(Prefix = "Form")] GenerateFlashcardsRequest form)
    {
        if (form.DeckId <= 0)
        {
            if (long.TryParse(Request.Form["Form.DeckId"], out var deckId)) form.DeckId = deckId;
            else if (long.TryParse(Request.Form["DeckId"], out deckId)) form.DeckId = deckId;
        }

        if (!ModelState.IsValid)
        {
            return View("Staging", BuildStagingViewModel(form.DeckId, form,
                string.Join(" ", ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage))));
        }

        try
        {
            var (_, tokens) = await _flashcardService.GenerateDraftCardsAsync(
                form.DeckId, form.Topic, form.CardCount, form.SourceMaterial, GetCurrentUserId());
            TempData["SuccessMessage"] = $"AI đã sinh flashcard (ước tính {tokens} tokens).";
        }
        catch (System.Exception ex)
        {
            return View("Staging", BuildStagingViewModel(form.DeckId, form, ex.Message));
        }

        return RedirectToAction(nameof(Staging), new { deckId = form.DeckId });
    }

    private FlashcardStagingViewModel BuildStagingViewModel(long deckId, GenerateFlashcardsRequest? form = null, string? errorMessage = null)
    {
        var deck = _context.FlashcardDecks.Include(d => d.Course).FirstOrDefault(d => d.Id == deckId);
        if (deck != null) ResolveSmeCourseContext(deck.CourseId);

        return new FlashcardStagingViewModel
        {
            DeckId = deckId,
            DeckName = deck?.Name ?? "",
            CourseId = deck?.CourseId ?? 0,
            ModuleId = deck?.ModuleId ?? 0,
            Form = form ?? new GenerateFlashcardsRequest { DeckId = deckId, CardCount = 10 },
            StagedCards = _flashcardService.GetDraftCards(deckId)
                .Select(c => new FlashcardItemViewModel { Id = c.Id, FrontText = c.FrontText, BackText = c.BackText })
                .ToList(),
            SuccessMessage = TempData["SuccessMessage"]?.ToString(),
            ErrorMessage = errorMessage ?? TempData["ErrorMessage"]?.ToString()
        };
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ApproveCard(long cardId, long deckId)
    {
        _flashcardService.ApproveCard(cardId);
        TempData["SuccessMessage"] = "Đã duyệt thẻ.";
        return RedirectToAction(nameof(Staging), new { deckId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult RejectCard(long cardId, long deckId)
    {
        _flashcardService.RejectCard(cardId);
        TempData["SuccessMessage"] = "Đã từ chối thẻ.";
        return RedirectToAction(nameof(Staging), new { deckId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ApproveAll(long deckId)
    {
        var count = _flashcardService.ApproveAllDrafts(deckId);
        TempData["SuccessMessage"] = $"Đã duyệt {count} thẻ.";
        return RedirectToAction(nameof(Staging), new { deckId });
    }

    // Student: Flashcard Library
    [HttpGet]
    public IActionResult Library(long? courseId, string? search, string? category)
    {
        var studentId = GetCurrentUserId();
        var vm = _flashcardService.GetLibraryForStudent(studentId, courseId, search, category);
        return View(vm);
    }

    // Student: Flashcard Practice
    [HttpGet]
    public IActionResult Practice(long deckId)
    {
        try
        {
            var vm = _flashcardService.GetPracticeViewModel(deckId, GetCurrentUserId());
            return View(vm);
        }
        catch (System.Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
            return RedirectToAction(nameof(Library));
        }
    }

    [HttpPost]
    public IActionResult RecordReview([FromBody] RecordReviewRequest request)
    {
        try
        {
            var summary = _flashcardService.RecordReview(
                request.DeckId, request.FlashcardId, GetCurrentUserId(), request.Remembered);
            return Ok(summary);
        }
        catch (System.Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    public class RecordReviewRequest
    {
        public long DeckId { get; set; }
        public long FlashcardId { get; set; }
        public bool Remembered { get; set; }
    }
}
