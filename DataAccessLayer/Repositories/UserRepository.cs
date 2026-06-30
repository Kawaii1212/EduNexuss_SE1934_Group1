using System.Collections.Generic;
using DataAccessLayer.DAOs;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public class UserRepository : IUserRepository
{
    public void AddUser(User user) => UserDAO.Instance.Add(user);

    public void DeleteUser(User user) => UserDAO.Instance.Delete(user);

    public IEnumerable<User> GetAllUsers() => UserDAO.Instance.GetAll();

    public User? GetUserById(object id) => UserDAO.Instance.GetById(id);

    public void UpdateUser(User user) => UserDAO.Instance.Update(user);

    public User? GetUserByEmail(string email) => UserDAO.Instance.GetUserByEmail(email);
}
