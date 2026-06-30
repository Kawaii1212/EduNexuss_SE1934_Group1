using System.Collections.Generic;
using DataAccessLayer.Models;

namespace DataAccessLayer.Services;

public interface IProgressService
{
    IEnumerable<Enrollment> GetEnrollmentsByStudent(long studentId);
    IEnumerable<LearningProgress> GetLearningProgressesByStudent(long studentId);
}
