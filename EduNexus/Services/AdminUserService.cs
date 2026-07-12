using System;
using System.Linq;
using EduNexus.Models;
using EduNexus.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Services;

public class AdminUserService : IAdminUserService
{
    private readonly EduNexusContext _context;

    public AdminUserService(EduNexusContext context)
    {
        _context = context;
    }

    public AdminUserListViewModel GetUserList(string? role, string? status, string? search)
    {
        var query = _context.Users.AsNoTracking().Where(u => u.DeletedAt == null);

        if (!string.IsNullOrWhiteSpace(role))
            query = query.Where(u => u.Role == role);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(u => u.Status == status);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                u.FullName.ToLower().Contains(term) ||
                u.Email.ToLower().Contains(term));
        }

        var users = query
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new AdminUserListItemViewModel
            {
                Id = u.Id,
                FullName = u.FullName,
                Email = u.Email,
                Role = u.Role,
                Status = u.Status,
                CreatedAt = u.CreatedAt
            })
            .ToList();

        return new AdminUserListViewModel
        {
            RoleFilter = role,
            StatusFilter = status,
            Search = search,
            Users = users
        };
    }

    public AdminUserDetailViewModel? GetUserDetail(long id)
    {
        var user = _context.Users.AsNoTracking().FirstOrDefault(u => u.Id == id && u.DeletedAt == null);
        if (user == null) return null;

        var logins = _context.LoginHistories.AsNoTracking()
            .Where(l => l.UserId == id)
            .OrderByDescending(l => l.LoginAt)
            .Take(20)
            .Select(l => new AdminLoginHistoryItemViewModel
            {
                LoginAt = l.LoginAt,
                Status = l.Status,
                IpAddress = l.IpAddress
            })
            .ToList();

        var groups = _context.CourseGroupMembers.AsNoTracking()
            .Include(m => m.CourseGroup)
            .Where(m => m.UserId == id)
            .Select(m => new AdminCourseGroupMembershipViewModel
            {
                GroupId = m.CourseGroupId,
                GroupName = m.CourseGroup.Name,
                RoleInGroup = m.RoleInGroup
            })
            .ToList();

        return new AdminUserDetailViewModel
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role,
            Status = user.Status,
            Phone = user.Phone,
            AvatarUrl = user.AvatarUrl,
            FailedLoginCount = user.FailedLoginCount,
            LockedUntil = user.LockedUntil,
            CreatedAt = user.CreatedAt,
            UpdatedAt = user.UpdatedAt,
            LoginHistories = logins,
            GroupMemberships = groups
        };
    }

    public bool UpdateUserStatus(long id, string status)
    {
        var user = _context.Users.FirstOrDefault(u => u.Id == id && u.DeletedAt == null);
        if (user == null) return false;

        user.Status = status;
        if (status == "LOCKED")
            user.LockedUntil = DateTimeOffset.UtcNow.AddDays(30);
        else
            user.LockedUntil = null;

        user.UpdatedAt = DateTimeOffset.UtcNow;
        _context.SaveChanges();
        return true;
    }

    public bool SoftDeleteUser(long id)
    {
        var user = _context.Users.FirstOrDefault(u => u.Id == id && u.DeletedAt == null);
        if (user == null || user.Role == "ADMIN") return false;

        user.DeletedAt = DateTimeOffset.UtcNow;
        user.Status = "INACTIVE";
        user.UpdatedAt = DateTimeOffset.UtcNow;
        _context.SaveChanges();
        return true;
    }
}
