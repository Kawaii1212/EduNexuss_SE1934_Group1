using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace EduNexus.ViewModels;

public class SmeAssignmentCreateViewModel
{
    public long CourseId { get; set; }
    public string CourseTitle { get; set; } = string.Empty;

    public long ClassId { get; set; }
    public List<SelectListItem> AvailableClasses { get; set; } = new List<SelectListItem>();

    public string Title { get; set; } = string.Empty;
    public string? DescriptionMd { get; set; }
    public decimal MaxScore { get; set; }
    public DateTimeOffset DueDate { get; set; } = DateTimeOffset.UtcNow.AddDays(7);
    public string Status { get; set; } = "PUBLISHED";

    public List<RubricCriterionViewModel> Rubrics { get; set; } = new List<RubricCriterionViewModel>();
}

public class SmeAssignmentEditViewModel : SmeAssignmentCreateViewModel
{
    public long AssignmentId { get; set; }
}

public class RubricCriterionViewModel
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal MaxScore { get; set; }
    public decimal WeightPercent { get; set; }
    public int OrderNo { get; set; }
}

public class AiAssignmentGenRequest
{
    public string Prompt { get; set; } = string.Empty;
}

public class AiAssignmentGenResponse
{
    public string Title { get; set; } = string.Empty;
    public string DescriptionMd { get; set; } = string.Empty;
    public decimal MaxScore { get; set; }
    public List<RubricCriterionViewModel> Rubrics { get; set; } = new List<RubricCriterionViewModel>();
}
