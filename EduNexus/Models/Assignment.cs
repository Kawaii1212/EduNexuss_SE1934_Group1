using System;
using System.Collections.Generic;

namespace EduNexus.Models;

public partial class Assignment
{
    public long Id { get; set; }

    public long ClassId { get; set; }

    public long? LessonId { get; set; }

    public string Title { get; set; } = null!;

    public string? DescriptionMd { get; set; }

    public decimal MaxScore { get; set; }

    public DateTimeOffset DueDate { get; set; }

    public string Status { get; set; } = null!;

    public long? CreatedBy { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public virtual ICollection<AssignmentRubricCriterion> AssignmentRubricCriteria { get; set; } = new List<AssignmentRubricCriterion>();

    public virtual Class Class { get; set; } = null!;

    public virtual Lesson? Lesson { get; set; }

    public virtual User? CreatedByNavigation { get; set; }

    public virtual ICollection<Submission> Submissions { get; set; } = new List<Submission>();
}
