using EduNexus.Models;
using EduNexus.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace EduNexus.Controllers
{
    public class CourseController : Controller
    {
        private readonly EduNexusContext _context;

        public CourseController(EduNexusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult MyCourses()
        {
            long userId = 0;
            string userName = "SME";

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim != null)
            {
                userId = long.Parse(userIdClaim.Value);
                userName = User.FindFirst(ClaimTypes.Name)?.Value ?? "SME";
            }
            else
            {
                // Fallback to first SME user in DB for testing without login
                var defaultSme = _context.Users.FirstOrDefault(u => u.Role == "SME" || u.Role == "sme");
                if (defaultSme != null)
                {
                    userId = defaultSme.Id;
                    userName = defaultSme.FullName;
                }
                else
                {
                    // Fallback to first user in DB, or ID 3
                    var firstUser = _context.Users.FirstOrDefault();
                    userId = firstUser?.Id ?? 3;
                    userName = firstUser?.FullName ?? "Mock SME";
                }
            }

            // Query course group IDs where this user is assigned as an SME
            var courseGroupIds = _context.CourseGroupMembers
                .Where(cgm => cgm.UserId == userId && cgm.RoleInGroup == "SME")
                .Select(cgm => cgm.CourseGroupId)
                .ToList();

            // Fetch the corresponding courses
            var courses = _context.Courses
                .Include(c => c.CourseGroup)
                .Include(c => c.Modules)
                .Include(c => c.Classes)
                .Where(c => courseGroupIds.Contains(c.CourseGroupId) && c.DeletedAt == null)
                .Select(c => new SmeCourseItemViewModel
                {
                    Id = c.Id,
                    Title = c.Title,
                    Description = c.Description ?? string.Empty,
                    CourseGroupName = c.CourseGroup.Name,
                    Status = c.Status,
                    ModuleCount = c.Modules.Count,
                    ClassCount = c.Classes.Count
                })
                .ToList();

            var viewModel = new SmeCoursesViewModel
            {
                SmeName = userName,
                Courses = courses
            };

            return View(viewModel);
        }

        [HttpGet]
        public IActionResult Structure(long courseId)
        {
            var course = _context.Courses
                .Include(c => c.CourseGroup)
                .Include(c => c.Modules)
                    .ThenInclude(m => m.Lessons)
                .FirstOrDefault(c => c.Id == courseId && c.DeletedAt == null);

            if (course == null)
            {
                return NotFound("Khóa học không tồn tại.");
            }

            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = null;

            var viewModel = new SmeCourseStructureViewModel
            {
                CourseId = course.Id,
                CourseTitle = course.Title,
                CourseGroupName = course.CourseGroup.Name,
                Status = course.Status,
                Modules = course.Modules.OrderBy(m => m.OrderNo).Select(m => new SmeModuleItemViewModel
                {
                    Id = m.Id,
                    Title = m.Title,
                    Description = m.Description ?? string.Empty,
                    OrderNo = m.OrderNo,
                    Lessons = m.Lessons.OrderBy(l => l.OrderNo).Select(l => new SmeLessonItemViewModel
                    {
                        Id = l.Id,
                        Title = l.Title,
                        Summary = l.Summary ?? string.Empty,
                        OrderNo = l.OrderNo
                    }).ToList(),
                    QuestionCount = _context.Questions.Count(q => q.ModuleId == m.Id),
                    AssignmentCount = 2, // Mock count
                    FlashcardCount = _context.FlashcardDecks.Count(fd => fd.ModuleId == m.Id),
                    QuizCount = _context.Quizzes.Count(q => q.CourseId == courseId) // Course level quiz
                }).ToList()
            };

            return View(viewModel);
        }

        [HttpGet]
        public IActionResult Lessons(long courseId)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == courseId && c.DeletedAt == null);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = "Lessons";

            return View("Placeholder", "Bài học (Lesson)");
        }

        [HttpGet]
        public IActionResult Assignments(long courseId)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == courseId && c.DeletedAt == null);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = "Assignments";

            string userName = User.FindFirst(ClaimTypes.Name)?.Value ?? "SME";

            var assignments = _context.Assignments
                .Include(a => a.Class)
                .Include(a => a.Submissions)
                .Where(a => a.Class.CourseId == courseId)
                .Select(a => new SmeAssignmentItemViewModel
                {
                    Id = a.Id,
                    Title = a.Title,
                    ClassName = a.Class.Name,
                    MaxScore = a.MaxScore,
                    DueDate = a.DueDate,
                    Status = a.Status,
                    SubmissionCount = a.Submissions.Count
                })
                .ToList();

            var viewModel = new SmeAssignmentsViewModel
            {
                CourseId = course.Id,
                CourseTitle = course.Title,
                SmeName = userName,
                Assignments = assignments,
                ActiveAssignments = assignments.Count(a => a.Status == "PUBLISHED" && a.DueDate > DateTimeOffset.UtcNow),
                DraftAssignments = assignments.Count(a => a.Status == "DRAFT" || a.Status == "CLOSED" || a.DueDate <= DateTimeOffset.UtcNow)
            };

            return View(viewModel);
        }

        [HttpGet]
        public IActionResult Flashcards(long courseId)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == courseId && c.DeletedAt == null);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = "Flashcards";

            return View("Placeholder", "Flashcard");
        }

        // GET: /Course/CreateModule
        [HttpGet]
        public IActionResult CreateModule(long courseId)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == courseId && c.DeletedAt == null);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";

            var module = new Module { CourseId = courseId };
            return View(module);
        }

        // POST: /Course/CreateModule
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CreateModule(Module model)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == model.CourseId && c.DeletedAt == null);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            ModelState.Remove("Course");
            ModelState.Remove("Lessons");
            ModelState.Remove("Questions");
            ModelState.Remove("FlashcardDecks");

            if (!ModelState.IsValid)
            {
                ViewBag.ActiveCourseId = course.Id;
                ViewBag.ActiveCourseTitle = course.Title;
                ViewData["ActiveMenu"] = "MyCourses";
                return View(model);
            }

            model.OrderNo = _context.Modules.Count(m => m.CourseId == model.CourseId) + 1;
            model.CreatedAt = DateTimeOffset.UtcNow;

            _context.Modules.Add(model);
            _context.SaveChanges();

            return RedirectToAction("Structure", new { courseId = model.CourseId });
        }

        // GET: /Course/EditModule
        [HttpGet]
        public IActionResult EditModule(long moduleId)
        {
            var module = _context.Modules
                .Include(m => m.Course)
                .FirstOrDefault(m => m.Id == moduleId);
            if (module == null) return NotFound("Chương học không tồn tại.");

            ViewBag.ActiveCourseId = module.CourseId;
            ViewBag.ActiveCourseTitle = module.Course.Title;
            ViewData["ActiveMenu"] = "MyCourses";

            return View(module);
        }

        // POST: /Course/EditModule
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult EditModule(long id, Module model)
        {
            var existingModule = _context.Modules
                .Include(m => m.Course)
                .FirstOrDefault(m => m.Id == id);
            if (existingModule == null) return NotFound("Chương học không tồn tại.");

            ModelState.Remove("Course");
            ModelState.Remove("Lessons");
            ModelState.Remove("Questions");
            ModelState.Remove("FlashcardDecks");

            if (!ModelState.IsValid)
            {
                ViewBag.ActiveCourseId = existingModule.CourseId;
                ViewBag.ActiveCourseTitle = existingModule.Course.Title;
                ViewData["ActiveMenu"] = "MyCourses";
                return View(model);
            }

            existingModule.Title = model.Title;
            existingModule.Description = model.Description;

            _context.SaveChanges();

            return RedirectToAction("Structure", new { courseId = existingModule.CourseId });
        }

        // POST: /Course/DeleteModule
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult DeleteModule(long moduleId)
        {
            var module = _context.Modules.Find(moduleId);
            if (module == null) return NotFound("Chương học không tồn tại.");

            long courseId = module.CourseId;

            // Delete dependencies manually to avoid DB constraints errors
            var lessonIds = _context.Lessons.Where(l => l.ModuleId == moduleId).Select(l => l.Id).ToList();

            // 1. Delete progress and events referencing lessons
            var progresses = _context.LearningProgresses.Where(lp => lp.LessonId != null && lessonIds.Contains(lp.LessonId.Value));
            _context.LearningProgresses.RemoveRange(progresses);

            var viewEvents = _context.LessonViewEvents.Where(lve => lessonIds.Contains(lve.LessonId));
            _context.LessonViewEvents.RemoveRange(viewEvents);

            // 2. Delete QuizQuestions and Attempt Answers referencing questions
            var questionIds = _context.Questions.Where(q => q.ModuleId == moduleId).Select(q => q.Id).ToList();
            var quizQuestions = _context.QuizQuestions.Where(qq => questionIds.Contains(qq.QuestionId));
            _context.QuizQuestions.RemoveRange(quizQuestions);

            var attemptAnswers = _context.QuizAttemptAnswers.Where(qaa => questionIds.Contains(qaa.QuestionId));
            _context.QuizAttemptAnswers.RemoveRange(attemptAnswers);

            // 3. Delete Flashcard Review Logs and Flashcards referencing decks
            var deckIds = _context.FlashcardDecks.Where(fd => fd.ModuleId == moduleId).Select(fd => fd.Id).ToList();
            var flashcards = _context.Flashcards.Where(f => deckIds.Contains(f.DeckId)).ToList();
            var flashcardIds = flashcards.Select(f => f.Id).ToList();

            var reviewLogs = _context.FlashcardReviewLogs.Where(frl => flashcardIds.Contains(frl.FlashcardId));
            _context.FlashcardReviewLogs.RemoveRange(reviewLogs);
            _context.Flashcards.RemoveRange(flashcards);

            // 4. Delete primary entities under the module
            var lessons = _context.Lessons.Where(l => l.ModuleId == moduleId);
            _context.Lessons.RemoveRange(lessons);

            var questions = _context.Questions.Where(q => q.ModuleId == moduleId);
            _context.Questions.RemoveRange(questions);

            var flashcardDecks = _context.FlashcardDecks.Where(fd => fd.ModuleId == moduleId);
            _context.FlashcardDecks.RemoveRange(flashcardDecks);

            _context.Modules.Remove(module);
            _context.SaveChanges();

            return RedirectToAction("Structure", new { courseId = courseId });
        }

        // POST: /Course/CreateLesson
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CreateLesson(Lesson model)
        {
            var module = _context.Modules
                .Include(m => m.Course)
                .FirstOrDefault(m => m.Id == model.ModuleId);
            if (module == null) return NotFound("Chương học không tồn tại.");

            ModelState.Remove("Module");
            ModelState.Remove("LearningProgresses");
            ModelState.Remove("LessonViewEvents");
            ModelState.Remove("CreatedByNavigation");
            ModelState.Remove("Content");
            ModelState.Remove("Status");

            if (!ModelState.IsValid)
            {
                TempData["ErrorMessage"] = "Tiêu đề bài học không hợp lệ.";
                return RedirectToAction("Structure", new { courseId = module.CourseId });
            }

            model.Content = ""; // Required non-nullable field
            model.Status = "PUBLISHED"; // Required non-nullable field
            model.OrderNo = _context.Lessons.Count(l => l.ModuleId == model.ModuleId) + 1;
            model.CreatedAt = DateTimeOffset.UtcNow;
            model.UpdatedAt = DateTimeOffset.UtcNow;

            _context.Lessons.Add(model);
            _context.SaveChanges();

            return RedirectToAction("Structure", new { courseId = module.CourseId });
        }

        // POST: /Course/EditLesson
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult EditLesson(long id, Lesson model)
        {
            var existingLesson = _context.Lessons
                .Include(l => l.Module)
                .FirstOrDefault(l => l.Id == id);
            if (existingLesson == null) return NotFound("Bài học không tồn tại.");

            ModelState.Remove("Module");
            ModelState.Remove("LearningProgresses");
            ModelState.Remove("LessonViewEvents");
            ModelState.Remove("CreatedByNavigation");
            ModelState.Remove("Content");
            ModelState.Remove("Status");

            if (!ModelState.IsValid)
            {
                TempData["ErrorMessage"] = "Tiêu đề bài học không hợp lệ.";
                return RedirectToAction("Structure", new { courseId = existingLesson.Module.CourseId });
            }

            existingLesson.Title = model.Title;
            existingLesson.UpdatedAt = DateTimeOffset.UtcNow;

            _context.SaveChanges();

            return RedirectToAction("Structure", new { courseId = existingLesson.Module.CourseId });
        }

        // POST: /Course/DeleteLesson
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult DeleteLesson(long lessonId)
        {
            var lesson = _context.Lessons
                .Include(l => l.Module)
                .FirstOrDefault(l => l.Id == lessonId);
            if (lesson == null) return NotFound("Bài học không tồn tại.");

            long courseId = lesson.Module.CourseId;

            // Delete dependencies to avoid DB constraints errors
            var progresses = _context.LearningProgresses.Where(lp => lp.LessonId == lessonId);
            _context.LearningProgresses.RemoveRange(progresses);

            var viewEvents = _context.LessonViewEvents.Where(lve => lve.LessonId == lessonId);
            _context.LessonViewEvents.RemoveRange(viewEvents);

            _context.Lessons.Remove(lesson);
            _context.SaveChanges();

            return RedirectToAction("Structure", new { courseId = courseId });
        }
    }
}
