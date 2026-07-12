using System;
using System.Collections.Generic;

namespace EduNexus.Models;

public partial class Lesson
{
    public long Id { get; set; }

    public long ModuleId { get; set; }

    public string Title { get; set; } = null!;

    public string? VideoUrl { get; set; }

    public string? Summary { get; set; }

    public string Content { get; set; } = null!;

    public string Status { get; set; } = null!;

    public int OrderNo { get; set; }

    public long? CreatedBy { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }

    public virtual User? CreatedByNavigation { get; set; }

    public virtual ICollection<LearningProgress> LearningProgresses { get; set; } = new List<LearningProgress>();

    public virtual ICollection<LessonViewEvent> LessonViewEvents { get; set; } = new List<LessonViewEvent>();

    public virtual ICollection<Assignment> Assignments { get; set; } = new List<Assignment>();

    public virtual Module Module { get; set; } = null!;
}
