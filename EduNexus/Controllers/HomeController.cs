using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using EduNexus.Services;
using EduNexus.ViewModels;

namespace EduNexus.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IClassMaterialService _classMaterialService;
        private readonly IQuizAttemptService _quizAttemptService;
        private readonly IProgressService _progressService;

        public HomeController(ILogger<HomeController> logger, IClassMaterialService classMaterialService, IQuizAttemptService quizAttemptService, IProgressService progressService)
        {
            _logger = logger;
            _classMaterialService = classMaterialService;
            _quizAttemptService = quizAttemptService;
            _progressService = progressService;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }



        public IActionResult QuizBuilder()
        {
            return View();
        }



        public IActionResult FlashcardLibrary()
        {
            return View();
        }


        public IActionResult QuizTaking()
        {
            return View();
        }

        public IActionResult QuizResults()
        {
            return View();
        }

        public IActionResult QuizReview()
        {
            return View();
        }

        public IActionResult EssaySubmit()
        {
            return RedirectToAction("SubmitEssay", "Assignment", new { assignmentId = 1 });
        }

        public IActionResult EssayResults()
        {
            return View();
        }



        public IActionResult AssignmentList()
        {
            return View();
        }

        public IActionResult AssignmentDetail()
        {
            return View();
        }

        public IActionResult AIAssignmentStaging()
        {
            return View();
        }

        public IActionResult QuestionDetail()
        {
            return View();
        }

        public IActionResult AIQuestionStaging()
        {
            return View();
        }

        public IActionResult FlashcardEditor()
        {
            return View();
        }

        public IActionResult AIFlashcardStaging()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
