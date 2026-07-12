<<<<<<< Updated upstream
﻿using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;
using EduNexus.ViewModels;
using System.Linq;
=======
using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;
>>>>>>> Stashed changes

namespace EduNexus.Controllers
{
    public class QuizController : Controller
    {
        private readonly IQuizAttemptService _quizAttemptService;

        public QuizController(IQuizAttemptService quizAttemptService)
        {
            _quizAttemptService = quizAttemptService;
        }

        [HttpGet]
<<<<<<< Updated upstream
        public IActionResult QuizHistory()
        {
            // 1. Đồng bộ Student ID = 1 khớp chính xác với dữ liệu mẫu bạn đã nạp thành công vào DB
            long studentId = 1;
            var attempts = _quizAttemptService.GetHistoryForStudent(studentId);

            var model = new QuizHistoryViewModel();

            if (attempts == null)
            {
                model.QuizzesTaken = 0;
                model.AverageScore = 0;
                model.PassedCount = 0;
                model.FailedCount = 0;
                model.Attempts = new System.Collections.Generic.List<QuizHistoryItemViewModel>();
                return View(model);
            }

            model.QuizzesTaken = attempts.Count;

=======
        public IActionResult History()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            long studentId = studentIdClaim != null ? long.Parse(studentIdClaim.Value) : 1;
            var attempts = _quizAttemptService.GetHistoryForStudent(studentId);

            var model = new EduNexus.ViewModels.QuizHistoryViewModel();
            model.QuizzesTaken = attempts.Count;
            
>>>>>>> Stashed changes
            if (attempts.Any(a => a.Score.HasValue))
            {
                model.AverageScore = attempts.Where(a => a.Score.HasValue).Average(a => a.Score.Value);
            }

<<<<<<< Updated upstream
            // 2. Tính toán số bài Đạt/Trượt cho Stats Card dựa trên mức điểm 50 theo trạng thái 'SUBMITTED' thực tế của DB
            model.PassedCount = attempts.Count(a => a.Status == "SUBMITTED" && (a.Score >= 50 || !a.Score.HasValue));
            model.FailedCount = attempts.Count(a => a.Status == "SUBMITTED" && a.Score < 50);

            // 3. ĐÃ FIX: Đổi tên Class về chuẩn 'QuizHistoryItemViewModel' khớp 100% dự án của bạn
            model.Attempts = attempts.Select(a => new QuizHistoryItemViewModel
=======
            model.PassedCount = attempts.Count(a => a.Status == "PASSED");
            model.FailedCount = attempts.Count(a => a.Status == "FAILED");

            model.Attempts = attempts.Select(a => new EduNexus.ViewModels.QuizHistoryItemViewModel
>>>>>>> Stashed changes
            {
                QuizAttemptId = a.Id,
                QuizTitle = a.Quiz?.Name ?? "Unknown Quiz",
                CourseName = a.Quiz?.Course?.Title ?? "Unknown Course",
                DateTaken = a.StartTime,
                Score = a.Score,
<<<<<<< Updated upstream
                Status = a.Status, // Giữ 'SUBMITTED', tầng View (.cshtml) sẽ tự phân loại Passed/Failed để bật màu Badge

                // Tính toán chính xác câu đúng / tổng số câu từ Service
                CorrectAnswers = a.QuizAttemptAnswers?.Count(ans => ans.IsCorrect == true) ?? 0,
                TotalQuestions = a.Quiz?.QuestionCount ?? 0
            }).ToList();

            

=======
                Status = a.Status
            }).ToList();

>>>>>>> Stashed changes
            return View(model);
        }

        [HttpGet]
        public IActionResult Result(long attemptId)
        {
            var vm = _quizAttemptService.GetQuizResultViewModel(attemptId);
            if (vm == null)
            {
                return NotFound();
            }

            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> AnalyzeResult(long attemptId)
        {
            try
            {
                var analysis = await _quizAttemptService.AnalyzeAttemptAsync(attemptId);
                if (analysis == null)
                {
                    return NotFound(new { success = false, message = "Attempt not found" });
                }

                return Ok(new { success = true, analysis = analysis });
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
            if (vm == null)
            {
                return NotFound();
            }

            return View(vm);
        }
    }
<<<<<<< Updated upstream
}
=======
}
>>>>>>> Stashed changes
