using System;
using System.Threading.Tasks;
using System.Text.Json;
using System.Linq;
using System.Collections.Generic;
using EduNexus.Models;
using EduNexus.Repositories;

namespace EduNexus.Services;

public class SubmissionService : ISubmissionService
{
    private readonly ISubmissionRepository _submissionRepository;
    private readonly GeminiService _geminiService;

    public SubmissionService(ISubmissionRepository submissionRepository, GeminiService geminiService)
    {
        _submissionRepository = submissionRepository;
        _geminiService = geminiService;
    }

    public long SubmitEssay(long assignmentId, long studentId, string content, string? fileUrl)
    {
        var existingSubmission = _submissionRepository.GetSubmissionByAssignmentAndStudent(assignmentId, studentId);

        if (existingSubmission != null)
        {
            // Resubmit: Update existing record
            existingSubmission.Content = content;
            if (fileUrl != null)
            {
                existingSubmission.FileUrl = fileUrl;
            }
            existingSubmission.SubmittedAt = DateTimeOffset.UtcNow;
            existingSubmission.Status = "SUBMITTED"; // Ensure status is SUBMITTED for AI to pick up
            
            _submissionRepository.UpdateSubmission(existingSubmission);
            return existingSubmission.Id;
        }
        else
        {
            // New submission
            var newSubmission = new Submission
            {
                AssignmentId = assignmentId,
                StudentId = studentId,
                Content = content,
                FileUrl = fileUrl,
                SubmittedAt = DateTimeOffset.UtcNow,
                Status = "SUBMITTED" // DO NOT USE "Pending_AI_Review" as it violates DB Constraint
            };

            _submissionRepository.AddSubmission(newSubmission);
            return newSubmission.Id;
        }
    }

    public Submission GetSubmissionForGrading(long submissionId)
    {
        var submission = _submissionRepository.GetSubmissionById(submissionId);
        if (submission == null)
        {
            throw new Exception("Submission not found.");
        }
        return submission;
    }

    public Submission GetSubmissionResult(long submissionId)
    {
        var submission = _submissionRepository.GetSubmissionResult(submissionId);
        if (submission == null)
        {
            throw new Exception("Submission result not found.");
        }
        return submission;
    }

    public void GradeSubmission(long submissionId, decimal finalScore, long teacherId)
    {
        var submission = _submissionRepository.GetSubmissionById(submissionId);
        if (submission == null)
        {
            throw new Exception("Submission not found.");
        }

        submission.FinalScore = finalScore;
        submission.GradedBy = teacherId;
        submission.GradedAt = DateTimeOffset.UtcNow;
        submission.Status = "GRADED";

        _submissionRepository.UpdateSubmission(submission);
    }

    public List<Submission> GetAllSubmissions()
    {
        return _submissionRepository.GetAllSubmissions();
    }

    public async Task EvaluateSubmissionWithAIAsync(long submissionId)
    {
        var submission = _submissionRepository.GetSubmissionById(submissionId);
        if (submission == null) return;

        var rubrics = _submissionRepository.GetAssignmentRubrics(submission.AssignmentId);
        if (rubrics == null || !rubrics.Any()) return; // Nothing to grade against

        // Build prompt
        var prompt = $"Please act as an expert teacher and grade this assignment submission.\n";
        prompt += $"Submission Content:\n{submission.Content}\n\n";
        prompt += "Rubric Criteria to evaluate against:\n";
        foreach (var r in rubrics)
        {
            prompt += $"- ID: {r.Id}, Name: {r.Name}, Max Score: {r.MaxScore}\n";
        }
        prompt += "\nEvaluate the submission against these criteria. Return ONLY a JSON object with this exact structure:\n";
        prompt += "{\n";
        prompt += "  \"generalFeedback\": \"overall comments\",\n";
        prompt += "  \"totalAiScore\": total_score_number,\n";
        prompt += "  \"criteriaScores\": [\n";
        prompt += "    { \"criterionId\": 1, \"aiScore\": 8.5, \"aiFeedback\": \"good...\" }\n";
        prompt += "  ]\n";
        prompt += "}";

        try
        {
            var resultJsonString = await _geminiService.GenerateTextAsync(prompt);
            
            // Clean up the string just in case Gemini wrapped it in ```json ... ```
            if (resultJsonString.StartsWith("```json"))
            {
                resultJsonString = resultJsonString.Replace("```json", "").Replace("```", "").Trim();
            }
            else if (resultJsonString.StartsWith("```"))
            {
                resultJsonString = resultJsonString.Replace("```", "").Trim();
            }
            
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var aiResult = JsonSerializer.Deserialize<AiEvaluationResult>(resultJsonString, options);

            if (aiResult != null)
            {
                submission.AiScore = aiResult.TotalAiScore;
                submission.Feedback = aiResult.GeneralFeedback;

                var newScores = new List<SubmissionCriterionScore>();
                foreach (var cs in aiResult.CriteriaScores)
                {
                    newScores.Add(new SubmissionCriterionScore
                    {
                        SubmissionId = submissionId,
                        CriterionId = cs.CriterionId,
                        AiScore = cs.AiScore,
                        AiFeedback = cs.AiFeedback
                    });
                }

                _submissionRepository.UpdateAiEvaluation(submission, newScores);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"AI Evaluation failed: {ex.Message}");
        }
    }

    private class AiEvaluationResult
    {
        public string GeneralFeedback { get; set; } = string.Empty;
        public decimal TotalAiScore { get; set; }
        public List<AiCriterionScore> CriteriaScores { get; set; } = new List<AiCriterionScore>();
    }

    private class AiCriterionScore
    {
        public long CriterionId { get; set; }
        public decimal AiScore { get; set; }
        public string AiFeedback { get; set; } = string.Empty;
    }
}
