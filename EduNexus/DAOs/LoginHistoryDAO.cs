using System.Collections.Generic;
using System.Linq;
using EduNexus.Models;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.DAOs
{
    public class LoginHistoryDAO : BaseDAO<LoginHistory>
    {
        private static LoginHistoryDAO? instance = null;
        private static readonly object instanceLock = new object();

        private LoginHistoryDAO() { }

        public static new LoginHistoryDAO Instance
        {
            get
            {
                lock (instanceLock)
                {
                    if (instance == null)
                    {
                        instance = new LoginHistoryDAO();
                    }
                    return instance;
                }
            }
        }

        public List<LoginHistory> GetRecentLoginHistories(int limit = 100)
        {
            using var context = GetContext();
            return context.LoginHistories
                .Include(h => h.User)
                .OrderByDescending(h => h.LoginAt)
                .Take(limit)
                .ToList();
        }
    }
}
