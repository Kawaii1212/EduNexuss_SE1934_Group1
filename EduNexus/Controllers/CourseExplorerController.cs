using EduNexus.ViewModels;
using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Controllers
{
    public class CourseExplorerController : Controller
    {
        private readonly ILogger<CourseExplorerController> _logger;
        private readonly EduNexusContext _context;

        public CourseExplorerController(
            ILogger<CourseExplorerController> logger, 
            EduNexusContext context)
        {
            _logger = logger;
            _context = context;
        }

        public IActionResult CourseList()
        {
            return View();
        }

        public IActionResult CourseStructure()
        {
            return View();
        }

        public IActionResult AllCourses(string search = "")
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            bool isGuest = studentIdClaim == null;
            var studentName = isGuest ? "Guest" : User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value ?? "Student";

            var coursesQuery = _context.Courses
                .Include(c => c.CourseGroup)
                .Include(c => c.CreatedByNavigation)
                .Where(c => c.Status == "PUBLISHED" && c.DeletedAt == null);

            if (!string.IsNullOrEmpty(search))
            {
                coursesQuery = coursesQuery.Where(c => c.Title.Contains(search) || c.Description.Contains(search));
            }

            if (!isGuest)
            {
                long studentId = long.Parse(studentIdClaim.Value);
                
                var enrolledCourseIds = _context.Enrollments
                    .Include(e => e.Class)
                    .Where(e => e.StudentId == studentId)
                    .Select(e => e.CourseId ?? (e.Class != null ? e.Class.CourseId : null))
                    .Where(id => id != null)
                    .Select(id => id.Value)
                    .Distinct()
                    .ToList();

                if (enrolledCourseIds.Any())
                {
                    coursesQuery = coursesQuery.Where(c => !enrolledCourseIds.Contains(c.Id));
                }
            }

            var courses = coursesQuery
                .OrderByDescending(c => c.CreatedAt)
                .Select(c => new CourseItemViewModel
                {
                    Id = c.Id,
                    Title = c.Title,
                    Description = c.Description ?? "No description available.",
                    Price = c.Price,
                    InstructorName = c.CreatedByNavigation != null ? c.CreatedByNavigation.FullName : "System",
                    ThumbnailUrl = "",
                    Version = c.Version,
                    CourseGroupName = c.CourseGroup != null ? c.CourseGroup.Name : "",
                    FirstLessonId = _context.Modules.Where(m => m.CourseId == c.Id).SelectMany(m => m.Lessons).OrderBy(l => l.OrderNo).Select(l => (long?)l.Id).FirstOrDefault()
                }).ToList();

            var model = new AllCoursesViewModel
            {
                SearchQuery = search,
                Courses = courses,
                StudentName = studentName,
                IsGuest = isGuest
            };

            return View(model);
        }

        [HttpPost]
        public IActionResult Enroll(long courseId)
        {
            return RedirectToAction("UnderDevelopment");
        }

        public IActionResult UnderDevelopment()
        {
            return View();
        }
    }
}
