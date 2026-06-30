using DataAccessLayer.Models;

namespace DataAccessLayer.DAOs;

public class UserDAO : BaseDAO<User>
{
    private static UserDAO? instance = null;
    private static readonly object instanceLock = new object();

    private UserDAO() { }

    public static new UserDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                {
                    instance = new UserDAO();
                }
                return instance;
            }
        }
    }

    public User? GetUserByEmail(string email)
    {
        using var context = GetContext();
        return context.Users.FirstOrDefault(u => u.Email == email);
    }
}
