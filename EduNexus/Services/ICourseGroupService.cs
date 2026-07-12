using EduNexus.ViewModels;

namespace EduNexus.Services;

public interface ICourseGroupService
{
    AdminCourseGroupListViewModel GetGroupList(string? status, string? search);
    long CreateGroup(CreateCourseGroupForm form, long createdBy);
    AdminCourseGroupDetailViewModel? GetGroupDetail(long id);
    bool UpdateGroup(UpdateCourseGroupForm form);
    bool AssignMember(AssignGroupMemberForm form, long assignedBy);
    bool RemoveMember(long memberId);
}
