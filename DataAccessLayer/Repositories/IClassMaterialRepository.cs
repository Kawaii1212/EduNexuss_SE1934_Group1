using System.Collections.Generic;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public interface IClassMaterialRepository
{
    IEnumerable<ClassMaterial> GetAllMaterials();
    ClassMaterial? GetMaterialById(object id);
    void AddMaterial(ClassMaterial material);
    void UpdateMaterial(ClassMaterial material);
    void DeleteMaterial(ClassMaterial material);
    IEnumerable<ClassMaterial> GetMaterialsByStudentId(long studentId);
}
