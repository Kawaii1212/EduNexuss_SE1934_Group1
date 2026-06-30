using System.Collections.Generic;
using DataAccessLayer.Models;

namespace DataAccessLayer.Services;

public interface IUserService
{
    IEnumerable<User> GetAllUsers();
    User? GetUserById(object id);
    void AddUser(User user);
    void UpdateUser(User user);
    void DeleteUser(User user);
    User? GetUserByEmail(string email);
}
