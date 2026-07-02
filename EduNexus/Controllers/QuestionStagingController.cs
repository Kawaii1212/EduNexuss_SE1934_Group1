using EduNexus.ViewModels;
using System;
using System.Threading.Tasks;
using System.Linq;
using EduNexus.Services;
using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

namespace EduNexus.Controllers;

public class QuestionStagingController : Controller
{
    private readonly IQuestionService _questionService;
    private readonly EduNexusContext _context;

    public QuestionStagingController(IQuestionService questionService, EduNexusContext context)
    {
        _questionService = questionService;
        _context = context;
    }

    private void ResolveCourseContext(long? courseId, long? moduleId)
    {
        Course? course = null;
        if (moduleId.HasValue && moduleId.Value > 0)
        {
            var module = _context.Modules
                .Include(m => m.Course)
                .FirstOrDefault(m => m.Id == moduleId.Value);
            if (module != null)
            {
                course = module.Course;
            }
        }
        else if (courseId.HasValue && courseId.Value > 0)
        {
            course = _context.Courses.Find(courseId.Value);
        }

        if (course != null)
        {
            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = "Question";
        }
    }

    // GET /QuestionStaging/Index?moduleId=1
    public IActionResult Index(long? moduleId)
    {
        var allModules = _questionService.GetAllModules();

        // Enforce default module if null
        if (!moduleId.HasValue && allModules.Count > 0)
        {
            moduleId = allModules[0].Id;
        }

        long? courseId = null;
        if (moduleId.HasValue && moduleId.Value > 0)
        {
            var module = _context.Modules.Find(moduleId.Value);
            if (module != null)
            {
                courseId = module.CourseId;
            }
        }

        ResolveCourseContext(courseId, moduleId);

        List<Module> modules;
        if (courseId.HasValue && courseId.Value > 0)
        {
            modules = _context.Modules
                .Where(m => m.CourseId == courseId.Value)
                .OrderBy(m => m.OrderNo)
                .ToList();
        }
        else
        {
            modules = allModules;
        }

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
        ModelState.Remove("form.Module"); // Remove EF navigation property validation

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

            TempData["SuccessMessage"] = $"Sinh thành công {questions.Count} câu hỏi. Vui lòng duyệt từng câu bên dưới.";
            TempData["LastTokensUsed"] = tokens.ToString();
        }
        catch (TimeoutException ex)
        {
            TempData["ErrorMessage"] = $"{ex.Message}";
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"{ex.Message}";
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
            ? "Câu hỏi đã được duyệt vào ngân hàng câu hỏi."
            : "Không tìm thấy câu hỏi.";
        return RedirectToAction(nameof(Index), new { moduleId });
    }

    // POST /QuestionStaging/Reject/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Reject(long id, long moduleId)
    {
        bool ok = _questionService.Reject(id);
        TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok
            ? "Câu hỏi đã bị từ chối."
            : "Không tìm thấy câu hỏi.";
        return RedirectToAction(nameof(Index), new { moduleId });
    }

    // POST /QuestionStaging/DeleteDraft/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult DeleteDraft(long id, long moduleId)
    {
        bool ok = _questionService.DeleteDraft(id);
        TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok
            ? "Đã xóa câu hỏi khỏi staging."
            : "Không thể xóa (không tồn tại hoặc không còn ở DRAFT).";
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
        TempData["SuccessMessage"] = $"Đã duyệt tất cả {count} câu hỏi.";
        return RedirectToAction(nameof(Index), new { moduleId });
    }

    // POST: /QuestionStaging/EditDraft
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult EditDraft(long id, long moduleId, string content, string optionA, string optionB, string optionC, string optionD, string correctOption, string difficulty, string actionType)
    {
        var q = _context.Questions.Find(id);
        if (q == null) return NotFound("Câu hỏi nháp không tồn tại.");

        if (actionType == "DELETE")
        {
            _context.Questions.Remove(q);
            _context.SaveChanges();
            TempData["SuccessMessage"] = "Đã xóa câu hỏi nháp thành công.";
            return RedirectToAction(nameof(Index), new { moduleId = moduleId });
        }

        q.Content = content;
        q.OptionA = optionA;
        q.OptionB = optionB;
        q.OptionC = optionC;
        q.OptionD = optionD;
        q.CorrectOption = correctOption.ToUpper();
        q.Difficulty = difficulty.ToUpper();

        if (actionType == "APPROVE")
        {
            q.Status = "APPROVED";
            q.ApprovedBy = 1; // Simulated User ID
            TempData["SuccessMessage"] = "Đã lưu và duyệt câu hỏi vào ngân hàng câu hỏi.";
        }
        else
        {
            TempData["SuccessMessage"] = "Đã lưu thay đổi câu hỏi nháp.";
        }

        _context.SaveChanges();
        return RedirectToAction(nameof(Index), new { moduleId = moduleId });
    }
}
