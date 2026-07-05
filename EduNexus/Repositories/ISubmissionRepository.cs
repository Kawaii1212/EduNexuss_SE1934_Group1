using EduNexus.Models;

namespace EduNexus.Repositories;

public interface ISubmissionRepository
{
    void AddSubmission(Submission submission);
    void UpdateSubmission(Submission submission);
    Submission? GetSubmissionByAssignmentAndStudent(long assignmentId, long studentId);
    Submission? GetSubmissionById(long submissionId);
    Submission? GetSubmissionResult(long submissionId);
    List<Submission> GetAllSubmissions();
    List<AssignmentRubricCriterion> GetAssignmentRubrics(long assignmentId);
    void UpdateAiEvaluation(Submission submission, List<SubmissionCriterionScore> newScores);
}
