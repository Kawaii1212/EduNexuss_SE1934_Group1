using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace EduNexus.Models;

public partial class EduNexusContext : DbContext
{
    public EduNexusContext()
    {
    }

    public EduNexusContext(DbContextOptions<EduNexusContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AiQuotum> AiQuota { get; set; }

    public virtual DbSet<AiRequest> AiRequests { get; set; }

    public virtual DbSet<AiResponse> AiResponses { get; set; }

    public virtual DbSet<Assignment> Assignments { get; set; }

    public virtual DbSet<AssignmentRubricCriterion> AssignmentRubricCriteria { get; set; }

    public virtual DbSet<AuditLog> AuditLogs { get; set; }

    public virtual DbSet<BackgroundJobLog> BackgroundJobLogs { get; set; }

    public virtual DbSet<Class> Classes { get; set; }

    public virtual DbSet<ClassMaterial> ClassMaterials { get; set; }

    public virtual DbSet<Course> Courses { get; set; }

    public virtual DbSet<CourseContentVersion> CourseContentVersions { get; set; }

    public virtual DbSet<CourseGroup> CourseGroups { get; set; }

    public virtual DbSet<CourseGroupMember> CourseGroupMembers { get; set; }

    public virtual DbSet<Enrollment> Enrollments { get; set; }

    public virtual DbSet<Flashcard> Flashcards { get; set; }

    public virtual DbSet<FlashcardDeck> FlashcardDecks { get; set; }

    public virtual DbSet<FlashcardReviewLog> FlashcardReviewLogs { get; set; }

    public virtual DbSet<KnowledgeGapAnalysis> KnowledgeGapAnalyses { get; set; }

    public virtual DbSet<LearningProgress> LearningProgresses { get; set; }

    public virtual DbSet<Lesson> Lessons { get; set; }

    public virtual DbSet<LessonViewEvent> LessonViewEvents { get; set; }

    public virtual DbSet<LoginHistory> LoginHistories { get; set; }

    public virtual DbSet<Module> Modules { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Question> Questions { get; set; }

    public virtual DbSet<Quiz> Quizzes { get; set; }

    public virtual DbSet<QuizAttempt> QuizAttempts { get; set; }

    public virtual DbSet<QuizAttemptAnswer> QuizAttemptAnswers { get; set; }

    public virtual DbSet<QuizQuestion> QuizQuestions { get; set; }

    public virtual DbSet<RefundRequest> RefundRequests { get; set; }

    public virtual DbSet<Submission> Submissions { get; set; }

    public virtual DbSet<SubmissionCriterionScore> SubmissionCriterionScores { get; set; }

    public virtual DbSet<SubscriptionPackage> SubscriptionPackages { get; set; }

    public virtual DbSet<SystemSetting> SystemSettings { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserOauthIdentity> UserOauthIdentities { get; set; }

    public virtual DbSet<UserSession> UserSessions { get; set; }

    public virtual DbSet<VClassOverviewReport> VClassOverviewReports { get; set; }

    public virtual DbSet<VContentQualityReport> VContentQualityReports { get; set; }

    public virtual DbSet<VRevenueReport> VRevenueReports { get; set; }


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AiQuotum>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__ai_quota__3213E83F39F1784C");

            entity.ToTable("ai_quota");

            entity.HasIndex(e => new { e.UserId, e.MonthYear }, "uq_ai_quota_user_month").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.MonthYear)
                .HasMaxLength(7)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("month_year");
            entity.Property(e => e.QuotaLimit).HasColumnName("quota_limit");
            entity.Property(e => e.UsedCount).HasColumnName("used_count");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.AiQuota)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ai_quota__user_i__17C286CF");
        });

        modelBuilder.Entity<AiRequest>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__ai_reque__3213E83FD9DBD319");

            entity.ToTable("ai_request");

            entity.HasIndex(e => e.RequesterId, "idx_ai_request_requester");

            entity.HasIndex(e => e.TaskType, "idx_ai_request_task_type");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.RequesterId).HasColumnName("requester_id");
            entity.Property(e => e.SourceRefId).HasColumnName("source_ref_id");
            entity.Property(e => e.SourceRefType)
                .HasMaxLength(50)
                .HasColumnName("source_ref_type");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("PENDING")
                .HasColumnName("status");
            entity.Property(e => e.TaskType)
                .HasMaxLength(20)
                .HasColumnName("task_type");

            entity.HasOne(d => d.Requester).WithMany(p => p.AiRequests)
                .HasForeignKey(d => d.RequesterId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ai_reques__reque__09746778");
        });

        modelBuilder.Entity<AiResponse>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__ai_respo__3213E83F5A56A28D");

            entity.ToTable("ai_response");

            entity.HasIndex(e => e.AiRequestId, "uq_ai_response_request").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AiRequestId).HasColumnName("ai_request_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.GeneratedContent).HasColumnName("generated_content");
            entity.Property(e => e.Model)
                .HasMaxLength(100)
                .HasColumnName("model");
            entity.Property(e => e.ProcessingTimeMs).HasColumnName("processing_time_ms");
            entity.Property(e => e.TokenConsumed).HasColumnName("token_consumed");

            entity.HasOne(d => d.AiRequest).WithOne(p => p.AiResponse)
                .HasForeignKey<AiResponse>(d => d.AiRequestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ai_respon__ai_re__11158940");
        });

        modelBuilder.Entity<Assignment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__assignme__3213E83FE01085EE");

            entity.ToTable("assignment");

            entity.HasIndex(e => e.ClassId, "idx_assignment_class");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.LessonId).HasColumnName("lesson_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.DescriptionMd).HasColumnName("description_md");
            entity.Property(e => e.DueDate)
                .HasPrecision(3)
                .HasColumnName("due_date");
            entity.Property(e => e.MaxScore)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("max_score");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");

            entity.HasOne(d => d.Class).WithMany(p => p.Assignments)
                .HasForeignKey(d => d.ClassId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__assignmen__class__57DD0BE4");

            entity.HasOne(d => d.Lesson).WithMany(p => p.Assignments)
                .HasForeignKey(d => d.LessonId)
                .HasConstraintName("FK_Assignment_Lesson");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.Assignments)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__assignmen__creat__5BAD9CC8");
        });

        modelBuilder.Entity<AssignmentRubricCriterion>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__assignme__3213E83F0347BA3C");

            entity.ToTable("assignment_rubric_criterion", tb => tb.HasTrigger("trg_rubric_weight_check"));

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AssignmentId).HasColumnName("assignment_id");
            entity.Property(e => e.MaxScore)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("max_score");
            entity.Property(e => e.Name)
                .HasMaxLength(150)
                .HasColumnName("name");
            entity.Property(e => e.OrderNo).HasColumnName("order_no");
            entity.Property(e => e.WeightPercent)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("weight_percent");

            entity.HasOne(d => d.Assignment).WithMany(p => p.AssignmentRubricCriteria)
                .HasForeignKey(d => d.AssignmentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__assignmen__assig__607251E5");
        });

        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__audit_lo__3213E83FEFF1FF34");

            entity.ToTable("audit_log");

            entity.HasIndex(e => e.ActorId, "idx_audit_log_actor");

            entity.HasIndex(e => new { e.ResourceType, e.ResourceId }, "idx_audit_log_resource");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ActionType)
                .HasMaxLength(100)
                .HasColumnName("action_type");
            entity.Property(e => e.ActorId).HasColumnName("actor_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.Metadata).HasColumnName("metadata");
            entity.Property(e => e.ResourceId).HasColumnName("resource_id");
            entity.Property(e => e.ResourceType)
                .HasMaxLength(100)
                .HasColumnName("resource_type");

            entity.HasOne(d => d.Actor).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.ActorId)
                .HasConstraintName("FK__audit_log__actor__2BC97F7C");
        });

        modelBuilder.Entity<BackgroundJobLog>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__backgrou__3213E83F08415B1A");

            entity.ToTable("background_job_log");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ErrorMessage).HasColumnName("error_message");
            entity.Property(e => e.FinishedAt)
                .HasPrecision(3)
                .HasColumnName("finished_at");
            entity.Property(e => e.JobName)
                .HasMaxLength(100)
                .HasColumnName("job_name");
            entity.Property(e => e.StartedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("started_at");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("RUNNING")
                .HasColumnName("status");
        });

        modelBuilder.Entity<Class>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__class__3213E83F2BF6B354");

            entity.ToTable("class");

            entity.HasIndex(e => e.CourseId, "idx_class_course");

            entity.HasIndex(e => e.TeacherId, "idx_class_teacher");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Capacity).HasColumnName("capacity");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.EndDate).HasColumnName("end_date");
            entity.Property(e => e.Name)
                .HasMaxLength(150)
                .HasColumnName("name");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("price");
            entity.Property(e => e.StartDate).HasColumnName("start_date");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("PLANNED")
                .HasColumnName("status");
            entity.Property(e => e.TeacherId).HasColumnName("teacher_id");

            entity.HasOne(d => d.Course).WithMany(p => p.Classes)
                .HasForeignKey(d => d.CourseId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__class__course_id__208CD6FA");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.ClassCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__class__created_b__2739D489");

            entity.HasOne(d => d.Teacher).WithMany(p => p.ClassTeachers)
                .HasForeignKey(d => d.TeacherId)
                .HasConstraintName("FK__class__teacher_i__2180FB33");
        });

        modelBuilder.Entity<ClassMaterial>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__class_ma__3213E83F72C377D6");

            entity.ToTable("class_material");

            entity.HasIndex(e => e.ClassId, "idx_class_material_class");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Body).HasColumnName("body");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.FileUrl)
                .HasMaxLength(500)
                .HasColumnName("file_url");
            entity.Property(e => e.TeacherId).HasColumnName("teacher_id");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");

            entity.HasOne(d => d.Class).WithMany(p => p.ClassMaterials)
                .HasForeignKey(d => d.ClassId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__class_mat__class__3493CFA7");

            entity.HasOne(d => d.Teacher).WithMany(p => p.ClassMaterials)
                .HasForeignKey(d => d.TeacherId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__class_mat__teach__3587F3E0");
        });

        modelBuilder.Entity<Course>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__course__3213E83FC916FB12");

            entity.ToTable("course", tb =>
                {
                    tb.HasTrigger("trg_course_publishable");
                    tb.HasTrigger("trg_course_updated_at");
                });

            entity.HasIndex(e => e.CourseGroupId, "idx_course_group_id");

            entity.HasIndex(e => new { e.CourseGroupId, e.Title }, "uq_course_title_in_group").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CourseGroupId).HasColumnName("course_group_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.DeletedAt)
                .HasPrecision(3)
                .HasColumnName("deleted_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("price");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");
            entity.Property(e => e.UpdatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("updated_at");
            entity.Property(e => e.Version)
                .HasDefaultValue(1)
                .HasColumnName("version");

            entity.HasOne(d => d.CourseGroup).WithMany(p => p.Courses)
                .HasForeignKey(d => d.CourseGroupId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__course__course_g__4D94879B");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.Courses)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__course__created___534D60F1");
        });

        modelBuilder.Entity<CourseContentVersion>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__course_c__3213E83FFD4101E9");

            entity.ToTable("course_content_version");

            entity.HasIndex(e => new { e.CourseId, e.VersionNo }, "uq_course_version").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ChangeNote).HasColumnName("change_note");
            entity.Property(e => e.ChangedBy).HasColumnName("changed_by");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.SnapshotJson).HasColumnName("snapshot_json");
            entity.Property(e => e.VersionNo).HasColumnName("version_no");

            entity.HasOne(d => d.ChangedByNavigation).WithMany(p => p.CourseContentVersions)
                .HasForeignKey(d => d.ChangedBy)
                .HasConstraintName("FK__course_co__chang__5AEE82B9");

            entity.HasOne(d => d.Course).WithMany(p => p.CourseContentVersions)
                .HasForeignKey(d => d.CourseId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__course_co__cours__59063A47");
        });

        modelBuilder.Entity<CourseGroup>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__course_g__3213E83FDAD1597A");

            entity.ToTable("course_group", tb => tb.HasTrigger("trg_course_group_updated_at"));

            entity.HasIndex(e => e.Name, "uq_course_group_name").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.Name)
                .HasMaxLength(150)
                .HasColumnName("name");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("ACTIVE")
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.CourseGroups)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__course_gr__creat__403A8C7D");
        });

        modelBuilder.Entity<CourseGroupMember>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__course_g__3213E83F8750206A");

            entity.ToTable("course_group_member");

            entity.HasIndex(e => e.UserId, "idx_course_group_member_user");

            entity.HasIndex(e => new { e.CourseGroupId, e.UserId, e.RoleInGroup }, "uq_group_member").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AssignedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("assigned_at");
            entity.Property(e => e.AssignedBy).HasColumnName("assigned_by");
            entity.Property(e => e.CourseGroupId).HasColumnName("course_group_id");
            entity.Property(e => e.RoleInGroup)
                .HasMaxLength(20)
                .HasColumnName("role_in_group");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.AssignedByNavigation).WithMany(p => p.CourseGroupMemberAssignedByNavigations)
                .HasForeignKey(d => d.AssignedBy)
                .HasConstraintName("FK__course_gr__assig__48CFD27E");

            entity.HasOne(d => d.CourseGroup).WithMany(p => p.CourseGroupMembers)
                .HasForeignKey(d => d.CourseGroupId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__course_gr__cours__45F365D3");

            entity.HasOne(d => d.User).WithMany(p => p.CourseGroupMemberUsers)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__course_gr__user___46E78A0C");
        });

        modelBuilder.Entity<Enrollment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__enrollme__3213E83F92B6D759");

            entity.ToTable("enrollment");

            entity.HasIndex(e => e.ClassId, "idx_enrollment_class");

            entity.HasIndex(e => e.Status, "idx_enrollment_status");

            entity.HasIndex(e => e.StudentId, "idx_enrollment_student");

            entity.HasIndex(e => new { e.StudentId, e.ClassId }, "uq_enrollment_student_class")
                .IsUnique()
                .HasFilter("([class_id] IS NOT NULL)");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.EnrolledAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("enrolled_at");
            entity.Property(e => e.EnrollmentType)
                .HasMaxLength(2)
                .HasColumnName("enrollment_type");
            entity.Property(e => e.ExpiresAt)
                .HasPrecision(3)
                .HasColumnName("expires_at");
            entity.Property(e => e.ProgressPercent)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("progress_percent");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("ACTIVE")
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.SubscriptionPackageId).HasColumnName("subscription_package_id");

            entity.HasOne(d => d.Class).WithMany(p => p.Enrollments)
                .HasForeignKey(d => d.ClassId)
                .HasConstraintName("FK__enrollmen__class__3C34F16F");

            entity.HasOne(d => d.Course).WithMany(p => p.Enrollments)
                .HasForeignKey(d => d.CourseId)
                .HasConstraintName("FK__enrollmen__cours__3B40CD36");

            entity.HasOne(d => d.Student).WithMany(p => p.Enrollments)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__enrollmen__stude__395884C4");

            entity.HasOne(d => d.SubscriptionPackage).WithMany(p => p.Enrollments)
                .HasForeignKey(d => d.SubscriptionPackageId)
                .HasConstraintName("FK__enrollmen__subsc__3D2915A8");
        });

        modelBuilder.Entity<Flashcard>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__flashcar__3213E83F6F93821F");

            entity.ToTable("flashcard");

            entity.HasIndex(e => e.DeckId, "idx_flashcard_deck_id");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.BackText).HasColumnName("back_text");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.DeckId).HasColumnName("deck_id");
            entity.Property(e => e.FrontText).HasColumnName("front_text");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("ACTIVE")
                .HasColumnName("status");

            entity.HasOne(d => d.Deck).WithMany(p => p.Flashcards)
                .HasForeignKey(d => d.DeckId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__flashcard__deck___160F4887");
        });

        modelBuilder.Entity<FlashcardDeck>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__flashcar__3213E83F0C36B623");

            entity.ToTable("flashcard_deck");

            entity.HasIndex(e => e.CourseId, "idx_flashcard_deck_course");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Category)
                .HasMaxLength(100)
                .HasColumnName("category");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.ModuleId).HasColumnName("module_id");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");

            entity.HasOne(d => d.Course).WithMany(p => p.FlashcardDecks)
                .HasForeignKey(d => d.CourseId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__flashcard__cours__0E6E26BF");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.FlashcardDecks)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__flashcard__creat__123EB7A3");

            entity.HasOne(d => d.Module).WithMany(p => p.FlashcardDecks)
                .HasForeignKey(d => d.ModuleId)
                .HasConstraintName("FK__flashcard__modul__0F624AF8");
        });

        modelBuilder.Entity<FlashcardReviewLog>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__flashcar__3213E83F79B14B0F");

            entity.ToTable("flashcard_review_log");

            entity.HasIndex(e => e.StudentId, "idx_flashcard_review_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.FlashcardId).HasColumnName("flashcard_id");
            entity.Property(e => e.MemoryState)
                .HasMaxLength(20)
                .HasColumnName("memory_state");
            entity.Property(e => e.NextReviewAt)
                .HasPrecision(3)
                .HasColumnName("next_review_at");
            entity.Property(e => e.ReviewedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("reviewed_at");
            entity.Property(e => e.StudentId).HasColumnName("student_id");

            entity.HasOne(d => d.Flashcard).WithMany(p => p.FlashcardReviewLogs)
                .HasForeignKey(d => d.FlashcardId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__flashcard__flash__1AD3FDA4");

            entity.HasOne(d => d.Student).WithMany(p => p.FlashcardReviewLogs)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__flashcard__stude__1BC821DD");
        });

        modelBuilder.Entity<KnowledgeGapAnalysis>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__knowledg__3213E83F862D89A9");

            entity.ToTable("knowledge_gap_analysis");

            entity.HasIndex(e => e.StudentId, "idx_knowledge_gap_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CacheExpiresAt)
                .HasPrecision(3)
                .HasColumnName("cache_expires_at");
            entity.Property(e => e.GeneratedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("generated_at");
            entity.Property(e => e.Roadmap).HasColumnName("roadmap");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.WeakTopics).HasColumnName("weak_topics");

            entity.HasOne(d => d.Student).WithMany(p => p.KnowledgeGapAnalyses)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__knowledge__stude__1E6F845E");
        });

        modelBuilder.Entity<LearningProgress>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__learning__3213E83FB6D65E8C");

            entity.ToTable("learning_progress");

            entity.HasIndex(e => e.ClassId, "idx_learning_progress_class");

            entity.HasIndex(e => e.StudentId, "idx_learning_progress_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ActivityType)
                .HasMaxLength(20)
                .HasColumnName("activity_type");
            entity.Property(e => e.AttemptCount).HasColumnName("attempt_count");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.CompletionStatus)
                .HasMaxLength(20)
                .HasDefaultValue("NOT_STARTED")
                .HasColumnName("completion_status");
            entity.Property(e => e.LastActiveAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("last_active_at");
            entity.Property(e => e.LessonId).HasColumnName("lesson_id");
            entity.Property(e => e.Score)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("score");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.TimeSpentSeconds).HasColumnName("time_spent_seconds");

            entity.HasOne(d => d.Class).WithMany(p => p.LearningProgresses)
                .HasForeignKey(d => d.ClassId)
                .HasConstraintName("FK__learning___class__00DF2177");

            entity.HasOne(d => d.Lesson).WithMany(p => p.LearningProgresses)
                .HasForeignKey(d => d.LessonId)
                .HasConstraintName("FK__learning___lesso__01D345B0");

            entity.HasOne(d => d.Student).WithMany(p => p.LearningProgresses)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__learning___stude__7FEAFD3E");
        });

        modelBuilder.Entity<Lesson>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__lesson__3213E83F682DE93F");

            entity.ToTable("lesson", tb => tb.HasTrigger("trg_lesson_updated_at"));

            entity.HasIndex(e => e.ModuleId, "idx_lesson_module");

            entity.HasIndex(e => new { e.ModuleId, e.OrderNo }, "uq_lesson_order").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.ModuleId).HasColumnName("module_id");
            entity.Property(e => e.OrderNo).HasColumnName("order_no");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");
            entity.Property(e => e.Summary).HasColumnName("summary");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");
            entity.Property(e => e.UpdatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("updated_at");
            entity.Property(e => e.VideoUrl)
                .HasMaxLength(500)
                .HasColumnName("video_url");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.Lessons)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__lesson__created___6754599E");

            entity.HasOne(d => d.Module).WithMany(p => p.Lessons)
                .HasForeignKey(d => d.ModuleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__lesson__module_i__6477ECF3");
        });

        modelBuilder.Entity<LessonViewEvent>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__lesson_v__3213E83FB277212C");

            entity.ToTable("lesson_view_event");

            entity.HasIndex(e => e.LessonId, "idx_lesson_view_lesson");

            entity.HasIndex(e => e.StudentId, "idx_lesson_view_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Completed).HasColumnName("completed");
            entity.Property(e => e.LessonId).HasColumnName("lesson_id");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.ViewedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("viewed_at");
            entity.Property(e => e.WatchSeconds).HasColumnName("watch_seconds");

            entity.HasOne(d => d.Lesson).WithMany(p => p.LessonViewEvents)
                .HasForeignKey(d => d.LessonId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__lesson_vi__lesso__6C190EBB");

            entity.HasOne(d => d.Student).WithMany(p => p.LessonViewEvents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__lesson_vi__stude__6D0D32F4");
        });

        modelBuilder.Entity<LoginHistory>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__login_hi__3213E83F91BB9805");

            entity.ToTable("login_history");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.IpAddress)
                .HasMaxLength(45)
                .HasColumnName("ip_address");
            entity.Property(e => e.LoginAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("login_at");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("SUCCESS")
                .HasColumnName("status");
            entity.Property(e => e.UserAgent)
                .HasMaxLength(255)
                .HasColumnName("user_agent");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.LoginHistories)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__login_his__user___38996AB5");
        });

        modelBuilder.Entity<Module>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__module__3213E83F13D7B383");

            entity.ToTable("module");

            entity.HasIndex(e => e.CourseId, "idx_module_course");

            entity.HasIndex(e => new { e.CourseId, e.OrderNo }, "uq_module_order").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.OrderNo).HasColumnName("order_no");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");

            entity.HasOne(d => d.Course).WithMany(p => p.Modules)
                .HasForeignKey(d => d.CourseId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__module__course_i__5FB337D6");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__notifica__3213E83FBE7731AC");

            entity.ToTable("notification");

            entity.HasIndex(e => new { e.UserId, e.IsRead }, "idx_notification_user");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.IsRead).HasColumnName("is_read");
            entity.Property(e => e.Message).HasColumnName("message");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");
            entity.Property(e => e.Type)
                .HasMaxLength(50)
                .HasColumnName("type");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__notificat__user___308E3499");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__payment__3213E83FB6E3211B");

            entity.ToTable("payment");

            entity.HasIndex(e => e.EnrollmentId, "idx_payment_enrollment");

            entity.HasIndex(e => e.UserId, "idx_payment_user");

            entity.HasIndex(e => e.TransactionRef, "uq_payment_transaction_ref").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Amount)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("amount");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.EnrollmentId).HasColumnName("enrollment_id");
            entity.Property(e => e.Gateway)
                .HasMaxLength(10)
                .HasColumnName("gateway");
            entity.Property(e => e.PaidAt)
                .HasPrecision(3)
                .HasColumnName("paid_at");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("PENDING")
                .HasColumnName("status");
            entity.Property(e => e.TransactionRef)
                .HasMaxLength(100)
                .HasColumnName("transaction_ref");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Enrollment).WithMany(p => p.Payments)
                .HasForeignKey(d => d.EnrollmentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__payment__enrollm__47A6A41B");

            entity.HasOne(d => d.User).WithMany(p => p.Payments)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__payment__user_id__489AC854");
        });

        modelBuilder.Entity<Question>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__question__3213E83F8774953E");

            entity.ToTable("question");

            entity.HasIndex(e => e.ModuleId, "idx_question_module");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AiExplanation).HasColumnName("ai_explanation");
            entity.Property(e => e.ApprovedBy).HasColumnName("approved_by");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.CorrectOption)
                .HasMaxLength(1)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("correct_option");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.Difficulty)
                .HasMaxLength(10)
                .HasDefaultValue("MEDIUM")
                .HasColumnName("difficulty");
            entity.Property(e => e.ModuleId).HasColumnName("module_id");
            entity.Property(e => e.OptionA)
                .HasMaxLength(500)
                .HasColumnName("option_a");
            entity.Property(e => e.OptionB)
                .HasMaxLength(500)
                .HasColumnName("option_b");
            entity.Property(e => e.OptionC)
                .HasMaxLength(500)
                .HasColumnName("option_c");
            entity.Property(e => e.OptionD)
                .HasMaxLength(500)
                .HasColumnName("option_d");
            entity.Property(e => e.Source)
                .HasMaxLength(20)
                .HasDefaultValue("MANUAL")
                .HasColumnName("source");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");

            entity.HasOne(d => d.ApprovedByNavigation).WithMany(p => p.QuestionApprovedByNavigations)
                .HasForeignKey(d => d.ApprovedBy)
                .HasConstraintName("FK__question__approv__7B5B524B");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.QuestionCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__question__create__7A672E12");

            entity.HasOne(d => d.Module).WithMany(p => p.Questions)
                .HasForeignKey(d => d.ModuleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__question__module__72C60C4A");
        });

        modelBuilder.Entity<Quiz>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__quiz__3213E83F81DC4D74");

            entity.ToTable("quiz", tb => tb.HasTrigger("trg_quiz_publishable"));

            entity.HasIndex(e => e.CourseId, "idx_quiz_course");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.Difficulty)
                .HasMaxLength(10)
                .HasDefaultValue("MEDIUM")
                .HasColumnName("difficulty");
            entity.Property(e => e.IsPracticeGenerated).HasColumnName("is_practice_generated");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.QuestionCount).HasColumnName("question_count");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");

            entity.HasOne(d => d.Course).WithMany(p => p.Quizzes)
                .HasForeignKey(d => d.CourseId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz__course_id__7F2BE32F");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.Quizzes)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__quiz__created_by__00200768");
        });

        modelBuilder.Entity<QuizAttempt>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__quiz_att__3213E83FC6D03C24");

            entity.ToTable("quiz_attempt");

            entity.HasIndex(e => e.QuizId, "idx_quiz_attempt_quiz");

            entity.HasIndex(e => e.StudentId, "idx_quiz_attempt_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.QuizId).HasColumnName("quiz_id");
            entity.Property(e => e.Score)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("score");
            entity.Property(e => e.StartTime)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("start_time");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("IN_PROGRESS")
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.SubmitTime)
                .HasPrecision(3)
                .HasColumnName("submit_time");

            entity.HasOne(d => d.Quiz).WithMany(p => p.QuizAttempts)
                .HasForeignKey(d => d.QuizId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz_atte__quiz___73852659");

            entity.HasOne(d => d.Student).WithMany(p => p.QuizAttempts)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz_atte__stude__74794A92");
        });

        modelBuilder.Entity<QuizAttemptAnswer>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__quiz_att__3213E83FF71E31A5");

            entity.ToTable("quiz_attempt_answer");

            entity.HasIndex(e => new { e.AttemptId, e.QuestionId }, "uq_attempt_question").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AttemptId).HasColumnName("attempt_id");
            entity.Property(e => e.IsCorrect).HasColumnName("is_correct");
            entity.Property(e => e.QuestionId).HasColumnName("question_id");
            entity.Property(e => e.SelectedOption)
                .HasMaxLength(1)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("selected_option");

            entity.HasOne(d => d.Attempt).WithMany(p => p.QuizAttemptAnswers)
                .HasForeignKey(d => d.AttemptId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz_atte__attem__7B264821");

            entity.HasOne(d => d.Question).WithMany(p => p.QuizAttemptAnswers)
                .HasForeignKey(d => d.QuestionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz_atte__quest__7C1A6C5A");
        });

        modelBuilder.Entity<QuizQuestion>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__quiz_que__3213E83F95559E01");

            entity.ToTable("quiz_question");

            entity.HasIndex(e => new { e.QuizId, e.QuestionId }, "uq_quiz_question").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.OrderNo).HasColumnName("order_no");
            entity.Property(e => e.QuestionId).HasColumnName("question_id");
            entity.Property(e => e.QuizId).HasColumnName("quiz_id");

            entity.HasOne(d => d.Question).WithMany(p => p.QuizQuestions)
                .HasForeignKey(d => d.QuestionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz_ques__quest__0B91BA14");

            entity.HasOne(d => d.Quiz).WithMany(p => p.QuizQuestions)
                .HasForeignKey(d => d.QuizId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__quiz_ques__quiz___0A9D95DB");
        });

        modelBuilder.Entity<RefundRequest>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__refund_r__3213E83F7C01AECA");

            entity.ToTable("refund_request");

            entity.HasIndex(e => e.PaymentId, "idx_refund_payment");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.PaymentId).HasColumnName("payment_id");
            entity.Property(e => e.Reason).HasColumnName("reason");
            entity.Property(e => e.RefundedAt)
                .HasPrecision(3)
                .HasColumnName("refunded_at");
            entity.Property(e => e.ReviewedAt)
                .HasPrecision(3)
                .HasColumnName("reviewed_at");
            entity.Property(e => e.ReviewedBy).HasColumnName("reviewed_by");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("PENDING")
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");

            entity.HasOne(d => d.Payment).WithMany(p => p.RefundRequests)
                .HasForeignKey(d => d.PaymentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__refund_re__payme__503BEA1C");

            entity.HasOne(d => d.ReviewedByNavigation).WithMany(p => p.RefundRequestReviewedByNavigations)
                .HasForeignKey(d => d.ReviewedBy)
                .HasConstraintName("FK__refund_re__revie__540C7B00");

            entity.HasOne(d => d.Student).WithMany(p => p.RefundRequestStudents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__refund_re__stude__51300E55");
        });

        modelBuilder.Entity<Submission>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__submissi__3213E83FA938D0E7");

            entity.ToTable("submission");

            entity.HasIndex(e => e.AssignmentId, "idx_submission_assignment");

            entity.HasIndex(e => e.StudentId, "idx_submission_student");

            entity.HasIndex(e => new { e.AssignmentId, e.StudentId }, "uq_submission_assignment_student").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AiScore)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("ai_score");
            entity.Property(e => e.AssignmentId).HasColumnName("assignment_id");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.Feedback).HasColumnName("feedback");
            entity.Property(e => e.FileUrl)
                .HasMaxLength(500)
                .HasColumnName("file_url");
            entity.Property(e => e.FinalScore)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("final_score");
            entity.Property(e => e.GradedAt)
                .HasPrecision(3)
                .HasColumnName("graded_at");
            entity.Property(e => e.GradedBy).HasColumnName("graded_by");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("SUBMITTED")
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.SubmittedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("submitted_at");

            entity.HasOne(d => d.Assignment).WithMany(p => p.Submissions)
                .HasForeignKey(d => d.AssignmentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__submissio__assig__671F4F74");

            entity.HasOne(d => d.GradedByNavigation).WithMany(p => p.SubmissionGradedByNavigations)
                .HasForeignKey(d => d.GradedBy)
                .HasConstraintName("FK__submissio__grade__6AEFE058");

            entity.HasOne(d => d.Student).WithMany(p => p.SubmissionStudents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__submissio__stude__681373AD");
        });

        modelBuilder.Entity<SubmissionCriterionScore>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__submissi__3213E83FD6257416");

            entity.ToTable("submission_criterion_score");

            entity.HasIndex(e => new { e.SubmissionId, e.CriterionId }, "uq_submission_criterion").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AiFeedback).HasColumnName("ai_feedback");
            entity.Property(e => e.AiScore)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("ai_score");
            entity.Property(e => e.CriterionId).HasColumnName("criterion_id");
            entity.Property(e => e.FinalScore)
                .HasColumnType("decimal(5, 2)")
                .HasColumnName("final_score");
            entity.Property(e => e.SubmissionId).HasColumnName("submission_id");
            entity.Property(e => e.TeacherFeedback).HasColumnName("teacher_feedback");

            entity.HasOne(d => d.Criterion).WithMany(p => p.SubmissionCriterionScores)
                .HasForeignKey(d => d.CriterionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__submissio__crite__70A8B9AE");

            entity.HasOne(d => d.Submission).WithMany(p => p.SubmissionCriterionScores)
                .HasForeignKey(d => d.SubmissionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__submissio__submi__6FB49575");
        });

        modelBuilder.Entity<SubscriptionPackage>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__subscrip__3213E83FEF41F850");

            entity.ToTable("subscription_package");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CourseGroupId).HasColumnName("course_group_id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.DurationDays).HasColumnName("duration_days");
            entity.Property(e => e.Name)
                .HasMaxLength(150)
                .HasColumnName("name");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("price");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("ACTIVE")
                .HasColumnName("status");

            entity.HasOne(d => d.CourseGroup).WithMany(p => p.SubscriptionPackages)
                .HasForeignKey(d => d.CourseGroupId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__subscript__cours__2BFE89A6");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.SubscriptionPackages)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__subscript__creat__30C33EC3");
        });

        modelBuilder.Entity<SystemSetting>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__system_s__3213E83F8AA4CC9B");

            entity.ToTable("system_setting");

            entity.HasIndex(e => e.SettingKey, "uq_system_setting_key").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.DisplayOrder).HasColumnName("display_order");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.SettingKey)
                .HasMaxLength(150)
                .HasColumnName("setting_key");
            entity.Property(e => e.SettingType)
                .HasMaxLength(50)
                .HasColumnName("setting_type");
            entity.Property(e => e.SettingValue).HasColumnName("setting_value");
            entity.Property(e => e.UpdatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("updated_at");
            entity.Property(e => e.UpdatedBy).HasColumnName("updated_by");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.SystemSettings)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK__system_se__updat__27F8EE98");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__users__3213E83FCDC96261");

            entity.ToTable("users", tb => tb.HasTrigger("trg_users_updated_at"));

            entity.HasIndex(e => e.Role, "idx_users_role");

            entity.HasIndex(e => e.Email, "uq_users_email").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AvatarUrl)
                .HasMaxLength(500)
                .HasColumnName("avatar_url");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.DeletedAt)
                .HasPrecision(3)
                .HasColumnName("deleted_at");
            entity.Property(e => e.Email)
                .HasMaxLength(150)
                .HasColumnName("email");
            entity.Property(e => e.FailedLoginCount).HasColumnName("failed_login_count");
            entity.Property(e => e.FullName)
                .HasMaxLength(150)
                .HasColumnName("full_name");
            entity.Property(e => e.LockedUntil)
                .HasPrecision(3)
                .HasColumnName("locked_until");
            entity.Property(e => e.PasswordHash)
                .HasMaxLength(255)
                .HasColumnName("password_hash");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .HasColumnName("phone");
            entity.Property(e => e.Role)
                .HasMaxLength(20)
                .HasColumnName("role");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("ACTIVE")
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.InverseCreatedByNavigation)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK__users__created_b__29572725");
        });

        modelBuilder.Entity<UserOauthIdentity>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__user_oau__3213E83FC81FC47C");

            entity.ToTable("user_oauth_identity");

            entity.HasIndex(e => new { e.Provider, e.ProviderUserId }, "uq_oauth_provider_user").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("created_at");
            entity.Property(e => e.Provider)
                .HasMaxLength(30)
                .HasDefaultValue("GOOGLE")
                .HasColumnName("provider");
            entity.Property(e => e.ProviderUserId)
                .HasMaxLength(255)
                .HasColumnName("provider_user_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.UserOauthIdentities)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__user_oaut__user___2F10007B");
        });

        modelBuilder.Entity<UserSession>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__user_ses__3213E83F0C1FBA22");

            entity.ToTable("user_session");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("(newid())")
                .HasColumnName("id");
            entity.Property(e => e.DeviceInfo)
                .HasMaxLength(255)
                .HasColumnName("device_info");
            entity.Property(e => e.ExpiresAt)
                .HasPrecision(3)
                .HasColumnName("expires_at");
            entity.Property(e => e.IssuedAt)
                .HasPrecision(3)
                .HasDefaultValueSql("(sysdatetimeoffset())")
                .HasColumnName("issued_at");
            entity.Property(e => e.RefreshTokenHash)
                .HasMaxLength(255)
                .HasColumnName("refresh_token_hash");
            entity.Property(e => e.RevokedAt)
                .HasPrecision(3)
                .HasColumnName("revoked_at");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.UserSessions)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__user_sess__user___34C8D9D1");
        });

        modelBuilder.Entity<VClassOverviewReport>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("v_class_overview_report");

            entity.Property(e => e.AvgProgress)
                .HasColumnType("decimal(38, 6)")
                .HasColumnName("avg_progress");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.ClassName)
                .HasMaxLength(150)
                .HasColumnName("class_name");
            entity.Property(e => e.InactiveStudents).HasColumnName("inactive_students");
            entity.Property(e => e.TotalStudents).HasColumnName("total_students");
        });

        modelBuilder.Entity<VContentQualityReport>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("v_content_quality_report");

            entity.Property(e => e.AvgWatchSeconds).HasColumnName("avg_watch_seconds");
            entity.Property(e => e.CourseId).HasColumnName("course_id");
            entity.Property(e => e.DropRate)
                .HasColumnType("decimal(21, 15)")
                .HasColumnName("drop_rate");
            entity.Property(e => e.LessonId).HasColumnName("lesson_id");
            entity.Property(e => e.LessonTitle)
                .HasMaxLength(255)
                .HasColumnName("lesson_title");
            entity.Property(e => e.ViewCount).HasColumnName("view_count");
        });

        modelBuilder.Entity<VRevenueReport>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("v_revenue_report");

            entity.Property(e => e.CourseGroupId).HasColumnName("course_group_id");
            entity.Property(e => e.CourseGroupName)
                .HasMaxLength(150)
                .HasColumnName("course_group_name");
            entity.Property(e => e.PaymentCount).HasColumnName("payment_count");
            entity.Property(e => e.Period).HasColumnName("period");
            entity.Property(e => e.TotalRevenue)
                .HasColumnType("decimal(38, 2)")
                .HasColumnName("total_revenue");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
