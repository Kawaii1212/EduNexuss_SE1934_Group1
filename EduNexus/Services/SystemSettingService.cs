using System;
using System.Collections.Generic;
using EduNexus.DAOs;
using EduNexus.Models;

namespace EduNexus.Services
{
    public class SystemSettingService : ISystemSettingService
    {
        public List<SystemSetting> GetAllSettings()
        {
            return SystemSettingDAO.Instance.GetAllSettings();
        }

        public SystemSetting? GetSettingByKey(string key)
        {
            return SystemSettingDAO.Instance.GetSettingByKey(key);
        }

        public void UpdateSetting(SystemSetting setting)
        {
            var existing = SystemSettingDAO.Instance.GetSettingByKey(setting.SettingKey);
            if (existing != null)
            {
                existing.SettingValue = setting.SettingValue;
                existing.DisplayOrder = setting.DisplayOrder;
                existing.Description = setting.Description;
                existing.IsActive = setting.IsActive;
                existing.UpdatedAt = DateTime.UtcNow;
                SystemSettingDAO.Instance.Update(existing);
            }
        }

        public void ToggleSettingStatus(string key, bool isActive)
        {
            var existing = SystemSettingDAO.Instance.GetSettingByKey(key);
            if (existing != null)
            {
                existing.IsActive = isActive;
                existing.UpdatedAt = DateTime.UtcNow;
                SystemSettingDAO.Instance.Update(existing);
            }
        }
    }
}
