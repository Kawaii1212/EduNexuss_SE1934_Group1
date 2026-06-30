using System.Collections.Generic;
using DataAccessLayer.Models;
using DataAccessLayer.Repositories;

namespace DataAccessLayer.Services;

public class ClassMaterialService : IClassMaterialService
{
    private readonly IClassMaterialRepository _materialRepository;

    public ClassMaterialService(IClassMaterialRepository materialRepository)
    {
        _materialRepository = materialRepository;
    }

    public void AddMaterial(ClassMaterial material) => _materialRepository.AddMaterial(material);

    public void DeleteMaterial(ClassMaterial material) => _materialRepository.DeleteMaterial(material);

    public IEnumerable<ClassMaterial> GetAllMaterials() => _materialRepository.GetAllMaterials();

    public ClassMaterial? GetMaterialById(object id) => _materialRepository.GetMaterialById(id);

    public void UpdateMaterial(ClassMaterial material) => _materialRepository.UpdateMaterial(material);

    public IEnumerable<ClassMaterial> GetMaterialsByStudentId(long studentId) => _materialRepository.GetMaterialsByStudentId(studentId);
}
