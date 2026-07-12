using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using EduNexus.Models;
using EduNexus.Services;
using EduNexus.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace EduNexus.Controllers
{
    public class QuizController : Controller
    {
        private readonly IQuizAttemptService _quizAttemptService;
        private readonly EduNexusContext _context;

        public QuizController(IQuizAttemptService quizAttemptService, EduNexusContext context)
        {
            _quizAttemptService = quizAttemptService;
            _context = context;
        }

        private long GetStudentId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (claim != null) return long.Parse(claim.Value);
            return _context.Users.FirstOrDefault(u => u.Role == "STUDENT")?.Id ?? 1;
        }

        [HttpGet]
        public IActionResult History()
        {
            var studentId = GetStudentId();
            var attempts = _quizAttemptService.GetHistoryForStudent(studentId);

            var model = new QuizHistoryViewModel();

            if (attempts == null || attempts.Count == 0)
            {
                model.QuizzesTaken = 0;
                model.AverageScore = 0;
                model.PassedCount = 0;
                model.FailedCount = 0;
                model.Attempts = new List<QuizHistoryItemViewModel>();
                return View(model);
            }

            model.QuizzesTaken = attempts.Count;

            if (attempts.Any(a => a.Score.HasValue))
                model.AverageScore = attempts.Where(a => a.Score.HasValue).Average(a => a.Score!.Value);

            model.PassedCount = attempts.Count(a => a.Status == "SUBMITTED" && (a.Score >= 50 || !a.Score.HasValue));
            model.FailedCount = attempts.Count(a => a.Status == "SUBMITTED" && a.Score < 50);

            model.Attempts = attempts.Select(a => new QuizHistoryItemViewModel
            {
                QuizAttemptId = a.Id,
                QuizTitle = a.Quiz?.Name ?? "Unknown Quiz",
                CourseName = a.Quiz?.Course?.Title ?? "Unknown Course",
                DateTaken = a.StartTime,
                Score = a.Score,
                Status = a.Status,
                CorrectAnswers = a.QuizAttemptAnswers?.Count(ans => ans.IsCorrect == true) ?? 0,
                TotalQuestions = a.Quiz?.QuestionCount ?? 0
            }).ToList();

            return View(model);
        }

        // Student: New Quiz (tạo bài luyện tập)
        [HttpGet]
        public IActionResult New(long? courseId)
        {
            return View(_quizAttemptService.GetNewQuizViewModel(courseId));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Create(CreatePracticeQuizRequest form)
        {
            if (!ModelState.IsValid)
            {
                var vm = _quizAttemptService.GetNewQuizViewModel(form.CourseId);
                vm.Form = form;
                vm.ErrorMessage = "Vui lòng kiểm tra lại thông tin.";
                return View("New", vm);
            }

            try
            {
                var attemptId = _quizAttemptService.CreatePracticeQuiz(form, GetStudentId());
                return RedirectToAction(nameof(Taking), new { attemptId });
            }
            catch (Exception ex)
            {
                var vm = _quizAttemptService.GetNewQuizViewModel(form.CourseId);
                vm.Form = form;
                vm.ErrorMessage = ex.Message;
                return View("New", vm);
            }
        }

        // Student: Quiz Taking
        [HttpGet]
        public IActionResult Taking(long attemptId)
        {
            var vm = _quizAttemptService.GetTakingViewModel(attemptId);
            if (vm == null) return NotFound();
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Submit(SubmitQuizRequest request)
        {
            _quizAttemptService.SubmitQuiz(request.AttemptId, request.Answers ?? new Dictionary<long, string>());
            return RedirectToAction(nameof(Result), new { attemptId = request.AttemptId });
        }

        [HttpGet]
        public IActionResult Result(long attemptId)
        {
            var vm = _quizAttemptService.GetQuizResultViewModel(attemptId);
            if (vm == null) return NotFound();
            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> AnalyzeResult(long attemptId)
        {
            try
            {
                var analysis = await _quizAttemptService.AnalyzeAttemptAsync(attemptId);
                if (analysis == null)
                    return NotFound(new { success = false, message = "Attempt not found" });
                return Ok(new { success = true, analysis });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        [HttpGet]
        public IActionResult Review(long attemptId)
        {
            var vm = _quizAttemptService.GetQuizReviewViewModel(attemptId);
            if (vm == null) return NotFound();
            return View(vm);
        }
    }
}
