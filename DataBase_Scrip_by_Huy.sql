/* =====================================================================
   EduNexus — Database Schema for Microsoft SQL Server (T-SQL)
   Engine: SQL Server 2019+ / Azure SQL

   GHI CHÚ CHUYỂN ĐỔI ENGINE (đọc trước khi chạy):
   1. ENUM -> NVARCHAR + CHECK constraint (SQL Server không có kiểu ENUM).
   2. BIGSERIAL -> BIGINT IDENTITY(1,1).
   3. UUID/gen_random_uuid() -> UNIQUEIDENTIFIER/NEWID().
   4. TIMESTAMPTZ/now() -> DATETIMEOFFSET(3)/SYSDATETIMEOFFSET().
   5. BOOLEAN true/false -> BIT 1/0.
   6. JSONB -> NVARCHAR(MAX) + CHECK(ISJSON(col)=1). Có thể tạo computed
      column + index riêng cho từng JSON path hay truy vấn nhiều (xem cuối file).
   7. TEXT/VARCHAR(Unicode) -> dùng NVARCHAR thống nhất để hỗ trợ tiếng Việt
      (NFR-I02), thay vì VARCHAR như bản Postgres (Postgres VARCHAR mặc định
      đã là UTF-8 nên không cần phân biệt N-prefix).
   8. ON DELETE CASCADE: bản Postgres dùng CASCADE nhiều tầng (course -> module
      -> lesson, course -> quiz -> quiz_question, course -> module -> question
      -> quiz_question...). SQL Server CHẶN khai báo nhiều "cascade path" hội
      tụ vào cùng 1 bảng từ cùng 1 bảng gốc (lỗi: "may cause cycles or multiple
      cascade paths"). Vì schema này có nhiều đường hội tụ kiểu "kim cương"
      (diamond) như trên, để AN TOÀN và ĐƠN GIẢN, toàn bộ FK trong file này
      dùng NO ACTION (mặc định, không cascade). Việc dọn dữ liệu con khi xoá
      cha (hard delete) cần xử lý ở application layer hoặc qua stored
      procedure dọn dẹp theo thứ tự, hoặc — khuyến nghị — dùng soft delete
      (deleted_at) thay vì xoá thật, đúng với pattern đã có trong thiết kế.
   9. Trigger PL/pgSQL theo dòng (FOR EACH ROW) -> Trigger T-SQL theo tập
      (set-based) trên bảng ảo inserted/deleted, không có DECLARE...BEGIN...$$.
  10. Nhiều CREATE TRIGGER / CREATE VIEW phải tách batch bằng GO (SQL Server
      yêu cầu các lệnh này là statement duy nhất trong batch).

	  Database Name: EduNexus_New_02
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =====================================================================
-- 1. USER MANAGER
-- =====================================================================
CREATE TABLE users (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    full_name           NVARCHAR(150) NOT NULL,
    email               NVARCHAR(150) NOT NULL,
    password_hash       NVARCHAR(255) NULL,                 -- NULL nếu chỉ login Google OAuth
    role                NVARCHAR(20) NOT NULL
        CONSTRAINT ck_users_role CHECK (role IN ('ADMIN','SME','COURSE_MANAGER','TEACHER','STUDENT')),
    status              NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CONSTRAINT ck_users_status CHECK (status IN ('ACTIVE','LOCKED','INACTIVE')),
    avatar_url          NVARCHAR(500) NULL,
    phone               NVARCHAR(20) NULL,
    failed_login_count  INT NOT NULL DEFAULT 0,
    locked_until        DATETIMEOFFSET(3) NULL,
    created_by          BIGINT NULL REFERENCES users(id),
    created_at          DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at          DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    deleted_at          DATETIMEOFFSET(3) NULL,
    CONSTRAINT uq_users_email UNIQUE (email)
);
GO
-- Tất cả người dùng có tài khoản: Admin, SME, Course Manager, Teacher, Student. Guest không lưu ở đây.

CREATE TABLE user_oauth_identity (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES users(id),
    provider            NVARCHAR(30) NOT NULL DEFAULT 'GOOGLE',
    provider_user_id    NVARCHAR(255) NOT NULL,
    created_at          DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_oauth_provider_user UNIQUE (provider, provider_user_id)
);
GO

CREATE TABLE user_session (
    id                      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    user_id                 BIGINT NOT NULL REFERENCES users(id),
    refresh_token_hash      NVARCHAR(255) NOT NULL,
    device_info             NVARCHAR(255) NULL,
    issued_at               DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    expires_at              DATETIMEOFFSET(3) NOT NULL,
    revoked_at              DATETIMEOFFSET(3) NULL
);
GO
-- Refresh token rotation; JOB-03 huỷ phiên khi account bị deactivate -> set revoked_at.

CREATE TABLE login_history (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    ip_address  NVARCHAR(45) NULL,
    user_agent  NVARCHAR(255) NULL,
    login_at    DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    status      NVARCHAR(20) NOT NULL DEFAULT 'SUCCESS'
);
GO

-- =====================================================================
-- 2. CONTENT MANAGER
-- =====================================================================
CREATE TABLE course_group (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(150) NOT NULL,
    description NVARCHAR(MAX) NULL,
    status      NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CONSTRAINT ck_course_group_status CHECK (status IN ('ACTIVE','ARCHIVED')),
    created_by  BIGINT NULL REFERENCES users(id),
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_course_group_name UNIQUE (name)
);
GO

CREATE TABLE course_group_member (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_group_id     BIGINT NOT NULL REFERENCES course_group(id),
    user_id             BIGINT NOT NULL REFERENCES users(id),
    role_in_group       NVARCHAR(20) NOT NULL
        CONSTRAINT ck_group_member_role CHECK (role_in_group IN ('COURSE_MANAGER','SME')),
    assigned_by         BIGINT NULL REFERENCES users(id),
    assigned_at         DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_group_member UNIQUE (course_group_id, user_id, role_in_group)
);
GO
-- GB-01: phạm vi phân công Course Manager / SME theo Course Group.

CREATE TABLE course (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_group_id BIGINT NOT NULL REFERENCES course_group(id),
    title           NVARCHAR(255) NOT NULL,
    description     NVARCHAR(MAX) NULL,
    price           DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),  -- Giá H1: mua lẻ 1 khoá học
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT ck_course_status CHECK (status IN ('DRAFT','PENDING_REVIEW','PUBLISHED','ARCHIVED')),
    version         INT NOT NULL DEFAULT 1,
    created_by      BIGINT NULL REFERENCES users(id),
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    deleted_at      DATETIMEOFFSET(3) NULL,
    CONSTRAINT uq_course_title_in_group UNIQUE (course_group_id, title)
);
GO

CREATE TABLE course_content_version (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_id       BIGINT NOT NULL REFERENCES course(id),
    version_no      INT NOT NULL,
    snapshot_json   NVARCHAR(MAX) NOT NULL CHECK (ISJSON(snapshot_json) = 1),
    changed_by      BIGINT NULL REFERENCES users(id),
    change_note     NVARCHAR(MAX) NULL,
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_course_version UNIQUE (course_id, version_no)
);
GO

CREATE TABLE module (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_id   BIGINT NOT NULL REFERENCES course(id),
    title       NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX) NULL,
    order_no    INT NOT NULL,
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_module_order UNIQUE (course_id, order_no)
);
GO

CREATE TABLE lesson (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    module_id   BIGINT NOT NULL REFERENCES module(id),
    title       NVARCHAR(255) NOT NULL,
    video_url   NVARCHAR(500) NULL,
    summary     NVARCHAR(MAX) NULL,
    content     NVARCHAR(MAX) NOT NULL,
    status      NVARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT ck_lesson_status CHECK (status IN ('DRAFT','PUBLISHED')),
    order_no    INT NOT NULL,
    created_by  BIGINT NULL REFERENCES users(id),
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_lesson_order UNIQUE (module_id, order_no)
);
GO

CREATE TABLE lesson_view_event (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    lesson_id       BIGINT NOT NULL REFERENCES lesson(id),
    student_id      BIGINT NOT NULL REFERENCES users(id),
    viewed_at       DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    watch_seconds   INT NOT NULL DEFAULT 0,
    completed       BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE question (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    module_id       BIGINT NOT NULL REFERENCES module(id),
    content         NVARCHAR(MAX) NOT NULL,
    option_a        NVARCHAR(500) NOT NULL,
    option_b        NVARCHAR(500) NOT NULL,
    option_c        NVARCHAR(500) NOT NULL,
    option_d        NVARCHAR(500) NOT NULL,
    correct_option  CHAR(1) NOT NULL CHECK (correct_option IN ('A','B','C','D')),
    difficulty      NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM'
        CONSTRAINT ck_question_difficulty CHECK (difficulty IN ('EASY','MEDIUM','HARD')),
    ai_explanation  NVARCHAR(MAX) NULL,
    source          NVARCHAR(20) NOT NULL DEFAULT 'MANUAL'
        CONSTRAINT ck_question_source CHECK (source IN ('MANUAL','AI_GENERATED')),
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT ck_question_status CHECK (status IN ('DRAFT','APPROVED','REJECTED')),
    created_by      BIGINT NULL REFERENCES users(id),
    approved_by     BIGINT NULL REFERENCES users(id),
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE quiz (
    id                      BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_id               BIGINT NOT NULL REFERENCES course(id),
    created_by              BIGINT NULL REFERENCES users(id),
    name                    NVARCHAR(255) NOT NULL,
    difficulty              NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM'
        CONSTRAINT ck_quiz_difficulty CHECK (difficulty IN ('EASY','MEDIUM','HARD')),
    question_count          INT NOT NULL DEFAULT 0,
    status                  NVARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT ck_quiz_status CHECK (status IN ('DRAFT','PUBLISHED')),
    is_practice_generated   BIT NOT NULL DEFAULT 0,  -- 1 = quiz tự sinh khi Student luyện tập (SCR-14)
    created_at              DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE quiz_question (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    quiz_id     BIGINT NOT NULL REFERENCES quiz(id),
    question_id BIGINT NOT NULL REFERENCES question(id),
    order_no    INT NOT NULL,
    CONSTRAINT uq_quiz_question UNIQUE (quiz_id, question_id)
);
GO

CREATE TABLE flashcard_deck (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_id   BIGINT NOT NULL REFERENCES course(id),
    module_id   BIGINT NULL REFERENCES module(id),
    name        NVARCHAR(255) NOT NULL,
    category    NVARCHAR(100) NULL,
    status      NVARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT ck_deck_status CHECK (status IN ('DRAFT','PUBLISHED')),
    created_by  BIGINT NULL REFERENCES users(id),
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE flashcard (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    deck_id     BIGINT NOT NULL REFERENCES flashcard_deck(id),
    front_text  NVARCHAR(MAX) NOT NULL,
    back_text   NVARCHAR(MAX) NOT NULL,
    status      NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE flashcard_review_log (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    flashcard_id    BIGINT NOT NULL REFERENCES flashcard(id),
    student_id      BIGINT NOT NULL REFERENCES users(id),
    memory_state    NVARCHAR(20) NOT NULL
        CONSTRAINT ck_memory_state CHECK (memory_state IN ('FORGOT','REMEMBERED','MASTERED')),
    reviewed_at     DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    next_review_at  DATETIMEOFFSET(3) NULL
);
GO

-- =====================================================================
-- 3. CLASSROOM & BUSINESS
-- =====================================================================
CREATE TABLE class (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_id   BIGINT NOT NULL REFERENCES course(id),
    teacher_id  BIGINT NULL REFERENCES users(id),
    name        NVARCHAR(150) NOT NULL,
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    capacity    INT NOT NULL CHECK (capacity > 0),
    price       DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),  -- Giá H2: đăng ký lớp có giáo viên
    status      NVARCHAR(20) NOT NULL DEFAULT 'PLANNED'
        CONSTRAINT ck_class_status CHECK (status IN ('PLANNED','ACTIVE','COMPLETED','EXPIRED','CLOSED')),
    created_by  BIGINT NULL REFERENCES users(id),
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT chk_class_dates CHECK (end_date > start_date)
);
GO

CREATE TABLE subscription_package (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    course_group_id BIGINT NOT NULL REFERENCES course_group(id),
    name            NVARCHAR(150) NOT NULL,
    price           DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    duration_days   INT NOT NULL CHECK (duration_days > 0),
    status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CONSTRAINT ck_package_status CHECK (status IN ('ACTIVE','INACTIVE')),
    created_by      BIGINT NULL REFERENCES users(id),
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Gói Membership (Enrollment Type H3) theo Course Group.

CREATE TABLE class_material (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    class_id    BIGINT NOT NULL REFERENCES class(id),
    teacher_id  BIGINT NOT NULL REFERENCES users(id),
    title       NVARCHAR(255) NOT NULL,
    body        NVARCHAR(MAX) NULL,
    file_url    NVARCHAR(500) NULL,
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE enrollment (
    id                      BIGINT IDENTITY(1,1) PRIMARY KEY,
    student_id              BIGINT NOT NULL REFERENCES users(id),
    enrollment_type         NVARCHAR(2) NOT NULL
        CONSTRAINT ck_enrollment_type CHECK (enrollment_type IN ('H1','H2','H3')),
    course_id               BIGINT NULL REFERENCES course(id),
    class_id                BIGINT NULL REFERENCES class(id),
    subscription_package_id BIGINT NULL REFERENCES subscription_package(id),
    status                  NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CONSTRAINT ck_enrollment_status CHECK (status IN ('ACTIVE','COMPLETED','CANCELLED','EXPIRED')),
    enrolled_at             DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    expires_at              DATETIMEOFFSET(3) NULL,
    progress_percent        DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    created_at              DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT chk_enrollment_exactly_one CHECK (
        (enrollment_type = 'H1' AND course_id IS NOT NULL AND class_id IS NULL AND subscription_package_id IS NULL) OR
        (enrollment_type = 'H2' AND class_id IS NOT NULL AND course_id IS NULL AND subscription_package_id IS NULL) OR
        (enrollment_type = 'H3' AND subscription_package_id IS NOT NULL AND course_id IS NULL AND class_id IS NULL)
    )
);
GO
-- GIẢ ĐỊNH (xem mục Mâu thuẫn #4 trong design doc): H1=mua lẻ course, H2=đăng ký class, H3=gói membership.
CREATE UNIQUE INDEX uq_enrollment_student_class ON enrollment(student_id, class_id) WHERE class_id IS NOT NULL;
GO

CREATE TABLE payment (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    enrollment_id       BIGINT NOT NULL REFERENCES enrollment(id),
    user_id             BIGINT NOT NULL REFERENCES users(id),
    amount              DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    gateway             NVARCHAR(10) NOT NULL
        CONSTRAINT ck_payment_gateway CHECK (gateway IN ('VNPAY','SEPAY')),
    status              NVARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT ck_payment_status CHECK (status IN ('PENDING','PAID','FAILED','REFUNDED')),
    transaction_ref     NVARCHAR(100) NULL,
    paid_at             DATETIMEOFFSET(3) NULL,
    created_at          DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_payment_transaction_ref UNIQUE (transaction_ref)
);
GO

CREATE TABLE refund_request (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    payment_id      BIGINT NOT NULL REFERENCES payment(id),
    student_id      BIGINT NOT NULL REFERENCES users(id),
    reason          NVARCHAR(MAX) NOT NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT ck_refund_status CHECK (status IN ('PENDING','APPROVED','REJECTED','COMPLETED')),
    reviewed_by     BIGINT NULL REFERENCES users(id),
    reviewed_at     DATETIMEOFFSET(3) NULL,
    refunded_at     DATETIMEOFFSET(3) NULL,
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

-- =====================================================================
-- 4. LEARNING (Assignment / Submission / Quiz Attempt / Progress)
-- =====================================================================
CREATE TABLE assignment (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    class_id        BIGINT NOT NULL REFERENCES class(id),
    lesson_id       BIGINT NULL REFERENCES lesson(id),
    title           NVARCHAR(255) NOT NULL,
    description_md  NVARCHAR(MAX) NULL,
    max_score       DECIMAL(5,2) NOT NULL CHECK (max_score > 0),
    due_date        DATETIMEOFFSET(3) NOT NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT ck_assignment_status CHECK (status IN ('DRAFT','PUBLISHED','CLOSED')),
    created_by      BIGINT NULL REFERENCES users(id),
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT chk_assignment_due_after_create CHECK (due_date > created_at)
);
GO

CREATE TABLE assignment_rubric_criterion (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    assignment_id   BIGINT NOT NULL REFERENCES assignment(id),
    name            NVARCHAR(150) NOT NULL,
    max_score       DECIMAL(5,2) NOT NULL CHECK (max_score > 0),
    weight_percent  DECIMAL(5,2) NOT NULL CHECK (weight_percent > 0 AND weight_percent <= 100),
    order_no        INT NOT NULL DEFAULT 0
);
GO

CREATE TABLE submission (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    assignment_id   BIGINT NOT NULL REFERENCES assignment(id),
    student_id      BIGINT NOT NULL REFERENCES users(id),
    content         NVARCHAR(MAX) NULL,
    file_url        NVARCHAR(500) NULL,
    final_score     DECIMAL(5,2) NULL,
    ai_score        DECIMAL(5,2) NULL,
    feedback        NVARCHAR(MAX) NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'SUBMITTED'
        CONSTRAINT ck_submission_status CHECK (status IN ('SUBMITTED','AI_GRADED','GRADED')),
    graded_by       BIGINT NULL REFERENCES users(id),
    graded_at       DATETIMEOFFSET(3) NULL,
    submitted_at    DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_submission_assignment_student UNIQUE (assignment_id, student_id)
    -- Mỗi student chỉ nộp 1 bài / assignment (resubmit = update, không tạo row mới).
);
GO

CREATE TABLE submission_criterion_score (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    submission_id       BIGINT NOT NULL REFERENCES submission(id),
    criterion_id        BIGINT NOT NULL REFERENCES assignment_rubric_criterion(id),
    ai_score            DECIMAL(5,2) NULL,
    final_score         DECIMAL(5,2) NULL,
    ai_feedback         NVARCHAR(MAX) NULL,
    teacher_feedback    NVARCHAR(MAX) NULL,
    CONSTRAINT uq_submission_criterion UNIQUE (submission_id, criterion_id)
);
GO

CREATE TABLE quiz_attempt (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    quiz_id     BIGINT NOT NULL REFERENCES quiz(id),
    student_id  BIGINT NOT NULL REFERENCES users(id),
    start_time  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    submit_time DATETIMEOFFSET(3) NULL,
    score       DECIMAL(5,2) NULL,
    status      NVARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS'
        CONSTRAINT ck_quiz_attempt_status CHECK (status IN ('IN_PROGRESS','SUBMITTED'))
);
GO

CREATE TABLE quiz_attempt_answer (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    attempt_id      BIGINT NOT NULL REFERENCES quiz_attempt(id),
    question_id     BIGINT NOT NULL REFERENCES question(id),
    selected_option CHAR(1) NULL CHECK (selected_option IN ('A','B','C','D')),
    is_correct      BIT NULL,
    CONSTRAINT uq_attempt_question UNIQUE (attempt_id, question_id)
);
GO

CREATE TABLE learning_progress (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    student_id          BIGINT NOT NULL REFERENCES users(id),
    class_id            BIGINT NULL REFERENCES class(id),
    lesson_id           BIGINT NULL REFERENCES lesson(id),
    activity_type       NVARCHAR(20) NOT NULL
        CONSTRAINT ck_activity_type CHECK (activity_type IN ('LESSON','QUIZ','FLASHCARD','ASSIGNMENT')),
    completion_status   NVARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED',
    score               DECIMAL(5,2) NULL,
    time_spent_seconds  INT NOT NULL DEFAULT 0,
    attempt_count       INT NOT NULL DEFAULT 0,
    last_active_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

-- =====================================================================
-- 5. AI SUBSYSTEM
-- =====================================================================
CREATE TABLE ai_request (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    requester_id    BIGINT NOT NULL REFERENCES users(id),
    task_type       NVARCHAR(20) NOT NULL
        CONSTRAINT ck_ai_task_type CHECK (task_type IN ('GEN_QUIZ','GEN_FLASHCARD','EXPAND_OUTLINE','SUMMARIZE_VIDEO','GRADE_ESSAY')),
    source_ref_type NVARCHAR(50) NULL,
    source_ref_id   BIGINT NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT ck_ai_request_status CHECK (status IN ('PENDING','SUCCESS','FAILED','TIMEOUT')),
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE ai_response (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    ai_request_id       BIGINT NOT NULL REFERENCES ai_request(id),
    model               NVARCHAR(100) NOT NULL,
    generated_content   NVARCHAR(MAX) NULL CHECK (generated_content IS NULL OR ISJSON(generated_content) = 1),
    token_consumed      INT NOT NULL DEFAULT 0,
    processing_time_ms  INT NULL,
    created_at          DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_ai_response_request UNIQUE (ai_request_id)
);
GO

CREATE TABLE ai_quota (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    month_year  CHAR(7) NOT NULL,                 -- '2026-06'
    quota_limit INT NOT NULL CHECK (quota_limit >= 0),
    used_count  INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
    CONSTRAINT uq_ai_quota_user_month UNIQUE (user_id, month_year),
    CONSTRAINT chk_ai_quota_not_exceeded CHECK (used_count <= quota_limit)
);
GO

CREATE TABLE knowledge_gap_analysis (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    student_id          BIGINT NOT NULL REFERENCES users(id),
    weak_topics         NVARCHAR(MAX) NULL CHECK (weak_topics IS NULL OR ISJSON(weak_topics) = 1),
    roadmap             NVARCHAR(MAX) NULL CHECK (roadmap IS NULL OR ISJSON(roadmap) = 1),
    generated_at        DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    cache_expires_at    DATETIMEOFFSET(3) NOT NULL
);
GO

-- =====================================================================
-- 6. SYSTEM ADMIN
-- =====================================================================
CREATE TABLE system_setting (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    setting_key     NVARCHAR(150) NOT NULL,
    setting_type    NVARCHAR(50) NULL,
    setting_value   NVARCHAR(MAX) NULL,
    display_order   INT NOT NULL DEFAULT 0 CHECK (display_order >= 0),
    description     NVARCHAR(MAX) NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    updated_by      BIGINT NULL REFERENCES users(id),
    updated_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT uq_system_setting_key UNIQUE (setting_key)
);
GO

CREATE TABLE audit_log (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    actor_id        BIGINT NULL REFERENCES users(id),
    action_type     NVARCHAR(100) NOT NULL,
    resource_type   NVARCHAR(100) NOT NULL,
    resource_id     BIGINT NULL,
    metadata        NVARCHAR(MAX) NULL CHECK (metadata IS NULL OR ISJSON(metadata) = 1),
    created_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Immutable theo NFR-S05: tài khoản ứng dụng (app role) chỉ nên có quyền INSERT, SELECT
-- trên bảng này; KHÔNG cấp UPDATE/DELETE (thực hiện qua GRANT/DENY khi cấp quyền user app).

CREATE TABLE notification (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    type        NVARCHAR(50) NOT NULL,
    title       NVARCHAR(255) NOT NULL,
    message     NVARCHAR(MAX) NULL,
    is_read     BIT NOT NULL DEFAULT 0,
    created_at  DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE TABLE background_job_log (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    job_name        NVARCHAR(100) NOT NULL,
    status          NVARCHAR(20) NOT NULL DEFAULT 'RUNNING'
        CONSTRAINT ck_job_status CHECK (status IN ('RUNNING','SUCCESS','FAILED')),
    started_at      DATETIMEOFFSET(3) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    finished_at     DATETIMEOFFSET(3) NULL,
    error_message   NVARCHAR(MAX) NULL
);
GO

-- =====================================================================
-- 7. INDEXES bổ sung
-- =====================================================================
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_course_group_member_user ON course_group_member(user_id);
CREATE INDEX idx_course_group_id ON course(course_group_id);
CREATE INDEX idx_module_course ON module(course_id);
CREATE INDEX idx_lesson_module ON lesson(module_id);
CREATE INDEX idx_lesson_view_lesson ON lesson_view_event(lesson_id);
CREATE INDEX idx_lesson_view_student ON lesson_view_event(student_id);
CREATE INDEX idx_question_module ON question(module_id);
CREATE INDEX idx_quiz_course ON quiz(course_id);
CREATE INDEX idx_quiz_attempt_student ON quiz_attempt(student_id);
CREATE INDEX idx_quiz_attempt_quiz ON quiz_attempt(quiz_id);
CREATE INDEX idx_flashcard_deck_course ON flashcard_deck(course_id);
CREATE INDEX idx_flashcard_deck_id ON flashcard(deck_id);
CREATE INDEX idx_flashcard_review_student ON flashcard_review_log(student_id);
CREATE INDEX idx_class_course ON class(course_id);
CREATE INDEX idx_class_teacher ON class(teacher_id);
CREATE INDEX idx_class_material_class ON class_material(class_id);
CREATE INDEX idx_assignment_class ON assignment(class_id);
CREATE INDEX idx_submission_assignment ON submission(assignment_id);
CREATE INDEX idx_submission_student ON submission(student_id);
CREATE INDEX idx_enrollment_student ON enrollment(student_id);
CREATE INDEX idx_enrollment_class ON enrollment(class_id);
CREATE INDEX idx_enrollment_status ON enrollment(status);
CREATE INDEX idx_payment_user ON payment(user_id);
CREATE INDEX idx_payment_enrollment ON payment(enrollment_id);
CREATE INDEX idx_refund_payment ON refund_request(payment_id);
CREATE INDEX idx_learning_progress_student ON learning_progress(student_id);
CREATE INDEX idx_learning_progress_class ON learning_progress(class_id);
CREATE INDEX idx_ai_request_requester ON ai_request(requester_id);
CREATE INDEX idx_ai_request_task_type ON ai_request(task_type);
CREATE INDEX idx_audit_log_actor ON audit_log(actor_id);
CREATE INDEX idx_audit_log_resource ON audit_log(resource_type, resource_id);
CREATE INDEX idx_notification_user ON notification(user_id, is_read);
CREATE INDEX idx_knowledge_gap_student ON knowledge_gap_analysis(student_id);
GO
-- Không có chỉ mục tương đương GIN cho cột JSON (SQL Server không hỗ trợ).
-- Nếu cần truy vấn nhanh theo 1 path JSON cụ thể (ví dụ ai_response.generated_content
-- -> 'topic'), tạo computed column persisted bằng JSON_VALUE(...) rồi đánh index lên
-- computed column đó. Ví dụ minh hoạ (không bắt buộc, comment lại để không tự ý thêm cột):
-- ALTER TABLE ai_response ADD topic_computed AS JSON_VALUE(generated_content, '$.topic') PERSISTED;
-- CREATE INDEX idx_ai_response_topic ON ai_response(topic_computed);

-- =====================================================================
-- 8. TRIGGERS — Business rule enforcement (set-based, T-SQL)
-- =====================================================================

-- 8.1 Tự động cập nhật updated_at
CREATE TRIGGER trg_users_updated_at ON users
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE u SET updated_at = SYSDATETIMEOFFSET()
    FROM users u INNER JOIN inserted i ON u.id = i.id;
END;
GO

CREATE TRIGGER trg_course_updated_at ON course
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c SET updated_at = SYSDATETIMEOFFSET()
    FROM course c INNER JOIN inserted i ON c.id = i.id;
END;
GO

CREATE TRIGGER trg_lesson_updated_at ON lesson
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE l SET updated_at = SYSDATETIMEOFFSET()
    FROM lesson l INNER JOIN inserted i ON l.id = i.id;
END;
GO

CREATE TRIGGER trg_course_group_updated_at ON course_group
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE g SET updated_at = SYSDATETIMEOFFSET()
    FROM course_group g INNER JOIN inserted i ON g.id = i.id;
END;
GO
-- Ghi chú: 4 trigger trên không gây đệ quy vô hạn vì DB option RECURSIVE_TRIGGERS
-- mặc định OFF (chặn đệ quy trực tiếp khi trigger tự UPDATE lại bảng của chính nó).

-- 8.2 Rubric criteria phải có tổng trọng số = 100% khi assignment đã PUBLISHED
CREATE TRIGGER trg_rubric_weight_check ON assignment_rubric_criterion
AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @bad_assignment BIGINT;

    SELECT TOP 1 @bad_assignment = a.id
    FROM assignment a
    WHERE a.status = 'PUBLISHED'
      AND a.id IN (
          SELECT assignment_id FROM inserted
          UNION
          SELECT assignment_id FROM deleted
      )
      AND (SELECT ISNULL(SUM(weight_percent),0) FROM assignment_rubric_criterion
           WHERE assignment_id = a.id) <> 100;

    IF @bad_assignment IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Tổng trọng số rubric của assignment %d phải = 100%%.', 16, 1, @bad_assignment);
        RETURN;
    END
END;
GO

-- 8.3 Course chỉ publish được khi có >=1 module và mỗi module có >=1 lesson
CREATE TRIGGER trg_course_publishable ON course
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @bad_course BIGINT;

    SELECT TOP 1 @bad_course = i.id
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id
    WHERE i.status = 'PUBLISHED' AND d.status <> 'PUBLISHED'
      AND (
            NOT EXISTS (SELECT 1 FROM module m WHERE m.course_id = i.id)
         OR EXISTS (
                SELECT 1 FROM module m
                WHERE m.course_id = i.id
                  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.module_id = m.id)
            )
      );

    IF @bad_course IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Course %d không thể publish: thiếu module hoặc có module chưa có lesson.', 16, 1, @bad_course);
        RETURN;
    END
END;
GO

-- 8.4 Quiz chỉ publish được khi có >=1 question
CREATE TRIGGER trg_quiz_publishable ON quiz
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @bad_quiz BIGINT;

    SELECT TOP 1 @bad_quiz = i.id
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id
    WHERE i.status = 'PUBLISHED' AND d.status <> 'PUBLISHED'
      AND NOT EXISTS (SELECT 1 FROM quiz_question qq WHERE qq.quiz_id = i.id);

    IF @bad_quiz IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Quiz %d không thể publish: chưa có câu hỏi nào.', 16, 1, @bad_quiz);
        RETURN;
    END
END;
GO

-- =====================================================================
-- 9. VIEWS (báo cáo Analytics)
-- =====================================================================
CREATE VIEW v_content_quality_report AS
SELECT
    l.id AS lesson_id,
    l.title AS lesson_title,
    m.course_id,
    COUNT(DISTINCT lve.student_id) AS view_count,
    AVG(CAST(lve.watch_seconds AS FLOAT)) AS avg_watch_seconds,
    CAST(SUM(CASE WHEN lve.completed = 0 THEN 1 ELSE 0 END) AS DECIMAL(10,4))
        / CASE WHEN COUNT(*) = 0 THEN 1 ELSE COUNT(*) END AS drop_rate
FROM lesson l
JOIN module m ON m.id = l.module_id
LEFT JOIN lesson_view_event lve ON lve.lesson_id = l.id
GROUP BY l.id, l.title, m.course_id;
GO

CREATE VIEW v_class_overview_report AS
SELECT
    c.id AS class_id,
    c.name AS class_name,
    COUNT(DISTINCT e.student_id) AS total_students,
    COUNT(DISTINCT CASE WHEN lp.last_active_at < DATEADD(DAY, -14, SYSDATETIMEOFFSET()) THEN lp.student_id END) AS inactive_students,
    AVG(e.progress_percent) AS avg_progress
FROM class c
LEFT JOIN enrollment e ON e.class_id = c.id AND e.status = 'ACTIVE'
LEFT JOIN learning_progress lp ON lp.class_id = c.id
GROUP BY c.id, c.name;
GO

CREATE VIEW v_revenue_report AS
SELECT
    cg.id AS course_group_id,
    cg.name AS course_group_name,
    DATEFROMPARTS(YEAR(p.paid_at), MONTH(p.paid_at), 1) AS period,
    COUNT(p.id) AS payment_count,
    SUM(p.amount) AS total_revenue
FROM payment p
JOIN enrollment e ON e.id = p.enrollment_id
LEFT JOIN course c ON c.id = e.course_id
LEFT JOIN class cl ON cl.id = e.class_id
LEFT JOIN course cl_course ON cl_course.id = cl.course_id
LEFT JOIN subscription_package sp ON sp.id = e.subscription_package_id
JOIN course_group cg ON cg.id = COALESCE(c.course_group_id, cl_course.course_group_id, sp.course_group_id)
WHERE p.status = 'PAID'
GROUP BY cg.id, cg.name, DATEFROMPARTS(YEAR(p.paid_at), MONTH(p.paid_at), 1);
GO

-- =====================================================================
-- END OF SCHEMA
-- =====================================================================


