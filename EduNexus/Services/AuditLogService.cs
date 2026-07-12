using System.Collections.Generic;
using EduNexus.DAOs;
using EduNexus.Models;

namespace EduNexus.Services
{
    public class AuditLogService : IAuditLogService
    {
        public List<AuditLog> GetRecentAuditLogs(int limit = 100)
        {
            return AuditLogDAO.Instance.GetRecentLogs(limit);
        }

        public List<LoginHistory> GetRecentLoginHistories(int limit = 100)
        {
            return LoginHistoryDAO.Instance.GetRecentLoginHistories(limit);
        }
    }
}
