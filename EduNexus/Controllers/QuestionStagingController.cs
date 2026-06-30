using System;
using System.Threading.Tasks;
using DataAccessLayer.Services;
using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;

namespace EduNexus.Controllers;

public class QuestionStagingController : Controller
{
    private readonly IQuestionService _questionService;

    public QuestionStagingController(IQuestionService questionService)
    {
        _questionService = questionService;
    }

    // GET /QuestionStaging/Index?moduleId=1
    public IActionResult Index(long? moduleId)
    {
        var modules = _questionService.GetAllModules();

        var vm = new QuestionStagingViewModel
        {
            Modules = modules,
            Form = new GenerateQuestionsRequest
            {
                ModuleId = moduleId ?? (modules.Count > 0 ? modules[0].Id : 0)
            }
        };

        if (moduleId.HasValue)
            vm.StagedQuestions = _questionService.GetDraftsByModule(moduleId.Value);

        vm.SuccessMessage = TempData["SuccessMessage"]?.ToString();
        vm.ErrorMessage = TempData["ErrorMessage"]?.ToString();
        if (int.TryParse(TempData["LastTokensUsed"]?.ToString(), out int t))
            vm.LastTokensUsed = t;

        return View(vm);
    }

    // POST /QuestionStaging/Generate
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Generate(GenerateQuestionsRequest form)
    {
        if (!ModelState.IsValid)
        {
            TempData["ErrorMessage"] = "Vui lòng điền đầy đủ thông tin.";
            return RedirectToAction(nameof(Index), new { moduleId = form.ModuleId });
        }

        // TODO: thay bằng Session["UserId"] sau khi Auth xong
        long requesterId = 1;

        try
        {
            var (questions, tokens) = await _questionService.GenerateAndSaveAsync(
                form.ModuleId, form.Topic, form.Difficulty, form.Count, requesterId);

            TempData["SuccessMessage"] = $"✅ Sinh thành công {questions.Count} câu hỏi. Vui lòng duyệt từng câu bên dưới.";
            TempData["LastTokensUsed"] = tokens.ToString();
        }
        catch (TimeoutException ex)
        {
            TempData["ErrorMessage"] = $"⏱ {ex.Message}";
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"❌ {ex.Message}";
        }

        return RedirectToAction(nameof(Index), new { moduleId = form.ModuleId });
    }

    // POST /QuestionStaging/Approve/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Approve(long id, long moduleId)
    {
        bool ok = _questionService.Approve(id, 1); // TODO: lấy userId từ Session
        TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok
            ? "✅ Câu hỏi đã được duyệt vào ngân hàng câu hỏi."
            : "❌ Không tìm thấy câu hỏi.";
        return RedirectToAction(nameof(Index), new { moduleId });
    }

    // POST /QuestionStaging/Reject/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Reject(long id, long moduleId)
    {
        bool ok = _questionService.Reject(id);
        TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok
            ? "🚫 Câu hỏi đã bị từ chối."
            : "❌ Không tìm thấy câu hỏi.";
        return RedirectToAction(nameof(Index), new { moduleId });
    }

    // POST /QuestionStaging/DeleteDraft/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult DeleteDraft(long id, long moduleId)
    {
        bool ok = _questionService.DeleteDraft(id);
        TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok
            ? "🗑 Đã xoá câu hỏi khỏi staging."
            : "❌ Không thể xoá (không tồn tại hoặc không còn ở DRAFT).";
        return RedirectToAction(nameof(Index), new { moduleId });
    }

    // POST /QuestionStaging/ApproveAll
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult ApproveAll(long moduleId)
    {
        var drafts = _questionService.GetDraftsByModule(moduleId);
        int count = 0;
        foreach (var q in drafts)
            if (_questionService.Approve(q.Id, 1)) count++; // TODO: userId từ Session
        TempData["SuccessMessage"] = $"✅ Đã duyệt tất cả {count} câu hỏi.";
        return RedirectToAction(nameof(Index), new { moduleId });
    }
}
