using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace EduNexus.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        public IActionResult CourseStructure()
        {
            return View();
        }

        public IActionResult EditLesson()
        {
            return View();
        }

        public IActionResult QuizBuilder()
        {
            return View();
        }

        public IActionResult PersonalProgress()
        {
            return View();
        }

        public IActionResult StudentLibrary()
        {
            return View();
        }

        public IActionResult LessonView()
        {
            return View();
        }

        public IActionResult FlashcardLibrary()
        {
            return View();
        }

        public IActionResult QuizHistory()
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
            return View();
        }

        public IActionResult EssayResults()
        {
            return View();
        }

        public IActionResult AILessonStaging()
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
