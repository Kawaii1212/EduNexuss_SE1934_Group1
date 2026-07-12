using EduNexus.ViewModels;
using EduNexus.Models;
using EduNexus.Services;
using Microsoft.AspNetCore.Mvc;
using System.Linq;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Controllers
{
    public class LessonController : Controller
    {
        private readonly EduNexusContext _context;
        private readonly GeminiService _geminiService;

        public LessonController(EduNexusContext context, GeminiService geminiService)
        {
            _context = context;
            _geminiService = geminiService;
        }

        [HttpGet]
        public IActionResult LessonEditor(long? id, long? moduleId)
        {
            var model = new LessonEditorViewModel();
            if (id.HasValue && id > 0)
            {
                var lesson = _context.Lessons.Include(l => l.Module).FirstOrDefault(l => l.Id == id.Value);
                if (lesson != null)
                {
                    model.LessonId = lesson.Id;
                    model.ModuleId = lesson.ModuleId;
                    model.CourseId = lesson.Module.CourseId;
                    model.Title = lesson.Title;
                    model.Content = lesson.Content;
                    model.VideoUrl = lesson.VideoUrl;
                    
                    // For demo mapping, in real app you might have extended Lesson fields
                    // model.LessonType = ...
                    // model.EstimatedDuration = ...
                }
            }
            else if (moduleId.HasValue)
            {
                model.ModuleId = moduleId.Value;
                var module = _context.Modules.FirstOrDefault(m => m.Id == moduleId.Value);
                if (module != null)
                {
                    model.CourseId = module.CourseId;
                }
            }
            
            return View(model);
        }

        [HttpPost]
        public IActionResult LessonEditor(LessonEditorViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var lesson = _context.Lessons.FirstOrDefault(l => l.Id == model.LessonId);
            if (lesson == null)
            {
                lesson = new Lesson
                {
                    ModuleId = model.ModuleId > 0 ? model.ModuleId : 1, // Fallback if no module
                    Status = "DRAFT",
                    CreatedAt = System.DateTimeOffset.UtcNow
                };
                _context.Lessons.Add(lesson);
            }
            
            lesson.Title = model.Title;
            lesson.Content = model.Content ?? "";
            lesson.VideoUrl = model.VideoUrl;
            lesson.UpdatedAt = System.DateTimeOffset.UtcNow;

            _context.SaveChanges();

            // Xử lý lưu file đính kèm (Lưu file vật lý và nối link vào Content)
            if (model.Attachments != null && model.Attachments.Length > 0)
            {
                var uploadDir = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "wwwroot", "uploads", "lessons", lesson.Id.ToString());
                if (!System.IO.Directory.Exists(uploadDir))
                {
                    System.IO.Directory.CreateDirectory(uploadDir);
                }

                var attachmentHtml = "<div class='lesson-attachments' style='margin-top:20px; padding-top:15px; border-top:1px solid #e5e7eb;'><h4>Tài liệu đính kèm:</h4><ul style='list-style-type:none; padding-left:0;'>";
                foreach (var file in model.Attachments)
                {
                    if (file.Length > 0)
                    {
                        var fileName = System.IO.Path.GetFileName(file.FileName);
                        var filePath = System.IO.Path.Combine(uploadDir, fileName);
                        using (var stream = new System.IO.FileStream(filePath, System.IO.FileMode.Create))
                        {
                            file.CopyTo(stream);
                        }
                        attachmentHtml += $"<li style='margin-bottom:8px;'><a href='/uploads/lessons/{lesson.Id}/{fileName}' target='_blank' style='text-decoration:none; color:#5c24ff;'><i class='fa-solid fa-file-arrow-down'></i> {fileName}</a></li>";
                    }
                }
                attachmentHtml += "</ul></div>";

                // Nối vào nội dung HTML của bài học và lưu lại
                lesson.Content += attachmentHtml;
                _context.SaveChanges();
            }

            TempData["SuccessMessage"] = "Lesson saved successfully!";
            return RedirectToAction("LessonEditor", new { id = lesson.Id });
        }

        [HttpGet]
        public IActionResult AILessonStaging(long id)
        {
            ViewBag.LessonId = id;
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> GenerateLessonText([FromBody] GenerateTextRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Outline)) return BadRequest("Outline is required");
            
            var prompt = $@"Bạn là một chuyên gia giáo dục. Hãy viết một bài giảng chi tiết và sinh động bằng Markdown (định dạng HTML-friendly) dựa trên dàn ý sau:
{req.Outline}

Hãy chia thành các phần rõ ràng, giải thích chi tiết từng ý, và cho ví dụ minh họa nếu cần thiết. Trả về nội dung bài giảng, không cần lời chào hay kết luận thừa.";
            
            try 
            {
                var content = await _geminiService.GenerateTextAsync(prompt);
                return Json(new { success = true, content = content });
            }
            catch(System.Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> SummarizeVideo([FromBody] SummarizeVideoRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.VideoUrl)) return BadRequest("Video URL is required");
            
            var prompt = $@"Bạn là một trợ lý AI thông minh học tập. Hãy phân tích nội dung dựa trên video YouTube sau đây: {req.VideoUrl}
Và tạo ra một 'Ghi chú học tập' có cấu trúc (bằng Markdown) bao gồm:
1. Tóm tắt nội dung chính (Overview).
2. Các điểm chính cần nhớ (Key Takeaways) bằng bullet points.
3. Giải thích một số khái niệm có thể xuất hiện trong video đó.
Chỉ trả về nội dung Markdown.";
            
            try 
            {
                var content = await _geminiService.GenerateTextAsync(prompt);
                return Json(new { success = true, content = content });
            }
            catch(System.Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        [HttpPost]
        public IActionResult SaveStaging([FromBody] SaveStagingRequest req)
        {
            var lesson = _context.Lessons.Find(req.LessonId);
            if (lesson == null) return NotFound();

            if (!string.IsNullOrEmpty(req.Content))
            {
                lesson.Content = req.Content; // Overwrite content with AI output
            }
            if (!string.IsNullOrEmpty(req.VideoUrl))
            {
                lesson.VideoUrl = req.VideoUrl;
            }

            _context.SaveChanges();
            
            return Json(new { success = true });
        }

        public class GenerateTextRequest { public string Outline { get; set; } }
        public class SummarizeVideoRequest { public string VideoUrl { get; set; } }
        public class SaveStagingRequest { public long LessonId { get; set; } public string Content { get; set; } public string VideoUrl { get; set; } }

        [HttpGet]
        public IActionResult LessonView(long? id)
        {
            if (!id.HasValue) return RedirectToAction("Index", "Home");
            
            var lesson = _context.Lessons
                .Include(l => l.Assignments)
                .Include(l => l.Module)
                .ThenInclude(m => m.Course)
                .FirstOrDefault(l => l.Id == id.Value);
                
            if (lesson == null) return NotFound();

            var modules = _context.Modules
                .Include(m => m.Lessons)
                .Where(m => m.CourseId == lesson.Module.CourseId)
                .OrderBy(m => m.OrderNo)
                .ToList();
                
            foreach (var m in modules)
            {
                m.Lessons = m.Lessons.OrderBy(l => l.OrderNo).ToList();
            }

            bool isCompleted = false;
            decimal progressPercent = 0;
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim != null)
            {
                long studentId = long.Parse(studentIdClaim.Value);
                isCompleted = _context.LearningProgresses.Any(lp => lp.StudentId == studentId && lp.LessonId == lesson.Id && lp.ActivityType == "LESSON" && lp.CompletionStatus == "COMPLETED");
                
                var enrollment = _context.Enrollments.FirstOrDefault(e => e.StudentId == studentId && (e.CourseId == lesson.Module.CourseId || (e.Class != null && e.Class.CourseId == lesson.Module.CourseId)));
                if (enrollment != null)
                {
                    progressPercent = enrollment.ProgressPercent;
                }
            }

            var model = new EduNexus.ViewModels.LessonViewModel
            {
                CurrentLesson = lesson,
                Course = lesson.Module.Course,
                Modules = modules,
                IsPreview = false,
                IsCompleted = isCompleted,
                ProgressPercent = progressPercent
            };

            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> MarkAsComplete(long lessonId)
        {
            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (studentIdClaim == null) return Unauthorized();

            long studentId = long.Parse(studentIdClaim.Value);
            
            var lesson = await _context.Lessons.Include(l => l.Module).FirstOrDefaultAsync(l => l.Id == lessonId);
            if (lesson == null) return NotFound();

            var courseId = lesson.Module.CourseId;

            var progress = await _context.LearningProgresses
                .FirstOrDefaultAsync(lp => lp.StudentId == studentId && lp.LessonId == lessonId && lp.ActivityType == "LESSON");

            if (progress == null)
            {
                progress = new LearningProgress
                {
                    StudentId = studentId,
                    LessonId = lessonId,
                    ActivityType = "LESSON",
                    CompletionStatus = "COMPLETED",
                    TimeSpentSeconds = 0,
                    LastActiveAt = DateTimeOffset.Now
                };
                _context.LearningProgresses.Add(progress);
            }
            else
            {
                progress.CompletionStatus = "COMPLETED";
                progress.LastActiveAt = DateTimeOffset.Now;
                _context.LearningProgresses.Update(progress);
            }
            await _context.SaveChangesAsync();

            var totalLessons = await _context.Lessons
                .CountAsync(l => l.Module.CourseId == courseId);

            var completedLessonIds = await _context.LearningProgresses
                .Where(lp => lp.StudentId == studentId && 
                             lp.ActivityType == "LESSON" && 
                             lp.CompletionStatus == "COMPLETED" && 
                             lp.LessonId != null)
                .Select(lp => lp.LessonId!.Value)
                .ToListAsync();

            var completedLessons = await _context.Lessons
                .CountAsync(l => l.Module.CourseId == courseId && completedLessonIds.Contains(l.Id));

            decimal progressPercent = 0;
            if (totalLessons > 0)
            {
                progressPercent = Math.Min(100m, Math.Round((decimal)completedLessons / (decimal)totalLessons * 100m, 2));
            }

            var enrollments = await _context.Enrollments
                .Include(e => e.Class)
                .Where(e => e.StudentId == studentId && (e.CourseId == courseId || (e.Class != null && e.Class.CourseId == courseId)))
                .ToListAsync();

            foreach (var enrollment in enrollments)
            {
                enrollment.ProgressPercent = progressPercent;
                _context.Enrollments.Update(enrollment);
            }
            await _context.SaveChangesAsync();

            return RedirectToAction("LessonView", new { id = lessonId });
        }

        [HttpGet]
        public IActionResult LessonPreview(long? id)
        {
            if (!id.HasValue) return RedirectToAction("Index", "Home");
            
            var lesson = _context.Lessons
                .Include(l => l.Assignments)
                .Include(l => l.Module)
                .ThenInclude(m => m.Course)
                .FirstOrDefault(l => l.Id == id.Value);
                
            if (lesson == null) return NotFound();

            var modules = _context.Modules
                .Include(m => m.Lessons)
                .Where(m => m.CourseId == lesson.Module.CourseId)
                .OrderBy(m => m.OrderNo)
                .ToList();
                
            foreach (var m in modules)
            {
                m.Lessons = m.Lessons.OrderBy(l => l.OrderNo).ToList();
            }

            var studentIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            bool isGuest = studentIdClaim == null;

            var model = new EduNexus.ViewModels.LessonViewModel
            {
                CurrentLesson = lesson,
                Course = lesson.Module.Course,
                Modules = modules,
                IsPreview = true,
                IsGuest = isGuest
            };

            return View(model);
        }

        public IActionResult LessonTextExtract()
        {
            return View();
        }
    }
}
