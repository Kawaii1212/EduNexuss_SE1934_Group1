using Microsoft.AspNetCore.Mvc;
using EduNexus.Services;
using EduNexus.Models;
using EduNexus.ViewModels;
using System.Linq;
using System.Security.Claims;

namespace EduNexus.Controllers
{
    public class AdminController : Controller
    {
        private readonly ISystemSettingService _systemSettingService;
        private readonly IAuditLogService _auditLogService;
        private readonly IAdminUserService _adminUserService;
        private readonly ICourseGroupService _courseGroupService;
        private readonly EduNexusContext _context;

        public AdminController(
            ISystemSettingService systemSettingService,
            IAuditLogService auditLogService,
            IAdminUserService adminUserService,
            ICourseGroupService courseGroupService,
            EduNexusContext context)
        {
            _systemSettingService = systemSettingService;
            _auditLogService = auditLogService;
            _adminUserService = adminUserService;
            _courseGroupService = courseGroupService;
            _context = context;
        }

        private long GetAdminId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (claim != null) return long.Parse(claim.Value);
            return _context.Users.FirstOrDefault(u => u.Role == "ADMIN")?.Id ?? 1;
        }

        public IActionResult Dashboard()
        {
            ViewData["ActiveMenu"] = "Dashboard";

            ViewBag.TotalUsers = _context.Users.Count(u => u.DeletedAt == null);
            ViewBag.TotalCourses = _context.Courses.Count(c => c.DeletedAt == null);
            ViewBag.TotalClasses = _context.Classes.Count();
            ViewBag.ActiveSettings = _context.SystemSettings.Count(s => s.IsActive == true);
            ViewBag.TotalCourseGroups = _context.CourseGroups.Count();

            return View();
        }

        // SCR-07: User List
        public IActionResult UserList(string? role, string? status, string? search)
        {
            ViewData["ActiveMenu"] = "Users";
            var vm = _adminUserService.GetUserList(role, status, search);
            vm.Users = vm.Users;
            return View(vm);
        }

        // User Detail
        public IActionResult UserDetail(long id)
        {
            ViewData["ActiveMenu"] = "Users";
            var vm = _adminUserService.GetUserDetail(id);
            if (vm == null) return NotFound();

            vm.SuccessMessage = TempData["SuccessMessage"]?.ToString();
            vm.ErrorMessage = TempData["ErrorMessage"]?.ToString();
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult UpdateUserStatus(long id, string status)
        {
            if (!_adminUserService.UpdateUserStatus(id, status))
            {
                TempData["ErrorMessage"] = "Không thể cập nhật trạng thái user.";
                return RedirectToAction(nameof(UserDetail), new { id });
            }

            TempData["SuccessMessage"] = $"Đã cập nhật trạng thái thành {status}.";
            return RedirectToAction(nameof(UserDetail), new { id });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult DeleteUser(long id)
        {
            if (!_adminUserService.SoftDeleteUser(id))
            {
                TempData["ErrorMessage"] = "Không thể xóa user (có thể là tài khoản Admin).";
                return RedirectToAction(nameof(UserDetail), new { id });
            }

            TempData["SuccessMessage"] = "Đã vô hiệu hóa tài khoản.";
            return RedirectToAction(nameof(UserList));
        }

        // Course Group List
        public IActionResult CourseGroupList(string? status, string? search)
        {
            ViewData["ActiveMenu"] = "CourseGroups";
            var vm = _courseGroupService.GetGroupList(status, search);
            vm.SuccessMessage = TempData["SuccessMessage"]?.ToString();
            vm.ErrorMessage = TempData["ErrorMessage"]?.ToString();
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CreateCourseGroup(CreateCourseGroupForm form)
        {
            if (!ModelState.IsValid)
            {
                TempData["ErrorMessage"] = "Vui lòng nhập tên nhóm khóa học.";
                return RedirectToAction(nameof(CourseGroupList));
            }

            try
            {
                var id = _courseGroupService.CreateGroup(form, GetAdminId());
                TempData["SuccessMessage"] = "Đã tạo nhóm khóa học.";
                return RedirectToAction(nameof(CourseGroupDetail), new { id });
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
                return RedirectToAction(nameof(CourseGroupList));
            }
        }

        // Course Group Detail
        public IActionResult CourseGroupDetail(long id)
        {
            ViewData["ActiveMenu"] = "CourseGroups";
            var vm = _courseGroupService.GetGroupDetail(id);
            if (vm == null) return NotFound();

            vm.SuccessMessage = TempData["SuccessMessage"]?.ToString();
            vm.ErrorMessage = TempData["ErrorMessage"]?.ToString();
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult UpdateCourseGroup(UpdateCourseGroupForm form)
        {
            try
            {
                if (!ModelState.IsValid || !_courseGroupService.UpdateGroup(form))
                {
                    TempData["ErrorMessage"] = "Không thể cập nhật nhóm khóa học.";
                    return RedirectToAction(nameof(CourseGroupDetail), new { id = form.Id });
                }

                TempData["SuccessMessage"] = "Đã cập nhật nhóm khóa học.";
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
            }

            return RedirectToAction(nameof(CourseGroupDetail), new { id = form.Id });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult AssignGroupMember(AssignGroupMemberForm form)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    TempData["ErrorMessage"] = "Vui lòng chọn user và vai trò.";
                    return RedirectToAction(nameof(CourseGroupDetail), new { id = form.CourseGroupId });
                }

                _courseGroupService.AssignMember(form, GetAdminId());
                TempData["SuccessMessage"] = "Đã gán thành viên vào nhóm.";
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
            }

            return RedirectToAction(nameof(CourseGroupDetail), new { id = form.CourseGroupId });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RemoveGroupMember(long memberId, long courseGroupId)
        {
            if (!_courseGroupService.RemoveMember(memberId))
                TempData["ErrorMessage"] = "Không thể gỡ thành viên.";
            else
                TempData["SuccessMessage"] = "Đã gỡ thành viên khỏi nhóm.";

            return RedirectToAction(nameof(CourseGroupDetail), new { id = courseGroupId });
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
            if (setting == null) return NotFound();
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
            if (string.IsNullOrEmpty(request.Key)) return BadRequest();
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
