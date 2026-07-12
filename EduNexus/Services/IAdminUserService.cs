using System.Collections.Generic;
using EduNexus.ViewModels;

namespace EduNexus.Services;

public interface IAdminUserService
{
    AdminUserListViewModel GetUserList(string? role, string? status, string? search);
    AdminUserDetailViewModel? GetUserDetail(long id);
    bool UpdateUserStatus(long id, string status);
    bool SoftDeleteUser(long id);
}
