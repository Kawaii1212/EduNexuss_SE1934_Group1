using System.Collections.Generic;
using DataAccessLayer.DAOs;
using DataAccessLayer.Models;

namespace DataAccessLayer.Repositories;

public class ClassMaterialRepository : IClassMaterialRepository
{
    public void AddMaterial(ClassMaterial material) => ClassMaterialDAO.Instance.Add(material);

    public void DeleteMaterial(ClassMaterial material) => ClassMaterialDAO.Instance.Delete(material);

    public IEnumerable<ClassMaterial> GetAllMaterials() => ClassMaterialDAO.Instance.GetAll();

    public ClassMaterial? GetMaterialById(object id) => ClassMaterialDAO.Instance.GetById(id);

    public void UpdateMaterial(ClassMaterial material) => ClassMaterialDAO.Instance.Update(material);

    public IEnumerable<ClassMaterial> GetMaterialsByStudentId(long studentId) => ClassMaterialDAO.Instance.GetMaterialsByStudentId(studentId);
}
