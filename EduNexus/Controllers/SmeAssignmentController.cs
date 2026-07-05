using EduNexus.Models;
using EduNexus.Services;
using EduNexus.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace EduNexus.Controllers
{
    public class SmeAssignmentController : Controller
    {
        private readonly EduNexusContext _context;
        private readonly GeminiService _geminiService;

        public SmeAssignmentController(EduNexusContext context, GeminiService geminiService)
        {
            _context = context;
            _geminiService = geminiService;
        }

        private long GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim != null) return long.Parse(userIdClaim.Value);
            
            var defaultSme = _context.Users.FirstOrDefault(u => u.Role == "SME" || u.Role == "sme");
            return defaultSme?.Id ?? 3;
        }

        private void SetNavigationData(long courseId, string courseTitle)
        {
            ViewBag.ActiveCourseId = courseId;
            ViewBag.ActiveCourseTitle = courseTitle;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = "Assignments";
        }

        [HttpGet]
        public IActionResult Create(long courseId)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == courseId && c.DeletedAt == null);
            if (course == null) return NotFound("Khóa học không tồn tại.");

            SetNavigationData(course.Id, course.Title);

            var classes = _context.Classes
                .Where(c => c.CourseId == courseId && c.Status != "CLOSED")
                .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.Name })
                .ToList();

            var model = new SmeAssignmentCreateViewModel
            {
                CourseId = course.Id,
                CourseTitle = course.Title,
                AvailableClasses = classes
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Create(SmeAssignmentCreateViewModel model)
        {
            var course = _context.Courses.FirstOrDefault(c => c.Id == model.CourseId);
            if (course == null) return NotFound();

            if (!ModelState.IsValid)
            {
                SetNavigationData(course.Id, course.Title);
                model.AvailableClasses = _context.Classes
                    .Where(c => c.CourseId == model.CourseId && c.Status != "CLOSED")
                    .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.Name })
                    .ToList();
                return View(model);
            }

            var assignment = new Assignment
            {
                ClassId = model.ClassId,
                Title = model.Title,
                DescriptionMd = model.DescriptionMd,
                MaxScore = model.MaxScore,
                DueDate = model.DueDate,
                Status = model.Status,
                CreatedBy = GetCurrentUserId(),
                CreatedAt = DateTimeOffset.UtcNow
            };

            _context.Assignments.Add(assignment);
            _context.SaveChanges();

            if (model.Rubrics != null && model.Rubrics.Any())
            {
                int order = 1;
                foreach (var r in model.Rubrics)
                {
                    _context.AssignmentRubricCriteria.Add(new AssignmentRubricCriterion
                    {
                        AssignmentId = assignment.Id,
                        Name = r.Name,
                        MaxScore = r.MaxScore,
                        WeightPercent = r.WeightPercent,
                        OrderNo = order++
                    });
                }
                _context.SaveChanges();
            }

            return RedirectToAction("Assignments", "Course", new { courseId = model.CourseId });
        }

        [HttpGet]
        public IActionResult Edit(long id)
        {
            var assignment = _context.Assignments
                .Include(a => a.Class)
                    .ThenInclude(c => c.Course)
                .Include(a => a.AssignmentRubricCriteria)
                .FirstOrDefault(a => a.Id == id);

            if (assignment == null) return NotFound("Bài tập không tồn tại.");

            SetNavigationData(assignment.Class.CourseId, assignment.Class.Course.Title);

            var classes = _context.Classes
                .Where(c => c.CourseId == assignment.Class.CourseId && c.Status != "CLOSED")
                .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.Name })
                .ToList();

            var model = new SmeAssignmentEditViewModel
            {
                AssignmentId = assignment.Id,
                CourseId = assignment.Class.CourseId,
                CourseTitle = assignment.Class.Course.Title,
                ClassId = assignment.ClassId,
                AvailableClasses = classes,
                Title = assignment.Title,
                DescriptionMd = assignment.DescriptionMd,
                MaxScore = assignment.MaxScore,
                DueDate = assignment.DueDate,
                Status = assignment.Status,
                Rubrics = assignment.AssignmentRubricCriteria.OrderBy(r => r.OrderNo).Select(r => new RubricCriterionViewModel
                {
                    Id = r.Id,
                    Name = r.Name,
                    MaxScore = r.MaxScore,
                    WeightPercent = r.WeightPercent,
                    OrderNo = r.OrderNo
                }).ToList()
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Edit(SmeAssignmentEditViewModel model)
        {
            var assignment = _context.Assignments
                .Include(a => a.AssignmentRubricCriteria)
                .FirstOrDefault(a => a.Id == model.AssignmentId);

            if (assignment == null) return NotFound();

            if (!ModelState.IsValid)
            {
                SetNavigationData(model.CourseId, model.CourseTitle);
                model.AvailableClasses = _context.Classes
                    .Where(c => c.CourseId == model.CourseId && c.Status != "CLOSED")
                    .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.Name })
                    .ToList();
                return View(model);
            }

            assignment.ClassId = model.ClassId;
            assignment.Title = model.Title;
            assignment.DescriptionMd = model.DescriptionMd;
            assignment.MaxScore = model.MaxScore;
            assignment.DueDate = model.DueDate;
            assignment.Status = model.Status;

            _context.Assignments.Update(assignment);

            // Sync Rubrics
            _context.AssignmentRubricCriteria.RemoveRange(assignment.AssignmentRubricCriteria);
            
            if (model.Rubrics != null && model.Rubrics.Any())
            {
                int order = 1;
                foreach (var r in model.Rubrics)
                {
                    _context.AssignmentRubricCriteria.Add(new AssignmentRubricCriterion
                    {
                        AssignmentId = assignment.Id,
                        Name = r.Name,
                        MaxScore = r.MaxScore,
                        WeightPercent = r.WeightPercent,
                        OrderNo = order++
                    });
                }
            }

            _context.SaveChanges();

            return RedirectToAction("Assignments", "Course", new { courseId = model.CourseId });
        }

        [HttpPost]
        public async Task<IActionResult> GenerateWithAI([FromBody] AiAssignmentGenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Prompt))
            {
                return BadRequest(new { success = false, message = "Prompt cannot be empty" });
            }

            var prompt = $@"
Act as an expert instructional designer. Generate an assignment details and its grading rubric based on this prompt: '{request.Prompt}'.
Return ONLY a valid JSON object with the following structure (no markdown fences, no extra text):
{{
  ""title"": ""Assignment Title"",
  ""descriptionMd"": ""Assignment description in Markdown format. Be detailed."",
  ""maxScore"": 10,
  ""rubrics"": [
    {{
      ""name"": ""Criterion 1"",
      ""maxScore"": 4,
      ""weightPercent"": 40
    }},
    {{
      ""name"": ""Criterion 2"",
      ""maxScore"": 6,
      ""weightPercent"": 60
    }}
  ]
}}
Ensure that the sum of weightPercent is 100, and the sum of maxScore of rubrics equals the total maxScore.
";

            try
            {
                var responseStr = await _geminiService.GenerateTextAsync(prompt);
                
                if (responseStr.StartsWith("```json"))
                {
                    responseStr = responseStr.Replace("```json", "").Replace("```", "").Trim();
                }
                else if (responseStr.StartsWith("```"))
                {
                    responseStr = responseStr.Replace("```", "").Trim();
                }

                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var aiResult = JsonSerializer.Deserialize<AiAssignmentGenResponse>(responseStr, options);

                return Ok(new { success = true, data = aiResult });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }
    }
}
