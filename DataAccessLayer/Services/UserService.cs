using System.Collections.Generic;
using DataAccessLayer.Models;
using DataAccessLayer.Repositories;

namespace DataAccessLayer.Services;

public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;

    public UserService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public void AddUser(User user) => _userRepository.AddUser(user);

    public void DeleteUser(User user) => _userRepository.DeleteUser(user);

    public IEnumerable<User> GetAllUsers() => _userRepository.GetAllUsers();

    public User? GetUserById(object id) => _userRepository.GetUserById(id);

    public void UpdateUser(User user) => _userRepository.UpdateUser(user);

    public User? GetUserByEmail(string email) => _userRepository.GetUserByEmail(email);
}
