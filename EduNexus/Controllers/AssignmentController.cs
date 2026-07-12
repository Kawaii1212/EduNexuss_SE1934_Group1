using EduNexus.ViewModels;
using System;
using System.IO;
using System.Threading.Tasks;
using EduNexus.Services;
using EduNexus.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;

using Microsoft.Extensions.DependencyInjection;

namespace EduNexus.Controllers;

public class AssignmentController : Controller
{
    private readonly ISubmissionService _submissionService;
    private readonly IWebHostEnvironment _env;
    private readonly IServiceScopeFactory _scopeFactory;

    public AssignmentController(ISubmissionService submissionService, IWebHostEnvironment env, IServiceScopeFactory scopeFactory)
    {
        _submissionService = submissionService;
        _env = env;
        _scopeFactory = scopeFactory;
    }

    [HttpGet]
    public IActionResult SubmitEssay(long assignmentId, long? lessonId)
    {
        var model = new SubmitEssayViewModel
        {
            AssignmentId = assignmentId,
            LessonId = lessonId
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
            long submissionId = _submissionService.SubmitEssay(model.AssignmentId, studentId, model.Content, fileUrl);
            TempData["SuccessMessage"] = "Nộp bài thành công. Hệ thống AI đang phân tích bài làm của bạn...";

            // Fire and forget async AI evaluation
            _ = Task.Run(async () => 
            {
                using var scope = _scopeFactory.CreateScope();
                var scopedService = scope.ServiceProvider.GetRequiredService<ISubmissionService>();
                await scopedService.EvaluateSubmissionWithAIAsync(submissionId);
            });

            return RedirectToAction("Result", new { submissionId = submissionId });
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", "Đã xảy ra lỗi khi lưu bài: " + ex.Message);
            return View("~/Views/Home/EssaySubmit.cshtml", model);
        }
    }

    [HttpGet]
    public IActionResult Result(long submissionId)
    {
        try
        {
            var submission = _submissionService.GetSubmissionResult(submissionId);

            // Optional: Authorize if the logged-in user is the owner of the submission
            // long currentUserId = long.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            // if (submission.StudentId != currentUserId) return Unauthorized();

            var model = new SubmissionResultViewModel
            {
                SubmissionId = submission.Id,
                AssignmentTitle = submission.Assignment?.Title ?? "Unknown Assignment",
                StudentName = submission.Student?.FullName ?? "Unknown Student",
                FinalScore = submission.FinalScore,
                AiScore = submission.AiScore,
                Feedback = submission.Feedback,
                Status = submission.Status,
                SubmittedAt = submission.SubmittedAt,
                CriterionScores = submission.SubmissionCriterionScores.Select(scs => new CriterionScoreViewModel
                {
                    CriterionName = scs.Criterion?.Name ?? "Unknown Criterion",
                    MaxScore = scs.Criterion?.MaxScore ?? 0,
                    WeightPercent = scs.Criterion?.WeightPercent ?? 0,
                    AiScore = scs.AiScore,
                    FinalScore = scs.FinalScore,
                    AiFeedback = scs.AiFeedback,
                    TeacherFeedback = scs.TeacherFeedback
                }).ToList()
            };

            return View(model);
        }
        catch (Exception ex)
        {
            return NotFound("Submission not found or error occurred: " + ex.Message);
        }
    }
}
