using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;
using EduNexus.Models;
using System.Linq;

namespace EduNexus.Controllers
{
    public class AdminController : Controller
    {
        private readonly ISystemSettingService _systemSettingService;
        private readonly IAuditLogService _auditLogService;
        private readonly EduNexusContext _context;

        public AdminController(ISystemSettingService systemSettingService, IAuditLogService auditLogService, EduNexusContext context)
        {
            _systemSettingService = systemSettingService;
            _auditLogService = auditLogService;
            _context = context;
        }

        public IActionResult Dashboard()
        {
            ViewData["ActiveMenu"] = "Dashboard";
            
            // Basic stats for the dashboard
            var totalUsers = _context.Users.Count();
            var totalCourses = _context.Courses.Count();
            var totalClasses = _context.Classes.Count();
            var activeSettings = _context.SystemSettings.Count(s => s.IsActive == true);

            ViewBag.TotalUsers = totalUsers;
            ViewBag.TotalCourses = totalCourses;
            ViewBag.TotalClasses = totalClasses;
            ViewBag.ActiveSettings = activeSettings;

            return View();
        }

        public IActionResult SystemConfig()
        {
            ViewData["ActiveMenu"] = "SystemConfig";
            var settings = _systemSettingService.GetAllSettings();
            return View(settings);
        }

        public IActionResult SystemConfigDetail(string key)
        {
            ViewData["ActiveMenu"] = "SystemConfig";
            var setting = _systemSettingService.GetSettingByKey(key);
            if (setting == null)
            {
                return NotFound();
            }
            return View(setting);
        }

        [HttpPost]
        public IActionResult UpdateSystemConfig(SystemSetting model)
        {
            _systemSettingService.UpdateSetting(model);
            return RedirectToAction("SystemConfig");
        }

        [HttpPost]
        public IActionResult ToggleSystemConfig([FromBody] ToggleSettingRequest request)
        {
            if (string.IsNullOrEmpty(request.Key))
            {
                return BadRequest();
            }
            _systemSettingService.ToggleSettingStatus(request.Key, request.IsActive);
            return Ok(new { success = true });
        }

        public IActionResult AuditLog()
        {
            ViewData["ActiveMenu"] = "AuditLog";
            ViewBag.AuditLogs = _auditLogService.GetRecentAuditLogs(100);
            ViewBag.LoginHistories = _auditLogService.GetRecentLoginHistories(100);
            return View();
        }
    }

    public class ToggleSettingRequest
    {
        public string Key { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
}
