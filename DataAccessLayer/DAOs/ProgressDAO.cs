using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using DataAccessLayer.Models;

namespace DataAccessLayer.DAOs;

public class ProgressDAO
{
    private static ProgressDAO? instance = null;
    private static readonly object instanceLock = new object();

    private ProgressDAO() { }

    public static ProgressDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                {
                    instance = new ProgressDAO();
                }
                return instance;
            }
        }
    }

    protected EduNexusNew02Context GetContext()
    {
        var optionsBuilder = new DbContextOptionsBuilder<EduNexusNew02Context>();
        optionsBuilder.UseSqlServer(AppConfiguration.ConnectionString);
        return new EduNexusNew02Context(optionsBuilder.Options);
    }

    public IEnumerable<Enrollment> GetEnrollmentsByStudent(long studentId)
    {
        using var context = GetContext();
        return context.Enrollments
            .Include(e => e.Course)
            .Include(e => e.Class)
                .ThenInclude(c => c.Course)
            .Where(e => e.StudentId == studentId)
            .ToList();
    }

    public IEnumerable<LearningProgress> GetLearningProgressesByStudent(long studentId)
    {
        using var context = GetContext();
        return context.LearningProgresses
            .Where(lp => lp.StudentId == studentId)
            .ToList();
    }
}
