using System;
using System.IO;
using System.Threading.Tasks;
using DataAccessLayer.Services;
using EduNexus.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;

namespace EduNexus.Controllers;

public class AssignmentController : Controller
{
    private readonly ISubmissionService _submissionService;
    private readonly IWebHostEnvironment _env;

    public AssignmentController(ISubmissionService submissionService, IWebHostEnvironment env)
    {
        _submissionService = submissionService;
        _env = env;
    }

    [HttpGet]
    public IActionResult SubmitEssay(long assignmentId)
    {
        var model = new SubmitEssayViewModel
        {
            AssignmentId = assignmentId
        };
        return View("~/Views/Home/EssaySubmit.cshtml", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SubmitEssay(SubmitEssayViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View("~/Views/Home/EssaySubmit.cshtml", model);
        }

        // Mocking StudentId since Auth is not fully implemented in the snippet
        // In reality, this would be: long.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
        long studentId = 1; 

        string? fileUrl = null;
        if (model.AttachedFile != null && model.AttachedFile.Length > 0)
        {
            var uploadsFolder = Path.Combine(_env.WebRootPath, "uploads", "submissions");
            if (!Directory.Exists(uploadsFolder))
            {
                Directory.CreateDirectory(uploadsFolder);
            }

            var uniqueFileName = Guid.NewGuid().ToString() + "_" + model.AttachedFile.FileName;
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await model.AttachedFile.CopyToAsync(fileStream);
            }

            fileUrl = "/uploads/submissions/" + uniqueFileName;
        }

        try
        {
            _submissionService.SubmitEssay(model.AssignmentId, studentId, model.Content, fileUrl);
            TempData["SuccessMessage"] = "Nộp bài thành công. Hệ thống AI đang phân tích bài làm của bạn...";
            return RedirectToAction("SubmitEssay", new { assignmentId = model.AssignmentId });
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", "Đã xảy ra lỗi khi lưu bài: " + ex.Message);
            return View("~/Views/Home/EssaySubmit.cshtml", model);
        }
    }
}
