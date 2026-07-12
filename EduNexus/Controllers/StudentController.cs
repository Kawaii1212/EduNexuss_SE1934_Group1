using EduNexus.ViewModels;
using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;

namespace EduNexus.Controllers
{
    public class StudentController : Controller
    {
        private readonly ILogger<StudentController> _logger;
        private readonly IClassMaterialService _classMaterialService;
        private readonly IProgressService _progressService;
        private readonly IUserService _userService;

        public StudentController(
            ILogger<StudentController> logger, 
            IClassMaterialService classMaterialService, 
            IProgressService progressService,
            IUserService userService)
        {
            _logger = logger;
            _classMaterialService = classMaterialService;
            _progressService = progressService;
            _userService = userService;
        }

        public IActionResult PersonalProgress()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Auth");
            
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
                CurrentStreak = activeDates.Count 
            };

            string[] defaultIcons = { "fa-react", "fa-node-js", "fa-docker", "fa-python", "fa-java" };
            string[] defaultColors = { "#3b82f6", "#10b981", "#3b82f6", "#f59e0b", "#ef4444" };
            int i = 0;

            using var context = new EduNexusContext(AppConfiguration.DbContextOptions);
            var addedCourseIds = new System.Collections.Generic.HashSet<long>();

            foreach (var e in enrollments.OrderByDescending(e => e.ClassId.HasValue))
            {
                var actualCourse = e.Course ?? e.Class?.Course;
                if (actualCourse != null && !addedCourseIds.Contains(actualCourse.Id))
                {
                    addedCourseIds.Add(actualCourse.Id);
                    var lastProgress = context.LearningProgresses
                        .Where(lp => lp.StudentId == studentId && lp.Lesson != null && lp.Lesson.Module.CourseId == actualCourse.Id)
                        .OrderByDescending(lp => lp.LastActiveAt)
                        .FirstOrDefault();
                    long? targetLessonId = lastProgress?.LessonId;

                    if (targetLessonId == null)
                    {
                        var firstLesson = context.Lessons
                            .Where(l => l.Module.CourseId == actualCourse.Id)
                            .OrderBy(l => l.Module.OrderNo).ThenBy(l => l.OrderNo)
                            .FirstOrDefault();
                        targetLessonId = firstLesson?.Id;
                    }

                    var courseVm = new OngoingCourseViewModel
                    {
                        CourseId = actualCourse.Id,
                        CourseName = actualCourse.Title,
                        CurrentModuleOrLesson = e.Class != null ? "Enrolled in Class: " + e.Class.Name : "Self-paced Course", 
                        ProgressPercent = e.ProgressPercent,
                        TargetLessonId = targetLessonId,
                        IconClass = "fa-brands " + defaultIcons[i % defaultIcons.Length],
                        IconColorHex = defaultColors[i % defaultColors.Length]
                    };

                    if (e.ProgressPercent < 100)
                    {
                        viewModel.OngoingCourses.Add(courseVm);
                    }
                    else
                    {
                        viewModel.CompletedCourses.Add(courseVm);
                    }
                    i++;
                }
            }

            return View(viewModel);
        }

        public IActionResult StudentSettings()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Auth");
            
            long studentId = long.Parse(studentIdClaim.Value);
            var user = _userService.GetUserById(studentId);
            if (user == null) return RedirectToAction("UserLogin", "Auth");

            var model = new StudentSettingsViewModel
            {
                FullName = user.FullName ?? "Student",
                Email = user.Email ?? "",
                Phone = user.Phone,
                EmailNotifications = true,
                SMSReminders = false
            };
            return View(model);
        }

        [HttpPost]
        public IActionResult UpdateProfile(StudentSettingsViewModel model)
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Auth");

            long studentId = long.Parse(studentIdClaim.Value);
            var user = _userService.GetUserById(studentId);
            if (user == null) return RedirectToAction("UserLogin", "Auth");

            if (!string.IsNullOrEmpty(model.FullName)) user.FullName = model.FullName;
            if (!string.IsNullOrEmpty(model.Email)) user.Email = model.Email;
            if (!string.IsNullOrEmpty(model.Phone)) user.Phone = model.Phone;

            _userService.UpdateUser(user);
            TempData["Success"] = "Profile updated successfully.";
            
            return RedirectToAction("StudentSettings");
        }

        [HttpPost]
        public IActionResult ChangePassword(StudentSettingsViewModel model)
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Auth");

            long studentId = long.Parse(studentIdClaim.Value);
            var user = _userService.GetUserById(studentId);
            if (user == null) return RedirectToAction("UserLogin", "Auth");

            if (user.PasswordHash != model.CurrentPassword)
            {
                TempData["Error"] = "Current password is incorrect.";
                TempData["ActiveTab"] = "security";
                return RedirectToAction("StudentSettings");
            }

            if (string.IsNullOrEmpty(model.NewPassword) || model.NewPassword != model.ConfirmPassword)
            {
                TempData["Error"] = "New passwords do not match or are empty.";
                TempData["ActiveTab"] = "security";
                return RedirectToAction("StudentSettings");
            }

            user.PasswordHash = model.NewPassword;
            _userService.UpdateUser(user);

            TempData["Success"] = "Password updated successfully.";
            TempData["ActiveTab"] = "security";
            
            return RedirectToAction("StudentSettings");
        }

        [HttpGet]
        public IActionResult StudentLibrary()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Auth");
            
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
                    FileSize = "Unknown Size" 
                });
            }

            return View(viewModel);
        }

        public IActionResult StudentDashboard()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Auth");
            
            long studentId = long.Parse(studentIdClaim.Value);
            var studentName = User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value ?? "Student";

            var enrollments = _progressService.GetEnrollmentsByStudent(studentId);
            var learningProgresses = _progressService.GetLearningProgressesByStudent(studentId);

            int totalSeconds = 0;
            var activeDates = new System.Collections.Generic.HashSet<string>();

            foreach(var lp in learningProgresses)
            {
                totalSeconds += lp.TimeSpentSeconds;
                activeDates.Add(lp.LastActiveAt.ToString("yyyy-MM-dd"));
            }

            var viewModel = new StudentDashboardViewModel
            {
                StudentName = studentName,
                CoursesInProgress = enrollments.Count(e => e.ProgressPercent < 100),
                TotalLearningHours = totalSeconds / 3600,
                CurrentStreak = activeDates.Count
            };

            string[] defaultIcons = { "fa-react", "fa-node-js", "fa-database", "fa-python", "fa-java" };
            string[] defaultColors = { "#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#3b82f6" };
            int i = 0;

            using var context = new EduNexusContext(AppConfiguration.DbContextOptions);
            var addedDashboardCourseIds = new System.Collections.Generic.HashSet<long>();

            foreach (var e in enrollments.Where(e => e.ProgressPercent < 100).OrderByDescending(e => e.ClassId.HasValue).ThenByDescending(e => e.CreatedAt))
            {
                var actualCourse = e.Course ?? e.Class?.Course;
                if (actualCourse != null && !addedDashboardCourseIds.Contains(actualCourse.Id))
                {
                    addedDashboardCourseIds.Add(actualCourse.Id);
                    var lastProgress = context.LearningProgresses
                        .Where(lp => lp.StudentId == studentId && lp.Lesson != null && lp.Lesson.Module.CourseId == actualCourse.Id)
                        .OrderByDescending(lp => lp.LastActiveAt)
                        .FirstOrDefault();
                    long? targetLessonId = lastProgress?.LessonId;

                    if (targetLessonId == null)
                    {
                        var firstLesson = context.Lessons
                            .Where(l => l.Module.CourseId == actualCourse.Id)
                            .OrderBy(l => l.Module.OrderNo).ThenBy(l => l.OrderNo)
                            .FirstOrDefault();
                        targetLessonId = firstLesson?.Id;
                    }

                    var courseVm = new OngoingCourseViewModel
                    {
                        CourseId = actualCourse.Id,
                        CourseName = actualCourse.Title,
                        CurrentModuleOrLesson = e.Class != null ? "Enrolled in Class: " + e.Class.Name : "Self-paced Course", 
                        ProgressPercent = e.ProgressPercent,
                        TargetLessonId = targetLessonId,
                        IconClass = "fa-brands " + defaultIcons[i % defaultIcons.Length],
                        IconColorHex = defaultColors[i % defaultColors.Length]
                    };
                    viewModel.OngoingCourses.Add(courseVm);
                    if (viewModel.LastAccessedCourse == null) viewModel.LastAccessedCourse = courseVm;
                    i++;
                }
            }

            var now = DateTimeOffset.Now;

            var studentClassIds = enrollments.Where(e => e.ClassId != null).Select(e => e.ClassId!.Value).ToList();
            var assignments = context.Assignments
                .Where(a => studentClassIds.Contains(a.ClassId) && a.DueDate > now)
                .OrderBy(a => a.DueDate)
                .Take(5)
                .ToList();

            viewModel.AssignmentsDue = assignments.Count;

            foreach(var a in assignments)
            {
                var daysUntil = (a.DueDate - now).Days;
                var className = context.Classes.Where(c => c.Id == a.ClassId).Select(c => c.Name).FirstOrDefault() ?? "Course";

                viewModel.UpcomingDeadlines.Add(new DeadlineViewModel
                {
                    Title = a.Title,
                    CourseName = className,
                    Month = a.DueDate.ToString("MMM"),
                    Day = a.DueDate.ToString("dd"),
                    DueInText = $"Due in {daysUntil} days",
                    IsDanger = daysUntil <= 2,
                    IsWarning = daysUntil > 2 && daysUntil <= 5
                });
            }

            var notifications = context.Notifications
                .Where(n => n.UserId == studentId)
                .OrderByDescending(n => n.CreatedAt)
                .Take(5)
                .ToList();

            foreach(var n in notifications)
            {
                var timeSpan = now - n.CreatedAt;
                string timeAgo = timeSpan.TotalHours < 24 ? $"{(int)timeSpan.TotalHours} hours ago" : $"{(int)timeSpan.TotalDays} days ago";
                
                viewModel.RecentNotifications.Add(new NotificationViewModel
                {
                    Content = n.Message ?? n.Title,
                    TimeAgo = timeAgo,
                    IconClass = n.Type == "Grade" ? "fa-check" : (n.Type == "System" ? "fa-bell" : "fa-info"),
                    IconColorClass = n.Type == "Grade" ? "color: var(--success);" : ""
                });
            }

            return View(viewModel);
        }
    }
}
