using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using DataAccessLayer.Services;
using EduNexus.Models;

namespace EduNexus.Controllers
{
    public class AuthController : Controller
    {
        private readonly IUserService _userService;

        public AuthController(IUserService userService)
        {
            _userService = userService;
        }

        public IActionResult SignUp()
        {
            return View();
        }

        [HttpGet]
        public IActionResult SignIn()
        {
            // If already authenticated, redirect based on role
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                if (User.IsInRole("Student"))
                {
                    return RedirectToAction("StudentLibrary", "Home");
                }
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SignIn(LoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = _userService.GetUserByEmail(model.Email);
            
            // TODO: In a real application, you should hash model.Password and compare with user.PasswordHash
            // For now, doing a plain text comparison or you can adapt it to your hashing logic
            if (user == null || user.PasswordHash != model.Password)
            {
                ModelState.AddModelError(string.Empty, "Invalid email or password.");
                return View(model);
            }

            if (user.Status != "Active" && user.Status != "active")
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
                return RedirectToAction("StudentLibrary", "Home");
            }
            
            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public new async Task<IActionResult> SignOut()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("SignIn", "Auth");
        }
    }
}
