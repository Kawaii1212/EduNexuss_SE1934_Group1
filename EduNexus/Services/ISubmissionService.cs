using System;
using EduNexus.Models;

namespace EduNexus.Services;

public interface ISubmissionService
{
    /// <summary>
    /// Submits an essay for a specific assignment and student.
    /// Handles both new submissions and resubmissions.
    /// </summary>
    long SubmitEssay(long assignmentId, long studentId, string content, string? fileUrl);

    Submission GetSubmissionForGrading(long submissionId);
    Submission GetSubmissionResult(long submissionId);
    void GradeSubmission(long submissionId, decimal finalScore, long teacherId);
    List<Submission> GetAllSubmissions();
    Task EvaluateSubmissionWithAIAsync(long submissionId);
}
