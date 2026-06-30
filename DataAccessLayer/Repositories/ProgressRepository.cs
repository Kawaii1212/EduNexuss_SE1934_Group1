using System.Collections.Generic;
using DataAccessLayer.DAOs;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public class ProgressRepository : IProgressRepository
{
    public IEnumerable<Enrollment> GetEnrollmentsByStudent(long studentId)
    {
        return ProgressDAO.Instance.GetEnrollmentsByStudent(studentId);
    }

    public IEnumerable<LearningProgress> GetLearningProgressesByStudent(long studentId)
    {
        return ProgressDAO.Instance.GetLearningProgressesByStudent(studentId);
    }
}
