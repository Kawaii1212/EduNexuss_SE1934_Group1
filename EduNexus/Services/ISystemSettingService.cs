using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Services
{
    public interface ISystemSettingService
    {
        List<SystemSetting> GetAllSettings();
        SystemSetting? GetSettingByKey(string key);
        void UpdateSetting(SystemSetting setting);
        void ToggleSettingStatus(string key, bool isActive);
    }
}
