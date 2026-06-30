using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public interface IUserOauthIdentityRepository
{
    UserOauthIdentity? GetByProviderAndProviderId(string provider, string providerId);
    void Add(UserOauthIdentity entity);
}
