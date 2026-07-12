using System.Collections.Generic;
using EduNexus.Models;

namespace EduNexus.Services
{
    public interface IAuditLogService
    {
        List<AuditLog> GetRecentAuditLogs(int limit = 100);
        List<LoginHistory> GetRecentLoginHistories(int limit = 100);
    }
}
