using EduNexus.ViewModels;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using EduNexus.Models;
using EduNexus.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace EduNexus.Controllers;

public class QuestionController : Controller
{
    private readonly IQuestionService _questionService;
    private readonly EduNexusContext _context;

    public QuestionController(IQuestionService questionService, EduNexusContext context)
    {
        _questionService = questionService;
        _context = context;
    }

    private void ResolveCourseContext(long? courseId, long? moduleId)
    {
        Course? course = null;
        if (moduleId.HasValue && moduleId.Value > 0)
        {
            var module = _context.Modules
                .Include(m => m.Course)
                .FirstOrDefault(m => m.Id == moduleId.Value);
            if (module != null)
            {
                course = module.Course;
            }
        }
        else if (courseId.HasValue && courseId.Value > 0)
        {
            course = _context.Courses.Find(courseId.Value);
        }

        if (course != null)
        {
            ViewBag.ActiveCourseId = course.Id;
            ViewBag.ActiveCourseTitle = course.Title;
            ViewData["ActiveMenu"] = "MyCourses";
            ViewData["ActiveSubMenu"] = "Question";
        }
    }

    // GET: /Question
    public IActionResult Index(long? courseId, long? moduleId, string? difficulty, string? status, string? searchTerm)
    {
        // Enforce strict module-level filtering
        if (!moduleId.HasValue || moduleId.Value <= 0)
        {
            if (courseId.HasValue && courseId.Value > 0)
            {
                var firstModule = _context.Modules
                    .Where(m => m.CourseId == courseId.Value)
                    .OrderBy(m => m.OrderNo)
                    .FirstOrDefault();
                if (firstModule != null)
                {
                    moduleId = firstModule.Id;
                }
            }
            else
            {
                var firstModule = _context.Modules.OrderBy(m => m.Id).FirstOrDefault();
                if (firstModule != null)
                {
                    moduleId = firstModule.Id;
                    courseId = firstModule.CourseId;
                }
            }
        }

        ResolveCourseContext(courseId, moduleId);
        if (ViewBag.ActiveCourseId != null && !courseId.HasValue)
        {
            courseId = (long)ViewBag.ActiveCourseId;
        }

        List<Module> modules;
        if (courseId.HasValue && courseId.Value > 0)
        {
            modules = _context.Modules
                .Where(m => m.CourseId == courseId.Value)
                .OrderBy(m => m.OrderNo)
                .ToList();
        }
        else
        {
            modules = _questionService.GetAllModules();
        }

        List<Question> questions;
        if (moduleId.HasValue && moduleId.Value > 0)
        {
            questions = _questionService.GetQuestions(moduleId.Value, difficulty, status, searchTerm);
        }
        else
        {
            questions = new List<Question>();
        }

        var vm = new QuestionBankViewModel
        {
            Questions = questions,
            Modules = modules,
            SelectedModuleId = moduleId,
            SelectedDifficulty = difficulty,
            SelectedStatus = status,
            SearchTerm = searchTerm
        };

        ViewData["SuccessMessage"] = TempData["SuccessMessage"];
        ViewData["ErrorMessage"] = TempData["ErrorMessage"];

        return View(vm);
    }

    // GET: /Question/Details/5
    public IActionResult Details(long id)
    {
        var q = _questionService.GetById(id);
        if (q == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy câu hỏi.";
            return RedirectToAction(nameof(Index));
        }
        ResolveCourseContext(null, q.ModuleId);
        return View(q);
    }

    // GET: /Question/Create
    public IActionResult Create(long? courseId, long? moduleId)
    {
        ResolveCourseContext(courseId, moduleId);
        if (ViewBag.ActiveCourseId != null && !courseId.HasValue)
        {
            courseId = (long)ViewBag.ActiveCourseId;
        }

        List<Module> modules;
        if (courseId.HasValue && courseId.Value > 0)
        {
            modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
        }
        else
        {
            modules = _questionService.GetAllModules();
        }

        var vm = new QuestionFormViewModel
        {
            Modules = modules,
            ModuleId = moduleId ?? 0
        };
        return View(vm);
    }

    // POST: /Question/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(QuestionFormViewModel form)
    {
        var module = _context.Modules.Find(form.ModuleId);
        long? courseId = module?.CourseId;

        if (!ModelState.IsValid)
        {
            ResolveCourseContext(courseId, form.ModuleId);
            if (courseId.HasValue)
            {
                form.Modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
            }
            else
            {
                form.Modules = _questionService.GetAllModules();
            }
            return View(form);
        }

        // Giả lập creatorId = 1 khi chưa có Auth hoàn chỉnh
        long creatorId = 1;

        var q = new Question
        {
            ModuleId = form.ModuleId,
            Content = form.Content,
            OptionA = form.OptionA,
            OptionB = form.OptionB,
            OptionC = form.OptionC,
            OptionD = form.OptionD,
            CorrectOption = form.CorrectOption.ToUpper(),
            Difficulty = form.Difficulty.ToUpper(),
            AiExplanation = form.AiExplanation,
            Source = "MANUAL",
            Status = "APPROVED",
            CreatedBy = creatorId,
            CreatedAt = DateTimeOffset.UtcNow
        };

        try
        {
            _questionService.Add(q);
            TempData["SuccessMessage"] = "Thêm câu hỏi thủ công thành công.";
            return RedirectToAction(nameof(Index), new { courseId = courseId, moduleId = form.ModuleId });
        }
        catch (Exception ex)
        {
            ViewData["ErrorMessage"] = $"Lỗi hệ thống: {ex.Message}";
            ResolveCourseContext(courseId, form.ModuleId);
            if (courseId.HasValue)
            {
                form.Modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
            }
            else
            {
                form.Modules = _questionService.GetAllModules();
            }
            return View(form);
        }
    }

    // GET: /Question/Edit/5
    public IActionResult Edit(long id)
    {
        var q = _questionService.GetById(id);
        if (q == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy câu hỏi.";
            return RedirectToAction(nameof(Index));
        }

        ResolveCourseContext(null, q.ModuleId);
        long? courseId = ViewBag.ActiveCourseId;

        List<Module> modules;
        if (courseId.HasValue && courseId.Value > 0)
        {
            modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
        }
        else
        {
            modules = _questionService.GetAllModules();
        }

        var vm = new QuestionFormViewModel
        {
            Id = q.Id,
            ModuleId = q.ModuleId,
            Content = q.Content,
            OptionA = q.OptionA,
            OptionB = q.OptionB,
            OptionC = q.OptionC,
            OptionD = q.OptionD,
            CorrectOption = q.CorrectOption,
            Difficulty = q.Difficulty,
            AiExplanation = q.AiExplanation,
            Modules = modules
        };

        return View(vm);
    }

    // POST: /Question/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Edit(long id, QuestionFormViewModel form)
    {
        if (id != form.Id)
        {
            return BadRequest();
        }

        var module = _context.Modules.Find(form.ModuleId);
        long? courseId = module?.CourseId;

        if (!ModelState.IsValid)
        {
            ResolveCourseContext(courseId, form.ModuleId);
            if (courseId.HasValue)
            {
                form.Modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
            }
            else
            {
                form.Modules = _questionService.GetAllModules();
            }
            return View(form);
        }

        var q = _questionService.GetById(id);
        if (q == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy câu hỏi để cập nhật.";
            return RedirectToAction(nameof(Index), new { courseId = courseId });
        }

        q.ModuleId = form.ModuleId;
        q.Content = form.Content;
        q.OptionA = form.OptionA;
        q.OptionB = form.OptionB;
        q.OptionC = form.OptionC;
        q.OptionD = form.OptionD;
        q.CorrectOption = form.CorrectOption.ToUpper();
        q.Difficulty = form.Difficulty.ToUpper();
        q.AiExplanation = form.AiExplanation;

        try
        {
            _questionService.Update(q);
            TempData["SuccessMessage"] = "Cập nhật câu hỏi thành công.";
            return RedirectToAction(nameof(Index), new { courseId = courseId, moduleId = form.ModuleId });
        }
        catch (Exception ex)
        {
            ViewData["ErrorMessage"] = $"Lỗi hệ thống: {ex.Message}";
            ResolveCourseContext(courseId, form.ModuleId);
            if (courseId.HasValue)
            {
                form.Modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
            }
            else
            {
                form.Modules = _questionService.GetAllModules();
            }
            return View(form);
        }
    }

    // POST: /Question/Delete/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Delete(long id)
    {
        var q = _questionService.GetById(id);
        if (q == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy câu hỏi để xóa.";
            return RedirectToAction(nameof(Index));
        }

        long? courseId = _context.Modules.Find(q.ModuleId)?.CourseId;
        long originalModuleId = q.ModuleId;

        try
        {
            _questionService.Delete(q);
            TempData["SuccessMessage"] = "Đã xóa câu hỏi thành công.";
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"Không thể xóa câu hỏi này: {ex.Message}";
        }

        return RedirectToAction(nameof(Index), new { courseId = courseId, moduleId = originalModuleId });
    }

    // GET: /Question/Import
    public IActionResult Import(long? courseId, long? moduleId)
    {
        ResolveCourseContext(courseId, moduleId);
        if (ViewBag.ActiveCourseId != null && !courseId.HasValue)
        {
            courseId = (long)ViewBag.ActiveCourseId;
        }

        List<Module> modules;
        if (courseId.HasValue && courseId.Value > 0)
        {
            modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
        }
        else
        {
            modules = _questionService.GetAllModules();
        }

        var vm = new QuestionImportViewModel
        {
            Modules = modules,
            ModuleId = moduleId ?? 0
        };
        return View(vm);
    }

    // POST: /Question/Import
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Import(QuestionImportViewModel model)
    {
        var module = _context.Modules.Find(model.ModuleId);
        long? courseId = module?.CourseId;

        ResolveCourseContext(courseId, model.ModuleId);

        if (model.ModuleId <= 0)
        {
            ModelState.AddModelError(nameof(model.ModuleId), "Vui lòng chọn Module nhận câu hỏi.");
        }

        if (courseId.HasValue)
        {
            model.Modules = _context.Modules.Where(m => m.CourseId == courseId.Value).OrderBy(m => m.OrderNo).ToList();
        }
        else
        {
            model.Modules = _questionService.GetAllModules();
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        string csvContent = "";
        if (model.File != null && model.File.Length > 0)
        {
            using var reader = new StreamReader(model.File.OpenReadStream(), Encoding.UTF8);
            csvContent = await reader.ReadToEndAsync();
        }
        else if (!string.IsNullOrEmpty(model.CsvText))
        {
            csvContent = model.CsvText;
        }
        else
        {
            ModelState.AddModelError("", "Vui lòng upload file .csv hoặc dán nội dung CSV.");
            return View(model);
        }

        var lines = csvContent.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);
        var questionsToImport = new List<Question>();
        var errors = new List<string>();

        // Giả lập creatorId = 1
        long creatorId = 1;
        int rowNum = 0;
        bool isFirstLine = true;

        foreach (var rawLine in lines)
        {
            rowNum++;
            if (string.IsNullOrWhiteSpace(rawLine)) continue;

            // Bỏ qua dòng tiêu đề nếu dòng đầu trùng định dạng cột mẫu
            var columns = ParseCsvLine(rawLine);
            if (isFirstLine)
            {
                isFirstLine = false;
                if (columns.Count > 0 &&
                    (columns[0].Equals("Content", StringComparison.OrdinalIgnoreCase) ||
                     columns[0].Equals("Nội dung", StringComparison.OrdinalIgnoreCase)))
                {
                    continue; // Skip header
                }
            }

            if (columns.Count < 6)
            {
                errors.Add($"Dòng {rowNum}: Thiếu dữ liệu (Cần ít nhất 6 cột: Nội dung, A, B, C, D, Đáp án đúng).");
                continue;
            }

            string content = columns[0];
            string optA = columns[1];
            string optB = columns[2];
            string optC = columns[3];
            string optD = columns[4];
            string correctOpt = columns[5].Trim().ToUpper();

            string difficulty = "MEDIUM";
            if (columns.Count > 6 && !string.IsNullOrWhiteSpace(columns[6]))
            {
                var diff = columns[6].Trim().ToUpper();
                if (diff == "EASY" || diff == "MEDIUM" || diff == "HARD")
                {
                    difficulty = diff;
                }
            }

            string? explanation = null;
            if (columns.Count > 7 && !string.IsNullOrWhiteSpace(columns[7]))
            {
                explanation = columns[7];
            }

            // Validate
            if (string.IsNullOrWhiteSpace(content))
            {
                errors.Add($"Dòng {rowNum}: Nội dung câu hỏi không được để trống.");
                continue;
            }
            if (string.IsNullOrWhiteSpace(optA) || string.IsNullOrWhiteSpace(optB) ||
                string.IsNullOrWhiteSpace(optC) || string.IsNullOrWhiteSpace(optD))
            {
                errors.Add($"Dòng {rowNum}: Các lựa chọn A, B, C, D không được để trống.");
                continue;
            }
            if (correctOpt != "A" && correctOpt != "B" && correctOpt != "C" && correctOpt != "D")
            {
                errors.Add($"Dòng {rowNum}: Đáp án đúng '{correctOpt}' không hợp lệ (phải là A, B, C hoặc D).");
                continue;
            }

            var q = new Question
            {
                ModuleId = model.ModuleId,
                Content = content,
                OptionA = optA,
                OptionB = optB,
                OptionC = optC,
                OptionD = optD,
                CorrectOption = correctOpt,
                Difficulty = difficulty,
                AiExplanation = explanation,
                Source = "MANUAL",
                Status = "APPROVED",
                CreatedBy = creatorId,
                CreatedAt = DateTimeOffset.UtcNow
            };

            questionsToImport.Add(q);
        }

        if (questionsToImport.Count == 0 && errors.Count == 0)
        {
            errors.Add("Không tìm thấy dữ liệu hợp lệ để import.");
        }

        if (errors.Count > 0)
        {
            model.ImportErrors = errors;
            return View(model);
        }

        try
        {
            _questionService.AddRange(questionsToImport);
            TempData["SuccessMessage"] = $"Import thành công {questionsToImport.Count} câu hỏi vào ngân hàng câu hỏi.";
            return RedirectToAction(nameof(Index), new { courseId = courseId, moduleId = model.ModuleId });
        }
        catch (Exception ex)
        {
            errors.Add($"Lỗi lưu database: {ex.Message}");
            model.ImportErrors = errors;
            return View(model);
        }
    }

    // Helper tách dòng CSV hỗ trợ dấu ngoặc kép
    private static List<string> ParseCsvLine(string line)
    {
        var result = new List<string>();
        if (string.IsNullOrWhiteSpace(line)) return result;

        var currentColumn = new StringBuilder();
        bool inQuotes = false;

        for (int i = 0; i < line.Length; i++)
        {
            char c = line[i];

            if (c == '"')
            {
                inQuotes = !inQuotes;
            }
            else if (c == ',' && !inQuotes)
            {
                result.Add(currentColumn.ToString());
                currentColumn.Clear();
            }
            else
            {
                currentColumn.Append(c);
            }
        }
        result.Add(currentColumn.ToString());
        return result;
    }

    // GET: /Question/ViewQuestions?moduleId=5
    [HttpGet]
    public IActionResult ViewQuestions(long moduleId)
    {
        var module = _context.Modules
            .Include(m => m.Course)
            .FirstOrDefault(m => m.Id == moduleId);
        if (module == null) return NotFound("Chương học không tồn tại.");

        ResolveCourseContext(module.CourseId, moduleId);

        var questions = _context.Questions
            .Include(q => q.Module)
            .Where(q => q.ModuleId == moduleId && q.Status == "APPROVED")
            .OrderByDescending(q => q.CreatedAt)
            .ToList();

        ViewBag.ModuleName = module.Title;
        ViewBag.ModuleOrderNo = module.OrderNo;

        return View(questions);
    }
}
