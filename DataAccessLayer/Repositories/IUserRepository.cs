using System.Collections.Generic;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public interface IUserRepository
{
    IEnumerable<User> GetAllUsers();
    User? GetUserById(object id);
    void AddUser(User user);
    void UpdateUser(User user);
    void DeleteUser(User user);
    User? GetUserByEmail(string email);
}
