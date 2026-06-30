using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using DataAccessLayer.Services;

namespace EduNexus.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IClassMaterialService _classMaterialService;
        private readonly DataAccessLayer.Services.IQuizAttemptService _quizAttemptService;
        private readonly IProgressService _progressService;

        public HomeController(ILogger<HomeController> logger, IClassMaterialService classMaterialService, DataAccessLayer.Services.IQuizAttemptService quizAttemptService, IProgressService progressService)
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
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("SignIn", "Auth");
            
            long studentId = long.Parse(studentIdClaim.Value);
            
            var enrollments = _progressService.GetEnrollmentsByStudent(studentId);
            var learningProgresses = _progressService.GetLearningProgressesByStudent(studentId);

            int totalSeconds = 0;
            var activeDates = new System.Collections.Generic.HashSet<string>();

            foreach(var lp in learningProgresses)
            {
                totalSeconds += lp.TimeSpentSeconds;
                activeDates.Add(lp.LastActiveAt.ToString("yyyy-MM-dd"));
            }

            var viewModel = new PersonalProgressViewModel
            {
                CoursesEnrolled = System.Linq.Enumerable.Count(enrollments),
                CoursesCompleted = System.Linq.Enumerable.Count(enrollments, e => e.ProgressPercent >= 100 || e.Status == "Completed"),
                LearningHours = totalSeconds / 3600,
                CurrentStreak = activeDates.Count // Simplistic streak calculation
            };

            string[] defaultIcons = { "fa-react", "fa-node-js", "fa-docker", "fa-python", "fa-java" };
            string[] defaultColors = { "#3b82f6", "#10b981", "#3b82f6", "#f59e0b", "#ef4444" };
            int i = 0;

            foreach (var e in enrollments)
            {
                if (e.ProgressPercent < 100)
                {
                    var actualCourse = e.Course ?? e.Class?.Course;
                    if (actualCourse != null)
                    {
                        viewModel.OngoingCourses.Add(new OngoingCourseViewModel
                        {
                            CourseId = actualCourse.Id,
                            CourseName = actualCourse.Title,
                            CurrentModuleOrLesson = e.Class != null ? "Enrolled in Class: " + e.Class.Name : "Self-paced Course", 
                            ProgressPercent = e.ProgressPercent,
                            IconClass = "fa-brands " + defaultIcons[i % defaultIcons.Length],
                            IconColorHex = defaultColors[i % defaultColors.Length]
                        });
                        i++;
                    }
                }
            }

            return View(viewModel);
        }

        public IActionResult StudentLibrary()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("SignIn", "Auth");
            
            long studentId = long.Parse(studentIdClaim.Value);
            var materials = _classMaterialService.GetMaterialsByStudentId(studentId);
            
            var viewModel = new StudentLibraryViewModel();
            foreach (var material in materials)
            {
                viewModel.Resources.Add(new ResourceItemViewModel
                {
                    Id = material.Id,
                    Title = material.Title,
                    Description = material.Body ?? "No description provided.",
                    FileUrl = material.FileUrl ?? "#",
                    FileSize = "Unknown Size" // Mock data since DB doesn't have it
                });
            }

            return View(viewModel);
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
            long studentId = 2; // Mock Student ID
            var attempts = _quizAttemptService.GetHistoryForStudent(studentId);

            var model = new QuizHistoryViewModel();
            model.QuizzesTaken = attempts.Count;
            
            if (attempts.Any(a => a.Score.HasValue))
            {
                model.AverageScore = attempts.Where(a => a.Score.HasValue).Average(a => a.Score.Value);
            }

            model.PassedCount = attempts.Count(a => a.Status == "PASSED");
            model.FailedCount = attempts.Count(a => a.Status == "FAILED");

            model.Attempts = attempts.Select(a => new QuizHistoryItemViewModel
            {
                QuizAttemptId = a.Id,
                QuizTitle = a.Quiz?.Name ?? "Unknown Quiz",
                CourseName = a.Quiz?.Course?.Title ?? "Unknown Course",
                DateTaken = a.StartTime,
                Score = a.Score,
                Status = a.Status
            }).ToList();

            return View(model);
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
