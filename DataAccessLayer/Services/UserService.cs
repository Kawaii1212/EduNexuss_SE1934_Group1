using System.Collections.Generic;
using DataAccessLayer.Models;
using DataAccessLayer.Repositories;

namespace DataAccessLayer.Services;

public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly IUserOauthIdentityRepository _oauthRepository;

    public UserService(IUserRepository userRepository, IUserOauthIdentityRepository oauthRepository)
    {
        _userRepository = userRepository;
        _oauthRepository = oauthRepository;
    }

    public void AddUser(User user) => _userRepository.AddUser(user);

    public void DeleteUser(User user) => _userRepository.DeleteUser(user);

    public IEnumerable<User> GetAllUsers() => _userRepository.GetAllUsers();

    public User? GetUserById(object id) => _userRepository.GetUserById(id);

    public void UpdateUser(User user) => _userRepository.UpdateUser(user);

    public User? GetUserByEmail(string email) => _userRepository.GetUserByEmail(email);

    public User HandleGoogleLogin(string email, string name, string providerId)
    {
        var oauthIdentity = _oauthRepository.GetByProviderAndProviderId("Google", providerId);
        
        if (oauthIdentity != null && oauthIdentity.User != null)
        {
            return oauthIdentity.User;
        }

        var existingUser = _userRepository.GetUserByEmail(email);
        if (existingUser != null)
        {
            // Link account
            var newOauth = new UserOauthIdentity
            {
                UserId = existingUser.Id,
                Provider = "Google",
                ProviderUserId = providerId,
                CreatedAt = System.DateTimeOffset.UtcNow
            };
            _oauthRepository.Add(newOauth);
            return existingUser;
        }

        // Create new user
        var newUser = new User
        {
            Email = email,
            FullName = name,
            Role = "STUDENT",
            Status = "ACTIVE",
            CreatedAt = System.DateTimeOffset.UtcNow,
            UpdatedAt = System.DateTimeOffset.UtcNow
        };
        _userRepository.AddUser(newUser);

        var oauth = new UserOauthIdentity
        {
            UserId = newUser.Id,
            Provider = "Google",
            ProviderUserId = providerId,
            CreatedAt = System.DateTimeOffset.UtcNow
        };
        _oauthRepository.Add(oauth);

        return newUser;
    }
}
