using System.Collections.Generic;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public interface IProgressRepository
{
    IEnumerable<Enrollment> GetEnrollmentsByStudent(long studentId);
    IEnumerable<LearningProgress> GetLearningProgressesByStudent(long studentId);
}
