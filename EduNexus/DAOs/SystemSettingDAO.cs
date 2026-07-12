using System.Collections.Generic;
using System.Linq;
using EduNexus.Models;

namespace EduNexus.DAOs
{
    public class SystemSettingDAO : BaseDAO<SystemSetting>
    {
        private static SystemSettingDAO? instance = null;
        private static readonly object instanceLock = new object();

        private SystemSettingDAO() { }

        public static new SystemSettingDAO Instance
        {
            get
            {
                lock (instanceLock)
                {
                    if (instance == null)
                    {
                        instance = new SystemSettingDAO();
                    }
                    return instance;
                }
            }
        }

        public List<SystemSetting> GetAllSettings()
        {
            using var context = GetContext();
            return context.SystemSettings.OrderBy(s => s.DisplayOrder).ToList();
        }

        public SystemSetting? GetSettingByKey(string key)
        {
            using var context = GetContext();
            return context.SystemSettings.FirstOrDefault(s => s.SettingKey == key);
        }
    }
}
