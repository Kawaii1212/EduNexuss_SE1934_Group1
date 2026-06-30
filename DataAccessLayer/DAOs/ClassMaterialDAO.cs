using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using DataAccessLayer.Models;

namespace DataAccessLayer.DAOs;

public class ClassMaterialDAO : BaseDAO<ClassMaterial>
{
    private static ClassMaterialDAO? instance = null;
    private static readonly object instanceLock = new object();

    private ClassMaterialDAO() { }

    public static new ClassMaterialDAO Instance
    {
        get
        {
            lock (instanceLock)
            {
                if (instance == null)
                {
                    instance = new ClassMaterialDAO();
                }
                return instance;
            }
        }
    }

    public IEnumerable<ClassMaterial> GetMaterialsByStudentId(long studentId)
    {
        using var context = GetContext();
        // Get all materials for classes where the student is enrolled
        var materials = from enrollment in context.Enrollments
                        join cls in context.Classes on enrollment.ClassId equals cls.Id
                        join material in context.ClassMaterials on cls.Id equals material.ClassId
                        where enrollment.StudentId == studentId
                        select material;
                        
        return materials.ToList();
    }
}
