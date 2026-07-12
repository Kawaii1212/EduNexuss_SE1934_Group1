using System.Collections.Generic;
using System.Linq;
using EduNexus.Models;

namespace EduNexus.DAOs
{
    public class AuditLogDAO : BaseDAO<AuditLog>
    {
        private static AuditLogDAO? instance = null;
        private static readonly object instanceLock = new object();

        private AuditLogDAO() { }

        public static new AuditLogDAO Instance
        {
            get
            {
                lock (instanceLock)
                {
                    if (instance == null)
                    {
                        instance = new AuditLogDAO();
                    }
                    return instance;
                }
            }
        }

        public List<AuditLog> GetRecentLogs(int limit = 100)
        {
            using var context = GetContext();
            return context.AuditLogs.OrderByDescending(a => a.CreatedAt).Take(limit).ToList();
        }
    }
}
