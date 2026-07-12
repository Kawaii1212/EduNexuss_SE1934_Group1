using EduNexus.ViewModels;
using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using EduNexus.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Controllers
{
    public class CommonController : Controller
    {
        private readonly ILogger<CommonController> _logger;
        private readonly IClassMaterialService _classMaterialService;
        private readonly IProgressService _progressService;
        private readonly IUserService _userService;
        private readonly EduNexusContext _context;

        public CommonController(
            ILogger<CommonController> logger, 
            IClassMaterialService classMaterialService, 
            IProgressService progressService,
            IUserService userService,
            EduNexusContext context)
        {
            _logger = logger;
            _classMaterialService = classMaterialService;
            _progressService = progressService;
            _userService = userService;
            _context = context;
        }

        public IActionResult CourseList()
        {
            return View();
        }

        [HttpGet]
        public IActionResult UserLogin()
        {
            // If already authenticated, redirect based on role
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                if (User.IsInRole("Student") || User.IsInRole("STUDENT"))
                {
                    return RedirectToAction("StudentDashboard", "Common");
                }
                if (User.IsInRole("SME") || User.IsInRole("sme"))
                {
                    return RedirectToAction("MyCourses", "Course");
                }
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> UserLogin(LoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = _userService.GetUserByEmail(model.Email);
            
            if (user == null || user.PasswordHash != model.Password)
            {
                ModelState.AddModelError(string.Empty, "Invalid email or password.");
                return View(model);
            }

            if (!string.Equals(user.Status, "ACTIVE", StringComparison.OrdinalIgnoreCase))
            {
                ModelState.AddModelError(string.Empty, "Your account is not active.");
                return View(model);
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.FullName ?? ""),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Role, user.Role ?? "")
            };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            var authProperties = new AuthenticationProperties
            {
                IsPersistent = model.RememberMe
            };

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                authProperties);

            if (user.Role?.Equals("Student", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("StudentDashboard", "Common");
            }
            if (user.Role?.Equals("SME", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("MyCourses", "Course");
            }
            
            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult UserRegister()
        {
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public IActionResult UserRegister(RegisterViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }
            if (!model.AgreeTerms)
            {
                ModelState.AddModelError("AgreeTerms", "You must agree to the terms of services.");
                return View(model);
            }

            var existingUser = _userService.GetUserByEmail(model.Email);
            if (existingUser != null)
            {
                ModelState.AddModelError("Email", "Email already exists.");
                return View(model);
            }

            var newUser = new User
            {
                FullName = model.FullName,
                Email = model.Email,
                PasswordHash = model.Password,
                Role = "STUDENT",
                Status = "ACTIVE",
                CreatedAt = System.DateTimeOffset.UtcNow,
                UpdatedAt = System.DateTimeOffset.UtcNow
            };

            _userService.AddUser(newUser);

            return RedirectToAction("UserLogin", "Common");
        }

        [HttpGet]
        public new async Task<IActionResult> SignOut()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("UserLogin", "Common");
        }

        [HttpGet]
        public IActionResult GoogleLogin()
        {
            var properties = new AuthenticationProperties { RedirectUri = Url.Action("GoogleResponse") };
            return Challenge(properties, Microsoft.AspNetCore.Authentication.Google.GoogleDefaults.AuthenticationScheme);
        }

        [HttpGet]
        public async Task<IActionResult> GoogleResponse()
        {
            var result = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            
            if (!result.Succeeded)
            {
                result = await HttpContext.AuthenticateAsync(Microsoft.AspNetCore.Authentication.Google.GoogleDefaults.AuthenticationScheme);
                if (!result.Succeeded)
                {
                    return RedirectToAction("UserLogin", "Common");
                }
            }

            var claims = result.Principal.Identities.FirstOrDefault()?.Claims.Select(claim => new
            {
                claim.Issuer,
                claim.OriginalIssuer,
                claim.Type,
                claim.Value
            });

            if (claims == null) return RedirectToAction("UserLogin", "Common");

            var email = claims.FirstOrDefault(c => c.Type == ClaimTypes.Email)?.Value;
            var name = claims.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value;
            var nameIdentifier = claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(nameIdentifier))
            {
                return RedirectToAction("UserLogin", "Common");
            }

            var user = _userService.HandleGoogleLogin(email, name ?? "Google User", nameIdentifier);

            var appClaims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.FullName ?? ""),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Role, user.Role ?? "")
            };

            var identity = new ClaimsIdentity(appClaims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);

            if (user.Role?.Equals("Student", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("StudentDashboard", "Common");
            }
            if (user.Role?.Equals("SME", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("MyCourses", "Course");
            }
            
            return RedirectToAction("Index", "Home");
        }

        public IActionResult CourseStructure()
        {
            return View();
        }

        public IActionResult PersonalProgress()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");
            
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

        public IActionResult StudentSettings()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");
            
            long studentId = long.Parse(studentIdClaim.Value);
            var user = _userService.GetUserById(studentId);
            if (user == null) return RedirectToAction("UserLogin", "Common");

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
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");

            long studentId = long.Parse(studentIdClaim.Value);
            var user = _userService.GetUserById(studentId);
            if (user == null) return RedirectToAction("UserLogin", "Common");

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
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");

            long studentId = long.Parse(studentIdClaim.Value);
            var user = _userService.GetUserById(studentId);
            if (user == null) return RedirectToAction("UserLogin", "Common");

            // Assuming simple plain text password check based on UserLogin implementation
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
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");
            
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

        public IActionResult AllCourses(string search = "")
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");
            var studentName = User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value ?? "Student";

            var coursesQuery = _context.Courses
                .Include(c => c.CourseGroup)
                .Include(c => c.CreatedByNavigation)
                .Where(c => c.Status == "PUBLISHED" && c.DeletedAt == null);

            if (!string.IsNullOrEmpty(search))
            {
                coursesQuery = coursesQuery.Where(c => c.Title.Contains(search) || c.Description.Contains(search));
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
                    ThumbnailUrl = "", // Set an empty or placeholder thumbnail for now
                    Version = c.Version,
                    CourseGroupName = c.CourseGroup != null ? c.CourseGroup.Name : ""
                }).ToList();

            var model = new AllCoursesViewModel
            {
                SearchQuery = search,
                Courses = courses,
                StudentName = studentName
            };

            return View(model);
        }

        public IActionResult StudentDashboard()
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return RedirectToAction("UserLogin", "Common");
            
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

            foreach (var e in enrollments.Where(e => e.ProgressPercent < 100).OrderByDescending(e => e.CreatedAt))
            {
                var actualCourse = e.Course ?? e.Class?.Course;
                if (actualCourse != null)
                {
                    var courseVm = new OngoingCourseViewModel
                    {
                        CourseId = actualCourse.Id,
                        CourseName = actualCourse.Title,
                        CurrentModuleOrLesson = e.Class != null ? "Enrolled in Class: " + e.Class.Name : "Self-paced Course", 
                        ProgressPercent = e.ProgressPercent,
                        IconClass = "fa-brands " + defaultIcons[i % defaultIcons.Length],
                        IconColorHex = defaultColors[i % defaultColors.Length]
                    };
                    viewModel.OngoingCourses.Add(courseVm);
                    if (viewModel.LastAccessedCourse == null) viewModel.LastAccessedCourse = courseVm;
                    i++;
                }
            }

            using var context = new EduNexusContext(AppConfiguration.DbContextOptions);

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
