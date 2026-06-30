using DataAccessLayer.DAOs;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public class UserOauthIdentityRepository : IUserOauthIdentityRepository
{
    public UserOauthIdentity? GetByProviderAndProviderId(string provider, string providerId)
    {
        return UserOauthIdentityDAO.Instance.GetByProviderAndProviderId(provider, providerId);
    }

    public void Add(UserOauthIdentity entity)
    {
        UserOauthIdentityDAO.Instance.Add(entity);
    }
}
