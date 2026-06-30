using System.Linq;
using DataAccessLayer.Models;

namespace DataAccessLayer.DAOs;

public class UserOauthIdentityDAO : BaseDAO<UserOauthIdentity>
{
    private static UserOauthIdentityDAO? instance = null;
    private static readonly object instanceLock = new object();

    private UserOauthIdentityDAO() { }

    public static new UserOauthIdentityDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                {
                    instance = new UserOauthIdentityDAO();
                }
                return instance;
            }
        }
    }

    public UserOauthIdentity? GetByProviderAndProviderId(string provider, string providerId)
    {
        using var context = GetContext();
        return context.UserOauthIdentities
            .FirstOrDefault(uoi => uoi.Provider == provider && uoi.ProviderUserId == providerId);
    }
}
