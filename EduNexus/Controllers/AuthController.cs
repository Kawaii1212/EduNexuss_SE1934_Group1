using EduNexus.ViewModels;
using EduNexus.Models;
using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.Extensions.Caching.Memory;

namespace EduNexus.Controllers
{
    public class AuthController : Controller
    {
        private readonly ILogger<AuthController> _logger;
        private readonly IUserService _userService;
        private readonly IMemoryCache _cache;
        private readonly IEmailService _emailService;

        public AuthController(
            ILogger<AuthController> logger, 
            IUserService userService,
            IMemoryCache cache,
            IEmailService emailService)
        {
            _logger = logger;
            _userService = userService;
            _cache = cache;
            _emailService = emailService;
        }

        [HttpGet]
        public IActionResult UserLogin()
        {
            // If already authenticated, redirect based on role
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                if (User.IsInRole("Student") || User.IsInRole("STUDENT"))
                {
                    return RedirectToAction("StudentDashboard", "Student");
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
                return RedirectToAction("StudentDashboard", "Student");
            }
            if (user.Role?.Equals("SME", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("MyCourses", "Course");
            }
            if (user.Role?.Equals("ADMIN", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("Dashboard", "Admin");
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

            return RedirectToAction("UserLogin", "Auth");
        }

        [HttpGet]
        public IActionResult ForgotPassword()
        {
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = _userService.GetUserByEmail(model.Email);
            if (user == null)
            {
                ModelState.AddModelError("Email", "No account found with this email.");
                return View(model);
            }

            if (!string.Equals(user.Status, "ACTIVE", StringComparison.OrdinalIgnoreCase))
            {
                ModelState.AddModelError(string.Empty, "Your account is not active.");
                return View(model);
            }

            Random random = new Random();
            string code = random.Next(100000, 999999).ToString();

            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(5));
            _cache.Set($"ResetCode_{model.Email}", code, cacheOptions);

            string subject = "EduNexus - Password Reset Verification Code";
            string body = $@"
                <div style='font-family: Arial, sans-serif; padding: 20px;'>
                    <h2>Password Reset Request</h2>
                    <p>We received a request to reset your password for your EduNexus account.</p>
                    <p>Your verification code is: <strong><span style='font-size: 24px; color: #5c24ff;'>{code}</span></strong></p>
                    <p>This code will expire in 5 minutes.</p>
                    <p>If you did not request this, please ignore this email.</p>
                </div>";

            await _emailService.SendEmailAsync(model.Email, subject, body);

            TempData["Success"] = "Verification code has been sent to your email.";
            return RedirectToAction("ResetPassword", new { email = model.Email });
        }

        [HttpGet]
        public IActionResult ResetPassword(string email)
        {
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("ForgotPassword");
            }
            
            var model = new ResetPasswordViewModel { Email = email };
            return View(model);
        }

        [HttpPost]
        public IActionResult ResetPassword(ResetPasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            if (!_cache.TryGetValue($"ResetCode_{model.Email}", out string? savedCode))
            {
                ModelState.AddModelError(string.Empty, "Verification code has expired. Please request a new one.");
                return View(model);
            }

            if (model.Code != savedCode)
            {
                ModelState.AddModelError("Code", "Invalid verification code.");
                return View(model);
            }

            var user = _userService.GetUserByEmail(model.Email);
            if (user == null)
            {
                ModelState.AddModelError(string.Empty, "User not found.");
                return View(model);
            }

            user.PasswordHash = model.NewPassword;
            _userService.UpdateUser(user);
            _cache.Remove($"ResetCode_{model.Email}");

            TempData["Success"] = "Password has been successfully reset. Please log in.";
            return RedirectToAction("UserLogin");
        }

        [HttpGet]
        public async Task<IActionResult> SignOut()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("UserLogin", "Auth");
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
                    return RedirectToAction("UserLogin", "Auth");
                }
            }

            var claims = result.Principal.Identities.FirstOrDefault()?.Claims.Select(claim => new
            {
                claim.Issuer,
                claim.OriginalIssuer,
                claim.Type,
                claim.Value
            });

            if (claims == null) return RedirectToAction("UserLogin", "Auth");

            var email = claims.FirstOrDefault(c => c.Type == ClaimTypes.Email)?.Value;
            var name = claims.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value;
            var nameIdentifier = claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(nameIdentifier))
            {
                return RedirectToAction("UserLogin", "Auth");
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
                return RedirectToAction("StudentDashboard", "Student");
            }
            if (user.Role?.Equals("SME", StringComparison.OrdinalIgnoreCase) == true)
            {
                return RedirectToAction("MyCourses", "Course");
            }
            
            return RedirectToAction("Index", "Home");
        }
    }
}
