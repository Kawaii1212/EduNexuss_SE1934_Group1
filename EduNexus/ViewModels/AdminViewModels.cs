using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace EduNexus.ViewModels;

public class AdminUserListViewModel
{
    public string? RoleFilter { get; set; }
    public string? StatusFilter { get; set; }
    public string? Search { get; set; }
    public List<AdminUserListItemViewModel> Users { get; set; } = new();
}

public class AdminUserListItemViewModel
{
    public long Id { get; set; }
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string Role { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
}

public class AdminUserDetailViewModel
{
    public long Id { get; set; }
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string Role { get; set; } = "";
    public string Status { get; set; } = "";
    public string? Phone { get; set; }
    public string? AvatarUrl { get; set; }
    public int FailedLoginCount { get; set; }
    public DateTimeOffset? LockedUntil { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public List<AdminLoginHistoryItemViewModel> LoginHistories { get; set; } = new();
    public List<AdminCourseGroupMembershipViewModel> GroupMemberships { get; set; } = new();
    public string? SuccessMessage { get; set; }
    public string? ErrorMessage { get; set; }
}

public class AdminLoginHistoryItemViewModel
{
    public DateTimeOffset LoginAt { get; set; }
    public string Status { get; set; } = "";
    public string? IpAddress { get; set; }
}

public class AdminCourseGroupMembershipViewModel
{
    public long GroupId { get; set; }
    public string GroupName { get; set; } = "";
    public string RoleInGroup { get; set; } = "";
}

public class AdminCourseGroupListViewModel
{
    public string? StatusFilter { get; set; }
    public string? Search { get; set; }
    public List<AdminCourseGroupListItemViewModel> Groups { get; set; } = new();
    public CreateCourseGroupForm CreateForm { get; set; } = new();
    public string? SuccessMessage { get; set; }
    public string? ErrorMessage { get; set; }
}

public class AdminCourseGroupListItemViewModel
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public string Status { get; set; } = "";
    public int CourseCount { get; set; }
    public int MemberCount { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

public class CreateCourseGroupForm
{
    [Required(ErrorMessage = "Tên nhóm khóa học là bắt buộc")]
    [MaxLength(150)]
    public string Name { get; set; } = "";

    public string? Description { get; set; }
}

public class AdminCourseGroupDetailViewModel
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public string Status { get; set; } = "";
    public int CourseCount { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public List<AdminGroupMemberViewModel> Members { get; set; } = new();
    public List<AdminUserOptionViewModel> AvailableCourseManagers { get; set; } = new();
    public List<AdminUserOptionViewModel> AvailableSmes { get; set; } = new();
    public AssignGroupMemberForm AssignForm { get; set; } = new();
    public string? SuccessMessage { get; set; }
    public string? ErrorMessage { get; set; }
}

public class AdminGroupMemberViewModel
{
    public long MemberId { get; set; }
    public long UserId { get; set; }
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string RoleInGroup { get; set; } = "";
    public DateTimeOffset AssignedAt { get; set; }
}

public class AdminUserOptionViewModel
{
    public long Id { get; set; }
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
}

public class AssignGroupMemberForm
{
    public long CourseGroupId { get; set; }

    [Required]
    public long UserId { get; set; }

    [Required]
    public string RoleInGroup { get; set; } = "SME";
}

public class UpdateCourseGroupForm
{
    public long Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = "";

    public string? Description { get; set; }

    [Required]
    public string Status { get; set; } = "ACTIVE";
}
