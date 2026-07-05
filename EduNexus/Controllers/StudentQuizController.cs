using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;

namespace EduNexus.Controllers
{
    public class StudentQuizController : Controller
    {
        private readonly IQuizAttemptService _quizAttemptService;

        public StudentQuizController(IQuizAttemptService quizAttemptService)
        {
            _quizAttemptService = quizAttemptService;
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
}
