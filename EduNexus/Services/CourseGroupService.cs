using System;
using System.Linq;
using EduNexus.Models;
using EduNexus.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Services;

public class CourseGroupService : ICourseGroupService
{
    private readonly EduNexusContext _context;

    public CourseGroupService(EduNexusContext context)
    {
        _context = context;
    }

    public AdminCourseGroupListViewModel GetGroupList(string? status, string? search)
    {
        var query = _context.CourseGroups.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(g => g.Status == status);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(g => g.Name.ToLower().Contains(term));
        }

        var groups = query
            .OrderByDescending(g => g.CreatedAt)
            .Select(g => new AdminCourseGroupListItemViewModel
            {
                Id = g.Id,
                Name = g.Name,
                Description = g.Description,
                Status = g.Status,
                CourseCount = g.Courses.Count(c => c.DeletedAt == null),
                MemberCount = g.CourseGroupMembers.Count,
                CreatedAt = g.CreatedAt
            })
            .ToList();

        return new AdminCourseGroupListViewModel
        {
            StatusFilter = status,
            Search = search,
            Groups = groups
        };
    }

    public long CreateGroup(CreateCourseGroupForm form, long createdBy)
    {
        if (_context.CourseGroups.Any(g => g.Name == form.Name.Trim()))
            throw new InvalidOperationException("Tên nhóm khóa học đã tồn tại.");

        var group = new CourseGroup
        {
            Name = form.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(form.Description) ? null : form.Description.Trim(),
            Status = "ACTIVE",
            CreatedBy = createdBy,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        _context.CourseGroups.Add(group);
        _context.SaveChanges();
        return group.Id;
    }

    public AdminCourseGroupDetailViewModel? GetGroupDetail(long id)
    {
        var group = _context.CourseGroups.AsNoTracking()
            .Include(g => g.CourseGroupMembers)
                .ThenInclude(m => m.User)
            .Include(g => g.Courses)
            .FirstOrDefault(g => g.Id == id);

        if (group == null) return null;

        var assignedUserIds = group.CourseGroupMembers.Select(m => m.UserId).ToHashSet();

        var courseManagers = _context.Users.AsNoTracking()
            .Where(u => u.DeletedAt == null && u.Status == "ACTIVE" && u.Role == "COURSE_MANAGER" && !assignedUserIds.Contains(u.Id))
            .OrderBy(u => u.FullName)
            .Select(u => new AdminUserOptionViewModel { Id = u.Id, FullName = u.FullName, Email = u.Email })
            .ToList();

        var smes = _context.Users.AsNoTracking()
            .Where(u => u.DeletedAt == null && u.Status == "ACTIVE" && u.Role == "SME" && !assignedUserIds.Contains(u.Id))
            .OrderBy(u => u.FullName)
            .Select(u => new AdminUserOptionViewModel { Id = u.Id, FullName = u.FullName, Email = u.Email })
            .ToList();

        return new AdminCourseGroupDetailViewModel
        {
            Id = group.Id,
            Name = group.Name,
            Description = group.Description,
            Status = group.Status,
            CourseCount = group.Courses.Count(c => c.DeletedAt == null),
            CreatedAt = group.CreatedAt,
            Members = group.CourseGroupMembers
                .OrderBy(m => m.RoleInGroup)
                .ThenBy(m => m.User.FullName)
                .Select(m => new AdminGroupMemberViewModel
                {
                    MemberId = m.Id,
                    UserId = m.UserId,
                    FullName = m.User.FullName,
                    Email = m.User.Email,
                    RoleInGroup = m.RoleInGroup,
                    AssignedAt = m.AssignedAt
                }).ToList(),
            AvailableCourseManagers = courseManagers,
            AvailableSmes = smes,
            AssignForm = new AssignGroupMemberForm { CourseGroupId = group.Id }
        };
    }

    public bool UpdateGroup(UpdateCourseGroupForm form)
    {
        var group = _context.CourseGroups.FirstOrDefault(g => g.Id == form.Id);
        if (group == null) return false;

        var name = form.Name.Trim();
        if (_context.CourseGroups.Any(g => g.Id != form.Id && g.Name == name))
            throw new InvalidOperationException("Tên nhóm khóa học đã tồn tại.");

        group.Name = name;
        group.Description = string.IsNullOrWhiteSpace(form.Description) ? null : form.Description.Trim();
        group.Status = form.Status;
        group.UpdatedAt = DateTimeOffset.UtcNow;
        _context.SaveChanges();
        return true;
    }

    public bool AssignMember(AssignGroupMemberForm form, long assignedBy)
    {
        var user = _context.Users.FirstOrDefault(u => u.Id == form.UserId && u.DeletedAt == null);
        if (user == null) return false;

        var expectedRole = form.RoleInGroup == "COURSE_MANAGER" ? "COURSE_MANAGER" : "SME";
        if (user.Role != expectedRole)
            throw new InvalidOperationException($"User phải có role {expectedRole}.");

        if (_context.CourseGroupMembers.Any(m =>
                m.CourseGroupId == form.CourseGroupId &&
                m.UserId == form.UserId &&
                m.RoleInGroup == form.RoleInGroup))
            throw new InvalidOperationException("User đã được gán vào nhóm với vai trò này.");

        _context.CourseGroupMembers.Add(new CourseGroupMember
        {
            CourseGroupId = form.CourseGroupId,
            UserId = form.UserId,
            RoleInGroup = form.RoleInGroup,
            AssignedBy = assignedBy,
            AssignedAt = DateTimeOffset.UtcNow
        });
        _context.SaveChanges();
        return true;
    }

    public bool RemoveMember(long memberId)
    {
        var member = _context.CourseGroupMembers.FirstOrDefault(m => m.Id == memberId);
        if (member == null) return false;

        _context.CourseGroupMembers.Remove(member);
        _context.SaveChanges();
        return true;
    }
}
