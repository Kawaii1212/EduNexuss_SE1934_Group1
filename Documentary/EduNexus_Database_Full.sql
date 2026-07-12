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

   CHANGELOG:
   - [07/2026] ALTER TABLE assignment ADD lesson_id BIGINT NULL REFERENCES lesson(id);
     Đã được tích hợp trực tiếp vào CREATE TABLE assignment bên dưới (không cần chạy
     ALTER riêng khi tạo DB mới từ file này). Mục đích: cho phép 1 bài tập tự luận
     (assignment) liên kết tùy chọn tới đúng 1 lesson cụ thể trong course gốc mà
     class đang dạy (ví dụ: assignment cuối bài của lesson X), thay vì chỉ gắn với
     class chung chung như trước. lesson_id = NULL nếu assignment không gắn với
     lesson cụ thể nào (áp dụng cho cả class). Index bổ sung: idx_assignment_lesson.
   - [07/2026] Bổ sung đầy đủ dữ liệu mẫu (seed data) cho toàn bộ 38 bảng ở cuối
     file, đảm bảo mỗi giá trị trạng thái/loại (status/type) xuất hiện tối thiểu
     6 bản ghi, mỗi module tối thiểu 6 lesson.
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
    lesson_id       BIGINT NULL REFERENCES lesson(id),  -- (Mới 07/2026) Liên kết tùy chọn tới 1 lesson cụ thể trong course gốc của class
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
CREATE INDEX idx_assignment_lesson ON assignment(lesson_id);   -- (Mới 07/2026)
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


-- =====================================================================
-- SEED DATA — EduNexus (sinh tu dong, dam bao moi trang thai/loai >= 6 ban ghi)
-- =====================================================================

-- users: 54 rows
INSERT INTO users (full_name, email, password_hash, role, status, avatar_url, phone, failed_login_count, locked_until, created_by, created_at, updated_at) VALUES
(N'Admin 1', N'admin1@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'ADMIN', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Admin 2', N'admin2@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'ADMIN', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Admin 3', N'admin3@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'ADMIN', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Admin 4', N'admin4@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'ADMIN', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Admin 5', N'admin5@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'ADMIN', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Admin 6 (Locked Test)', N'admin6@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'ADMIN', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'SME Chuyen Gia 1', N'sme1@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'SME', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'SME Chuyen Gia 2', N'sme2@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'SME', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'SME Chuyen Gia 3', N'sme3@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'SME', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'SME Chuyen Gia 4', N'sme4@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'SME', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'SME Chuyen Gia 5 (Locked)', N'sme5@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'SME', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'SME Chuyen Gia 6 (Inactive)', N'sme6@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'SME', 'INACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Course Manager 1', N'cm1@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'COURSE_MANAGER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Course Manager 2', N'cm2@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'COURSE_MANAGER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Course Manager 3', N'cm3@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'COURSE_MANAGER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Course Manager 4', N'cm4@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'COURSE_MANAGER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Course Manager 5 (Locked)', N'cm5@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'COURSE_MANAGER', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Course Manager 6 (Inactive)', N'cm6@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'COURSE_MANAGER', 'INACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Giao Vien 1', N'teacher1@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'TEACHER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Giao Vien 2', N'teacher2@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'TEACHER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Giao Vien 3', N'teacher3@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'TEACHER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Giao Vien 4', N'teacher4@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'TEACHER', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Giao Vien 5 (Locked)', N'teacher5@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'TEACHER', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Giao Vien 6 (Inactive)', N'teacher6@edunexus.vn', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'TEACHER', 'INACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 01', N'student01@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 02', N'student02@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 03', N'student03@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 04', N'student04@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 05', N'student05@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 06', N'student06@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 07', N'student07@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 08', N'student08@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 09', N'student09@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 10', N'student10@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 11', N'student11@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 12', N'student12@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 13', N'student13@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 14', N'student14@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 15', N'student15@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 16', N'student16@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 17', N'student17@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 18', N'student18@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 19', N'student19@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 20', N'student20@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 21', N'student21@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 22', N'student22@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 23', N'student23@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 24', N'student24@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'ACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 25 (Locked)', N'student25@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 26 (Locked)', N'student26@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00');
INSERT INTO users (full_name, email, password_hash, role, status, avatar_url, phone, failed_login_count, locked_until, created_by, created_at, updated_at) VALUES
(N'Hoc Vien 27 (Locked)', N'student27@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'LOCKED', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 28 (Inactive)', N'student28@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'INACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 29 (Inactive)', N'student29@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'INACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(N'Hoc Vien 30 (Inactive)', N'student30@gmail.com', N'$2a$12$SEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEEDHASHSEED', 'STUDENT', 'INACTIVE', NULL, NULL, 0, NULL, NULL, '2026-04-01T08:00:00+07:00', '2026-04-01T08:00:00+07:00');
GO

-- user_oauth_identity: 8 rows
INSERT INTO user_oauth_identity (user_id, provider, provider_user_id, created_at) VALUES
(25, 'GOOGLE', N'google-oauth-uid-0001', '2026-04-07T08:00:00+07:00'),
(26, 'GOOGLE', N'google-oauth-uid-0002', '2026-04-08T08:00:00+07:00'),
(27, 'GOOGLE', N'google-oauth-uid-0003', '2026-04-09T08:00:00+07:00'),
(28, 'GOOGLE', N'google-oauth-uid-0004', '2026-04-10T08:00:00+07:00'),
(7, 'GOOGLE', N'google-oauth-uid-0005', '2026-04-11T08:00:00+07:00'),
(8, 'GOOGLE', N'google-oauth-uid-0006', '2026-04-12T08:00:00+07:00'),
(19, 'GOOGLE', N'google-oauth-uid-0007', '2026-04-13T08:00:00+07:00'),
(1, 'GOOGLE', N'google-oauth-uid-0008', '2026-04-14T08:00:00+07:00');
GO

-- user_session: 12 rows
INSERT INTO user_session (user_id, refresh_token_hash, device_info, issued_at, expires_at, revoked_at) VALUES
(25, N'refresh-hash-0000', N'Chrome on Windows', '2026-04-21T08:00:00+07:00', '2026-05-21T08:00:00+07:00', NULL),
(26, N'refresh-hash-0001', N'Chrome on Windows', '2026-04-22T08:00:00+07:00', '2026-05-22T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(27, N'refresh-hash-0002', N'Chrome on Windows', '2026-04-23T08:00:00+07:00', '2026-05-23T08:00:00+07:00', NULL),
(28, N'refresh-hash-0003', N'Chrome on Windows', '2026-04-24T08:00:00+07:00', '2026-05-24T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(29, N'refresh-hash-0004', N'Chrome on Windows', '2026-04-25T08:00:00+07:00', '2026-05-25T08:00:00+07:00', NULL),
(30, N'refresh-hash-0005', N'Chrome on Windows', '2026-04-26T08:00:00+07:00', '2026-05-26T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(31, N'refresh-hash-0006', N'Chrome on Windows', '2026-04-27T08:00:00+07:00', '2026-05-27T08:00:00+07:00', NULL),
(32, N'refresh-hash-0007', N'Chrome on Windows', '2026-04-28T08:00:00+07:00', '2026-05-28T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(33, N'refresh-hash-0008', N'Chrome on Windows', '2026-04-29T08:00:00+07:00', '2026-05-29T08:00:00+07:00', NULL),
(34, N'refresh-hash-0009', N'Chrome on Windows', '2026-04-30T08:00:00+07:00', '2026-05-30T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(35, N'refresh-hash-0010', N'Chrome on Windows', '2026-05-01T08:00:00+07:00', '2026-05-31T08:00:00+07:00', NULL),
(36, N'refresh-hash-0011', N'Chrome on Windows', '2026-05-02T08:00:00+07:00', '2026-06-01T08:00:00+07:00', '2026-04-30T08:00:00+07:00');
GO

-- login_history: 60 rows
INSERT INTO login_history (user_id, ip_address, user_agent, login_at, status) VALUES
(25, N'118.70.0.0', N'Mozilla/5.0', '2026-03-22T08:00:00+07:00', 'SUCCESS'),
(26, N'118.70.1.3', N'Mozilla/5.0', '2026-03-23T08:00:00+07:00', 'SUCCESS'),
(27, N'118.70.2.6', N'Mozilla/5.0', '2026-03-24T08:00:00+07:00', 'SUCCESS'),
(28, N'118.70.3.9', N'Mozilla/5.0', '2026-03-25T08:00:00+07:00', 'SUCCESS'),
(29, N'118.70.4.12', N'Mozilla/5.0', '2026-03-26T08:00:00+07:00', 'SUCCESS'),
(30, N'118.70.5.15', N'Mozilla/5.0', '2026-03-27T08:00:00+07:00', 'SUCCESS'),
(31, N'118.70.6.18', N'Mozilla/5.0', '2026-03-28T08:00:00+07:00', 'SUCCESS'),
(32, N'118.70.7.21', N'Mozilla/5.0', '2026-03-29T08:00:00+07:00', 'SUCCESS'),
(33, N'118.70.8.24', N'Mozilla/5.0', '2026-03-30T08:00:00+07:00', 'SUCCESS'),
(34, N'118.70.9.27', N'Mozilla/5.0', '2026-03-31T08:00:00+07:00', 'SUCCESS'),
(35, N'118.70.10.30', N'Mozilla/5.0', '2026-04-01T08:00:00+07:00', 'SUCCESS'),
(36, N'118.70.11.33', N'Mozilla/5.0', '2026-04-02T08:00:00+07:00', 'SUCCESS'),
(37, N'118.70.12.36', N'Mozilla/5.0', '2026-04-03T08:00:00+07:00', 'SUCCESS'),
(38, N'118.70.13.39', N'Mozilla/5.0', '2026-04-04T08:00:00+07:00', 'SUCCESS'),
(39, N'118.70.14.42', N'Mozilla/5.0', '2026-04-05T08:00:00+07:00', 'SUCCESS'),
(40, N'118.70.15.45', N'Mozilla/5.0', '2026-04-06T08:00:00+07:00', 'SUCCESS'),
(41, N'118.70.16.48', N'Mozilla/5.0', '2026-04-07T08:00:00+07:00', 'SUCCESS'),
(42, N'118.70.17.51', N'Mozilla/5.0', '2026-04-08T08:00:00+07:00', 'SUCCESS'),
(43, N'118.70.18.54', N'Mozilla/5.0', '2026-04-09T08:00:00+07:00', 'SUCCESS'),
(44, N'118.70.19.57', N'Mozilla/5.0', '2026-04-10T08:00:00+07:00', 'SUCCESS'),
(45, N'118.70.20.60', N'Mozilla/5.0', '2026-04-11T08:00:00+07:00', 'SUCCESS'),
(46, N'118.70.21.63', N'Mozilla/5.0', '2026-04-12T08:00:00+07:00', 'SUCCESS'),
(47, N'118.70.22.66', N'Mozilla/5.0', '2026-04-13T08:00:00+07:00', 'SUCCESS'),
(48, N'118.70.23.69', N'Mozilla/5.0', '2026-04-14T08:00:00+07:00', 'SUCCESS'),
(49, N'118.70.24.72', N'Mozilla/5.0', '2026-04-15T08:00:00+07:00', 'SUCCESS'),
(50, N'118.70.25.75', N'Mozilla/5.0', '2026-04-16T08:00:00+07:00', 'SUCCESS'),
(51, N'118.70.26.78', N'Mozilla/5.0', '2026-04-17T08:00:00+07:00', 'SUCCESS'),
(52, N'118.70.27.81', N'Mozilla/5.0', '2026-04-18T08:00:00+07:00', 'SUCCESS'),
(53, N'118.70.28.84', N'Mozilla/5.0', '2026-04-19T08:00:00+07:00', 'SUCCESS'),
(54, N'118.70.29.87', N'Mozilla/5.0', '2026-04-20T08:00:00+07:00', 'SUCCESS'),
(19, N'118.70.30.90', N'Mozilla/5.0', '2026-04-21T08:00:00+07:00', 'SUCCESS'),
(20, N'118.70.31.93', N'Mozilla/5.0', '2026-04-22T08:00:00+07:00', 'SUCCESS'),
(21, N'118.70.32.96', N'Mozilla/5.0', '2026-04-23T08:00:00+07:00', 'SUCCESS'),
(22, N'118.70.33.99', N'Mozilla/5.0', '2026-04-24T08:00:00+07:00', 'SUCCESS'),
(23, N'118.70.34.102', N'Mozilla/5.0', '2026-04-25T08:00:00+07:00', 'SUCCESS'),
(24, N'118.70.35.105', N'Mozilla/5.0', '2026-04-26T08:00:00+07:00', 'SUCCESS'),
(7, N'118.70.36.108', N'Mozilla/5.0', '2026-04-27T08:00:00+07:00', 'SUCCESS'),
(8, N'118.70.37.111', N'Mozilla/5.0', '2026-04-28T08:00:00+07:00', 'SUCCESS'),
(9, N'118.70.38.114', N'Mozilla/5.0', '2026-04-29T08:00:00+07:00', 'SUCCESS'),
(10, N'118.70.39.117', N'Mozilla/5.0', '2026-04-30T08:00:00+07:00', 'SUCCESS'),
(11, N'118.70.40.120', N'Mozilla/5.0', '2026-05-01T08:00:00+07:00', 'SUCCESS'),
(12, N'118.70.41.123', N'Mozilla/5.0', '2026-05-02T08:00:00+07:00', 'SUCCESS'),
(13, N'118.70.42.126', N'Mozilla/5.0', '2026-05-03T08:00:00+07:00', 'SUCCESS'),
(14, N'118.70.43.129', N'Mozilla/5.0', '2026-05-04T08:00:00+07:00', 'SUCCESS'),
(15, N'118.70.44.132', N'Mozilla/5.0', '2026-05-05T08:00:00+07:00', 'SUCCESS'),
(25, N'118.70.0.0', N'Mozilla/5.0', '2026-04-11T08:00:00+07:00', 'FAILED'),
(26, N'118.70.1.7', N'Mozilla/5.0', '2026-04-12T08:00:00+07:00', 'FAILED'),
(27, N'118.70.2.14', N'Mozilla/5.0', '2026-04-13T08:00:00+07:00', 'FAILED'),
(28, N'118.70.3.21', N'Mozilla/5.0', '2026-04-14T08:00:00+07:00', 'FAILED'),
(29, N'118.70.4.28', N'Mozilla/5.0', '2026-04-15T08:00:00+07:00', 'FAILED');
INSERT INTO login_history (user_id, ip_address, user_agent, login_at, status) VALUES
(30, N'118.70.5.35', N'Mozilla/5.0', '2026-04-16T08:00:00+07:00', 'FAILED'),
(31, N'118.70.6.42', N'Mozilla/5.0', '2026-04-17T08:00:00+07:00', 'FAILED'),
(32, N'118.70.7.49', N'Mozilla/5.0', '2026-04-18T08:00:00+07:00', 'FAILED'),
(33, N'118.70.8.56', N'Mozilla/5.0', '2026-04-19T08:00:00+07:00', 'FAILED'),
(34, N'118.70.9.63', N'Mozilla/5.0', '2026-04-20T08:00:00+07:00', 'FAILED'),
(35, N'118.70.10.70', N'Mozilla/5.0', '2026-04-21T08:00:00+07:00', 'FAILED'),
(36, N'118.70.11.77', N'Mozilla/5.0', '2026-04-22T08:00:00+07:00', 'FAILED'),
(37, N'118.70.12.84', N'Mozilla/5.0', '2026-04-23T08:00:00+07:00', 'FAILED'),
(38, N'118.70.13.91', N'Mozilla/5.0', '2026-04-24T08:00:00+07:00', 'FAILED'),
(39, N'118.70.14.98', N'Mozilla/5.0', '2026-04-25T08:00:00+07:00', 'FAILED');
GO

-- course_group: 12 rows
INSERT INTO course_group (name, description, status, created_by, created_at, updated_at) VALUES
(N'Lap Trinh Web', N'Nhom khoa hoc chuyen de: Lap Trinh Web', 'ACTIVE', 1, '2026-03-02T08:00:00+07:00', '2026-03-02T08:00:00+07:00'),
(N'Khoa Hoc Du Lieu', N'Nhom khoa hoc chuyen de: Khoa Hoc Du Lieu', 'ACTIVE', 2, '2026-03-03T08:00:00+07:00', '2026-03-03T08:00:00+07:00'),
(N'Ngoai Ngu Giao Tiep', N'Nhom khoa hoc chuyen de: Ngoai Ngu Giao Tiep', 'ACTIVE', 3, '2026-03-04T08:00:00+07:00', '2026-03-04T08:00:00+07:00'),
(N'Marketing So', N'Nhom khoa hoc chuyen de: Marketing So', 'ACTIVE', 4, '2026-03-05T08:00:00+07:00', '2026-03-05T08:00:00+07:00'),
(N'Thiet Ke Do Hoa', N'Nhom khoa hoc chuyen de: Thiet Ke Do Hoa', 'ACTIVE', 5, '2026-03-06T08:00:00+07:00', '2026-03-06T08:00:00+07:00'),
(N'Ky Nang Mem', N'Nhom khoa hoc chuyen de: Ky Nang Mem', 'ACTIVE', 6, '2026-03-07T08:00:00+07:00', '2026-03-07T08:00:00+07:00'),
(N'Toan Cao Cap', N'Nhom khoa hoc chuyen de: Toan Cao Cap', 'ARCHIVED', 1, '2026-03-08T08:00:00+07:00', '2026-03-08T08:00:00+07:00'),
(N'Tai Chinh Ca Nhan', N'Nhom khoa hoc chuyen de: Tai Chinh Ca Nhan', 'ARCHIVED', 2, '2026-03-09T08:00:00+07:00', '2026-03-09T08:00:00+07:00'),
(N'Nhiep Anh Co Ban', N'Nhom khoa hoc chuyen de: Nhiep Anh Co Ban', 'ARCHIVED', 3, '2026-03-10T08:00:00+07:00', '2026-03-10T08:00:00+07:00'),
(N'Am Nhac & Nhac Cu', N'Nhom khoa hoc chuyen de: Am Nhac & Nhac Cu', 'ARCHIVED', 4, '2026-03-11T08:00:00+07:00', '2026-03-11T08:00:00+07:00'),
(N'Quan Tri Kinh Doanh', N'Nhom khoa hoc chuyen de: Quan Tri Kinh Doanh', 'ARCHIVED', 5, '2026-03-12T08:00:00+07:00', '2026-03-12T08:00:00+07:00'),
(N'An Toan Thong Tin', N'Nhom khoa hoc chuyen de: An Toan Thong Tin', 'ARCHIVED', 6, '2026-03-13T08:00:00+07:00', '2026-03-13T08:00:00+07:00');
GO

-- course_group_member: 24 rows
INSERT INTO course_group_member (course_group_id, user_id, role_in_group, assigned_by, assigned_at) VALUES
(1, 13, 'COURSE_MANAGER', 1, '2026-03-07T08:00:00+07:00'),
(2, 14, 'COURSE_MANAGER', 2, '2026-03-08T08:00:00+07:00'),
(3, 15, 'COURSE_MANAGER', 3, '2026-03-09T08:00:00+07:00'),
(4, 16, 'COURSE_MANAGER', 4, '2026-03-10T08:00:00+07:00'),
(5, 17, 'COURSE_MANAGER', 5, '2026-03-11T08:00:00+07:00'),
(6, 18, 'COURSE_MANAGER', 6, '2026-03-12T08:00:00+07:00'),
(7, 13, 'COURSE_MANAGER', 1, '2026-03-13T08:00:00+07:00'),
(8, 14, 'COURSE_MANAGER', 2, '2026-03-14T08:00:00+07:00'),
(9, 15, 'COURSE_MANAGER', 3, '2026-03-15T08:00:00+07:00'),
(10, 16, 'COURSE_MANAGER', 4, '2026-03-16T08:00:00+07:00'),
(11, 17, 'COURSE_MANAGER', 5, '2026-03-17T08:00:00+07:00'),
(12, 18, 'COURSE_MANAGER', 6, '2026-03-18T08:00:00+07:00'),
(1, 7, 'SME', 1, '2026-03-07T08:00:00+07:00'),
(2, 8, 'SME', 2, '2026-03-08T08:00:00+07:00'),
(3, 9, 'SME', 3, '2026-03-09T08:00:00+07:00'),
(4, 10, 'SME', 4, '2026-03-10T08:00:00+07:00'),
(5, 11, 'SME', 5, '2026-03-11T08:00:00+07:00'),
(6, 12, 'SME', 6, '2026-03-12T08:00:00+07:00'),
(7, 7, 'SME', 1, '2026-03-13T08:00:00+07:00'),
(8, 8, 'SME', 2, '2026-03-14T08:00:00+07:00'),
(9, 9, 'SME', 3, '2026-03-15T08:00:00+07:00'),
(10, 10, 'SME', 4, '2026-03-16T08:00:00+07:00'),
(11, 11, 'SME', 5, '2026-03-17T08:00:00+07:00'),
(12, 12, 'SME', 6, '2026-03-18T08:00:00+07:00');
GO

-- course: 24 rows
INSERT INTO course (course_group_id, title, description, price, status, version, created_by, created_at, updated_at, deleted_at) VALUES
(1, N'Nhap Mon HTML/CSS', N'Mo ta chi tiet cho khoa hoc: Nhap Mon HTML/CSS', 0, 'DRAFT', 1, 7, '2026-03-12T08:00:00+07:00', '2026-03-22T08:00:00+07:00', NULL),
(2, N'JavaScript Co Ban', N'Mo ta chi tiet cho khoa hoc: JavaScript Co Ban', 160000, 'DRAFT', 1, 8, '2026-03-13T08:00:00+07:00', '2026-03-23T08:00:00+07:00', NULL),
(3, N'ReactJS Tu Dau', N'Mo ta chi tiet cho khoa hoc: ReactJS Tu Dau', 170000, 'DRAFT', 1, 9, '2026-03-14T08:00:00+07:00', '2026-03-24T08:00:00+07:00', NULL),
(4, N'Python Cho Nguoi Moi', N'Mo ta chi tiet cho khoa hoc: Python Cho Nguoi Moi', 180000, 'DRAFT', 1, 10, '2026-03-15T08:00:00+07:00', '2026-03-25T08:00:00+07:00', NULL),
(5, N'Phan Tich Du Lieu Voi Pandas', N'Mo ta chi tiet cho khoa hoc: Phan Tich Du Lieu Voi Pandas', 190000, 'DRAFT', 1, 11, '2026-03-16T08:00:00+07:00', '2026-03-26T08:00:00+07:00', NULL),
(6, N'Machine Learning Nhap Mon', N'Mo ta chi tiet cho khoa hoc: Machine Learning Nhap Mon', 0, 'DRAFT', 1, 12, '2026-03-17T08:00:00+07:00', '2026-03-27T08:00:00+07:00', NULL),
(7, N'Tieng Anh Giao Tiep A1', N'Mo ta chi tiet cho khoa hoc: Tieng Anh Giao Tiep A1', 210000, 'PENDING_REVIEW', 1, 7, '2026-03-18T08:00:00+07:00', '2026-03-28T08:00:00+07:00', NULL),
(8, N'Tieng Anh Giao Tiep A2', N'Mo ta chi tiet cho khoa hoc: Tieng Anh Giao Tiep A2', 220000, 'PENDING_REVIEW', 1, 8, '2026-03-19T08:00:00+07:00', '2026-03-29T08:00:00+07:00', NULL),
(9, N'Luyen Thi IELTS 6.5', N'Mo ta chi tiet cho khoa hoc: Luyen Thi IELTS 6.5', 230000, 'PENDING_REVIEW', 1, 9, '2026-03-20T08:00:00+07:00', '2026-03-30T08:00:00+07:00', NULL),
(10, N'Facebook Ads Tu Xa La Den Chuyen Nghiep', N'Mo ta chi tiet cho khoa hoc: Facebook Ads Tu Xa La Den Chuyen Nghiep', 240000, 'PENDING_REVIEW', 1, 10, '2026-03-21T08:00:00+07:00', '2026-03-31T08:00:00+07:00', NULL),
(11, N'SEO Website Can Ban', N'Mo ta chi tiet cho khoa hoc: SEO Website Can Ban', 0, 'PENDING_REVIEW', 1, 11, '2026-03-22T08:00:00+07:00', '2026-04-01T08:00:00+07:00', NULL),
(12, N'Content Marketing', N'Mo ta chi tiet cho khoa hoc: Content Marketing', 260000, 'PENDING_REVIEW', 1, 12, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00', NULL),
(1, N'Photoshop Can Ban', N'Mo ta chi tiet cho khoa hoc: Photoshop Can Ban', 270000, 'PUBLISHED', 1, 7, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00', NULL),
(2, N'Illustrator Nang Cao', N'Mo ta chi tiet cho khoa hoc: Illustrator Nang Cao', 280000, 'PUBLISHED', 1, 8, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00', NULL),
(3, N'Figma UI/UX', N'Mo ta chi tiet cho khoa hoc: Figma UI/UX', 290000, 'PUBLISHED', 1, 9, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00', NULL),
(4, N'Ky Nang Thuyet Trinh', N'Mo ta chi tiet cho khoa hoc: Ky Nang Thuyet Trinh', 0, 'PUBLISHED', 1, 10, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00', NULL),
(5, N'Quan Ly Thoi Gian', N'Mo ta chi tiet cho khoa hoc: Quan Ly Thoi Gian', 310000, 'PUBLISHED', 1, 11, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00', NULL),
(6, N'Tu Duy Phan Bien', N'Mo ta chi tiet cho khoa hoc: Tu Duy Phan Bien', 320000, 'PUBLISHED', 1, 12, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00', NULL),
(7, N'Giai Tich 1', N'Mo ta chi tiet cho khoa hoc: Giai Tich 1', 330000, 'ARCHIVED', 1, 7, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00', NULL),
(8, N'Dai So Tuyen Tinh', N'Mo ta chi tiet cho khoa hoc: Dai So Tuyen Tinh', 340000, 'ARCHIVED', 1, 8, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00', NULL),
(9, N'Xac Suat Thong Ke', N'Mo ta chi tiet cho khoa hoc: Xac Suat Thong Ke', 0, 'ARCHIVED', 1, 9, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00', NULL),
(10, N'Dau Tu Chung Khoan Co Ban', N'Mo ta chi tiet cho khoa hoc: Dau Tu Chung Khoan Co Ban', 360000, 'ARCHIVED', 1, 10, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00', NULL),
(11, N'Quan Ly Tai Chinh Ca Nhan', N'Mo ta chi tiet cho khoa hoc: Quan Ly Tai Chinh Ca Nhan', 370000, 'ARCHIVED', 1, 11, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00', NULL),
(12, N'Bao Mat Ung Dung Web', N'Mo ta chi tiet cho khoa hoc: Bao Mat Ung Dung Web', 380000, 'ARCHIVED', 1, 12, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00', NULL);
GO

-- course_content_version: 12 rows
INSERT INTO course_content_version (course_id, version_no, snapshot_json, changed_by, change_note, created_at) VALUES
(13, 1, N'{"note":"snapshot khoi tao", "version":1}', 7, N'Xuat ban phien ban dau tien', '2026-03-27T08:00:00+07:00'),
(14, 1, N'{"note":"snapshot khoi tao", "version":1}', 8, N'Xuat ban phien ban dau tien', '2026-03-28T08:00:00+07:00'),
(15, 1, N'{"note":"snapshot khoi tao", "version":1}', 9, N'Xuat ban phien ban dau tien', '2026-03-29T08:00:00+07:00'),
(16, 1, N'{"note":"snapshot khoi tao", "version":1}', 10, N'Xuat ban phien ban dau tien', '2026-03-30T08:00:00+07:00'),
(17, 1, N'{"note":"snapshot khoi tao", "version":1}', 11, N'Xuat ban phien ban dau tien', '2026-03-31T08:00:00+07:00'),
(18, 1, N'{"note":"snapshot khoi tao", "version":1}', 12, N'Xuat ban phien ban dau tien', '2026-04-01T08:00:00+07:00'),
(19, 1, N'{"note":"snapshot khoi tao", "version":1}', 7, N'Xuat ban phien ban dau tien', '2026-04-02T08:00:00+07:00'),
(20, 1, N'{"note":"snapshot khoi tao", "version":1}', 8, N'Xuat ban phien ban dau tien', '2026-04-03T08:00:00+07:00'),
(21, 1, N'{"note":"snapshot khoi tao", "version":1}', 9, N'Xuat ban phien ban dau tien', '2026-04-04T08:00:00+07:00'),
(22, 1, N'{"note":"snapshot khoi tao", "version":1}', 10, N'Xuat ban phien ban dau tien', '2026-04-05T08:00:00+07:00'),
(23, 1, N'{"note":"snapshot khoi tao", "version":1}', 11, N'Xuat ban phien ban dau tien', '2026-04-06T08:00:00+07:00'),
(24, 1, N'{"note":"snapshot khoi tao", "version":1}', 12, N'Xuat ban phien ban dau tien', '2026-04-07T08:00:00+07:00');
GO

-- module: 48 rows
INSERT INTO module (course_id, title, description, order_no, created_at) VALUES
(1, N'Module 1: Nhap Mon - Nhap Mon HTML/CSS', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-18T08:00:00+07:00'),
(1, N'Module 2: Nang Cao - Nhap Mon HTML/CSS', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-18T08:00:00+07:00'),
(2, N'Module 1: Nhap Mon - JavaScript Co Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-19T08:00:00+07:00'),
(2, N'Module 2: Nang Cao - JavaScript Co Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-19T08:00:00+07:00'),
(3, N'Module 1: Nhap Mon - ReactJS Tu Dau', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-20T08:00:00+07:00'),
(3, N'Module 2: Nang Cao - ReactJS Tu Dau', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-20T08:00:00+07:00'),
(4, N'Module 1: Nhap Mon - Python Cho Nguoi Moi', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-21T08:00:00+07:00'),
(4, N'Module 2: Nang Cao - Python Cho Nguoi Moi', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-21T08:00:00+07:00'),
(5, N'Module 1: Nhap Mon - Phan Tich Du Lieu Voi Pandas', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-22T08:00:00+07:00'),
(5, N'Module 2: Nang Cao - Phan Tich Du Lieu Voi Pandas', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-22T08:00:00+07:00'),
(6, N'Module 1: Nhap Mon - Machine Learning Nhap Mon', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-23T08:00:00+07:00'),
(6, N'Module 2: Nang Cao - Machine Learning Nhap Mon', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-23T08:00:00+07:00'),
(7, N'Module 1: Nhap Mon - Tieng Anh Giao Tiep A1', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-24T08:00:00+07:00'),
(7, N'Module 2: Nang Cao - Tieng Anh Giao Tiep A1', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-24T08:00:00+07:00'),
(8, N'Module 1: Nhap Mon - Tieng Anh Giao Tiep A2', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-25T08:00:00+07:00'),
(8, N'Module 2: Nang Cao - Tieng Anh Giao Tiep A2', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-25T08:00:00+07:00'),
(9, N'Module 1: Nhap Mon - Luyen Thi IELTS 6.5', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-26T08:00:00+07:00'),
(9, N'Module 2: Nang Cao - Luyen Thi IELTS 6.5', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-26T08:00:00+07:00'),
(10, N'Module 1: Nhap Mon - Facebook Ads Tu Xa La Den Chuyen Nghiep', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-27T08:00:00+07:00'),
(10, N'Module 2: Nang Cao - Facebook Ads Tu Xa La Den Chuyen Nghiep', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-27T08:00:00+07:00'),
(11, N'Module 1: Nhap Mon - SEO Website Can Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-28T08:00:00+07:00'),
(11, N'Module 2: Nang Cao - SEO Website Can Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-28T08:00:00+07:00'),
(12, N'Module 1: Nhap Mon - Content Marketing', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-29T08:00:00+07:00'),
(12, N'Module 2: Nang Cao - Content Marketing', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-29T08:00:00+07:00'),
(13, N'Module 1: Nhap Mon - Photoshop Can Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-30T08:00:00+07:00'),
(13, N'Module 2: Nang Cao - Photoshop Can Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-30T08:00:00+07:00'),
(14, N'Module 1: Nhap Mon - Illustrator Nang Cao', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-03-31T08:00:00+07:00'),
(14, N'Module 2: Nang Cao - Illustrator Nang Cao', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-03-31T08:00:00+07:00'),
(15, N'Module 1: Nhap Mon - Figma UI/UX', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-01T08:00:00+07:00'),
(15, N'Module 2: Nang Cao - Figma UI/UX', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-01T08:00:00+07:00'),
(16, N'Module 1: Nhap Mon - Ky Nang Thuyet Trinh', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-02T08:00:00+07:00'),
(16, N'Module 2: Nang Cao - Ky Nang Thuyet Trinh', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-02T08:00:00+07:00'),
(17, N'Module 1: Nhap Mon - Quan Ly Thoi Gian', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-03T08:00:00+07:00'),
(17, N'Module 2: Nang Cao - Quan Ly Thoi Gian', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-03T08:00:00+07:00'),
(18, N'Module 1: Nhap Mon - Tu Duy Phan Bien', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-04T08:00:00+07:00'),
(18, N'Module 2: Nang Cao - Tu Duy Phan Bien', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-04T08:00:00+07:00'),
(19, N'Module 1: Nhap Mon - Giai Tich 1', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-05T08:00:00+07:00'),
(19, N'Module 2: Nang Cao - Giai Tich 1', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-05T08:00:00+07:00'),
(20, N'Module 1: Nhap Mon - Dai So Tuyen Tinh', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-06T08:00:00+07:00'),
(20, N'Module 2: Nang Cao - Dai So Tuyen Tinh', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-06T08:00:00+07:00'),
(21, N'Module 1: Nhap Mon - Xac Suat Thong Ke', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-07T08:00:00+07:00'),
(21, N'Module 2: Nang Cao - Xac Suat Thong Ke', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-07T08:00:00+07:00'),
(22, N'Module 1: Nhap Mon - Dau Tu Chung Khoan Co Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-08T08:00:00+07:00'),
(22, N'Module 2: Nang Cao - Dau Tu Chung Khoan Co Ban', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-08T08:00:00+07:00'),
(23, N'Module 1: Nhap Mon - Quan Ly Tai Chinh Ca Nhan', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-09T08:00:00+07:00'),
(23, N'Module 2: Nang Cao - Quan Ly Tai Chinh Ca Nhan', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-09T08:00:00+07:00'),
(24, N'Module 1: Nhap Mon - Bao Mat Ung Dung Web', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 1, '2026-04-10T08:00:00+07:00'),
(24, N'Module 2: Nang Cao - Bao Mat Ung Dung Web', N'Noi dung module bao gom ly thuyet, video va bai tap thuc hanh.', 2, '2026-04-10T08:00:00+07:00');
GO

-- lesson: 288 rows
INSERT INTO lesson (module_id, title, video_url, summary, content, status, order_no, created_by, created_at, updated_at) VALUES
(1, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0001', N'Tom tat AI: bai hoc so 1 cua module 1.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 1. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 1. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 1. ', 'DRAFT', 1, 8, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(1, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0002', N'Tom tat AI: bai hoc so 2 cua module 1.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 1. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 1. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 1. ', 'PUBLISHED', 2, 8, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(1, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 1.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 1. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 1. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 1. ', 'PUBLISHED', 3, 8, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(1, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0004', N'Tom tat AI: bai hoc so 4 cua module 1.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 1. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 1. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 1. ', 'PUBLISHED', 4, 8, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(1, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0005', N'Tom tat AI: bai hoc so 5 cua module 1.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 1. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 1. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 1. ', 'PUBLISHED', 5, 8, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(1, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 1.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 1. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 1. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 1. ', 'PUBLISHED', 6, 8, '2026-03-23T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(2, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0007', N'Tom tat AI: bai hoc so 1 cua module 2.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 2. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 2. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 2. ', 'DRAFT', 1, 9, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(2, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0008', N'Tom tat AI: bai hoc so 2 cua module 2.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 2. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 2. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 2. ', 'PUBLISHED', 2, 9, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(2, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 2.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 2. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 2. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 2. ', 'PUBLISHED', 3, 9, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(2, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0010', N'Tom tat AI: bai hoc so 4 cua module 2.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 2. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 2. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 2. ', 'PUBLISHED', 4, 9, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(2, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0011', N'Tom tat AI: bai hoc so 5 cua module 2.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 2. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 2. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 2. ', 'PUBLISHED', 5, 9, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(2, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 2.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 2. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 2. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 2. ', 'PUBLISHED', 6, 9, '2026-03-24T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(3, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0013', N'Tom tat AI: bai hoc so 1 cua module 3.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 3. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 3. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 3. ', 'DRAFT', 1, 10, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(3, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0014', N'Tom tat AI: bai hoc so 2 cua module 3.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 3. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 3. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 3. ', 'PUBLISHED', 2, 10, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(3, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 3.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 3. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 3. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 3. ', 'PUBLISHED', 3, 10, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(3, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0016', N'Tom tat AI: bai hoc so 4 cua module 3.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 3. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 3. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 3. ', 'PUBLISHED', 4, 10, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(3, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0017', N'Tom tat AI: bai hoc so 5 cua module 3.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 3. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 3. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 3. ', 'PUBLISHED', 5, 10, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(3, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 3.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 3. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 3. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 3. ', 'PUBLISHED', 6, 10, '2026-03-25T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(4, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0019', N'Tom tat AI: bai hoc so 1 cua module 4.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 4. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 4. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 4. ', 'DRAFT', 1, 11, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(4, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0020', N'Tom tat AI: bai hoc so 2 cua module 4.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 4. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 4. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 4. ', 'PUBLISHED', 2, 11, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(4, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 4.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 4. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 4. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 4. ', 'PUBLISHED', 3, 11, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(4, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0022', N'Tom tat AI: bai hoc so 4 cua module 4.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 4. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 4. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 4. ', 'PUBLISHED', 4, 11, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(4, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0023', N'Tom tat AI: bai hoc so 5 cua module 4.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 4. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 4. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 4. ', 'PUBLISHED', 5, 11, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(4, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 4.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 4. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 4. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 4. ', 'PUBLISHED', 6, 11, '2026-03-26T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(5, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0025', N'Tom tat AI: bai hoc so 1 cua module 5.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 5. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 5. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 5. ', 'DRAFT', 1, 12, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(5, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0026', N'Tom tat AI: bai hoc so 2 cua module 5.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 5. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 5. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 5. ', 'PUBLISHED', 2, 12, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(5, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 5.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 5. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 5. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 5. ', 'PUBLISHED', 3, 12, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(5, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0028', N'Tom tat AI: bai hoc so 4 cua module 5.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 5. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 5. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 5. ', 'PUBLISHED', 4, 12, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(5, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0029', N'Tom tat AI: bai hoc so 5 cua module 5.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 5. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 5. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 5. ', 'PUBLISHED', 5, 12, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(5, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 5.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 5. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 5. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 5. ', 'PUBLISHED', 6, 12, '2026-03-27T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(6, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0031', N'Tom tat AI: bai hoc so 1 cua module 6.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 6. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 6. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 6. ', 'DRAFT', 1, 7, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(6, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0032', N'Tom tat AI: bai hoc so 2 cua module 6.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 6. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 6. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 6. ', 'PUBLISHED', 2, 7, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(6, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 6.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 6. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 6. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 6. ', 'PUBLISHED', 3, 7, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(6, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0034', N'Tom tat AI: bai hoc so 4 cua module 6.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 6. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 6. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 6. ', 'PUBLISHED', 4, 7, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(6, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0035', N'Tom tat AI: bai hoc so 5 cua module 6.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 6. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 6. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 6. ', 'PUBLISHED', 5, 7, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(6, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 6.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 6. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 6. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 6. ', 'PUBLISHED', 6, 7, '2026-03-28T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(7, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0037', N'Tom tat AI: bai hoc so 1 cua module 7.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 7. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 7. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 7. ', 'DRAFT', 1, 8, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(7, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0038', N'Tom tat AI: bai hoc so 2 cua module 7.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 7. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 7. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 7. ', 'PUBLISHED', 2, 8, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(7, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 7.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 7. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 7. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 7. ', 'PUBLISHED', 3, 8, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(7, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0040', N'Tom tat AI: bai hoc so 4 cua module 7.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 7. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 7. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 7. ', 'PUBLISHED', 4, 8, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(7, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0041', N'Tom tat AI: bai hoc so 5 cua module 7.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 7. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 7. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 7. ', 'PUBLISHED', 5, 8, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(7, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 7.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 7. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 7. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 7. ', 'PUBLISHED', 6, 8, '2026-03-29T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(8, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0043', N'Tom tat AI: bai hoc so 1 cua module 8.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 8. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 8. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 8. ', 'DRAFT', 1, 9, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(8, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0044', N'Tom tat AI: bai hoc so 2 cua module 8.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 8. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 8. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 8. ', 'PUBLISHED', 2, 9, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(8, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 8.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 8. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 8. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 8. ', 'PUBLISHED', 3, 9, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(8, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0046', N'Tom tat AI: bai hoc so 4 cua module 8.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 8. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 8. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 8. ', 'PUBLISHED', 4, 9, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(8, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0047', N'Tom tat AI: bai hoc so 5 cua module 8.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 8. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 8. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 8. ', 'PUBLISHED', 5, 9, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(8, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 8.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 8. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 8. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 8. ', 'PUBLISHED', 6, 9, '2026-03-30T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(9, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0049', N'Tom tat AI: bai hoc so 1 cua module 9.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 9. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 9. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 9. ', 'DRAFT', 1, 10, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(9, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0050', N'Tom tat AI: bai hoc so 2 cua module 9.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 9. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 9. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 9. ', 'PUBLISHED', 2, 10, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00');
INSERT INTO lesson (module_id, title, video_url, summary, content, status, order_no, created_by, created_at, updated_at) VALUES
(9, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 9.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 9. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 9. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 9. ', 'PUBLISHED', 3, 10, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(9, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0052', N'Tom tat AI: bai hoc so 4 cua module 9.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 9. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 9. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 9. ', 'PUBLISHED', 4, 10, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(9, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0053', N'Tom tat AI: bai hoc so 5 cua module 9.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 9. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 9. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 9. ', 'PUBLISHED', 5, 10, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(9, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 9.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 9. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 9. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 9. ', 'PUBLISHED', 6, 10, '2026-03-31T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(10, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0055', N'Tom tat AI: bai hoc so 1 cua module 10.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 10. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 10. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 10. ', 'DRAFT', 1, 11, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(10, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0056', N'Tom tat AI: bai hoc so 2 cua module 10.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 10. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 10. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 10. ', 'PUBLISHED', 2, 11, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(10, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 10.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 10. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 10. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 10. ', 'PUBLISHED', 3, 11, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(10, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0058', N'Tom tat AI: bai hoc so 4 cua module 10.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 10. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 10. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 10. ', 'PUBLISHED', 4, 11, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(10, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0059', N'Tom tat AI: bai hoc so 5 cua module 10.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 10. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 10. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 10. ', 'PUBLISHED', 5, 11, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(10, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 10.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 10. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 10. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 10. ', 'PUBLISHED', 6, 11, '2026-04-01T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(11, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0061', N'Tom tat AI: bai hoc so 1 cua module 11.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 11. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 11. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 11. ', 'DRAFT', 1, 12, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(11, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0062', N'Tom tat AI: bai hoc so 2 cua module 11.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 11. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 11. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 11. ', 'PUBLISHED', 2, 12, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(11, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 11.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 11. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 11. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 11. ', 'PUBLISHED', 3, 12, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(11, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0064', N'Tom tat AI: bai hoc so 4 cua module 11.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 11. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 11. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 11. ', 'PUBLISHED', 4, 12, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(11, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0065', N'Tom tat AI: bai hoc so 5 cua module 11.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 11. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 11. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 11. ', 'PUBLISHED', 5, 12, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(11, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 11.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 11. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 11. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 11. ', 'PUBLISHED', 6, 12, '2026-04-02T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(12, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0067', N'Tom tat AI: bai hoc so 1 cua module 12.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 12. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 12. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 12. ', 'DRAFT', 1, 7, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(12, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0068', N'Tom tat AI: bai hoc so 2 cua module 12.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 12. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 12. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 12. ', 'PUBLISHED', 2, 7, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(12, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 12.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 12. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 12. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 12. ', 'PUBLISHED', 3, 7, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(12, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0070', N'Tom tat AI: bai hoc so 4 cua module 12.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 12. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 12. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 12. ', 'PUBLISHED', 4, 7, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(12, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0071', N'Tom tat AI: bai hoc so 5 cua module 12.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 12. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 12. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 12. ', 'PUBLISHED', 5, 7, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(12, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 12.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 12. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 12. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 12. ', 'PUBLISHED', 6, 7, '2026-04-03T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(13, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0073', N'Tom tat AI: bai hoc so 1 cua module 13.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 13. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 13. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 13. ', 'DRAFT', 1, 8, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(13, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0074', N'Tom tat AI: bai hoc so 2 cua module 13.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 13. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 13. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 13. ', 'PUBLISHED', 2, 8, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(13, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 13.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 13. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 13. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 13. ', 'PUBLISHED', 3, 8, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(13, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0076', N'Tom tat AI: bai hoc so 4 cua module 13.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 13. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 13. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 13. ', 'PUBLISHED', 4, 8, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(13, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0077', N'Tom tat AI: bai hoc so 5 cua module 13.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 13. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 13. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 13. ', 'PUBLISHED', 5, 8, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(13, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 13.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 13. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 13. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 13. ', 'PUBLISHED', 6, 8, '2026-04-04T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(14, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0079', N'Tom tat AI: bai hoc so 1 cua module 14.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 14. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 14. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 14. ', 'DRAFT', 1, 9, '2026-04-05T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(14, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0080', N'Tom tat AI: bai hoc so 2 cua module 14.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 14. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 14. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 14. ', 'PUBLISHED', 2, 9, '2026-04-05T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(14, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 14.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 14. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 14. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 14. ', 'PUBLISHED', 3, 9, '2026-04-05T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(14, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0082', N'Tom tat AI: bai hoc so 4 cua module 14.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 14. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 14. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 14. ', 'PUBLISHED', 4, 9, '2026-04-05T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(14, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0083', N'Tom tat AI: bai hoc so 5 cua module 14.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 14. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 14. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 14. ', 'PUBLISHED', 5, 9, '2026-04-05T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(14, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 14.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 14. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 14. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 14. ', 'PUBLISHED', 6, 9, '2026-04-05T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(15, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0085', N'Tom tat AI: bai hoc so 1 cua module 15.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 15. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 15. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 15. ', 'DRAFT', 1, 10, '2026-04-06T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(15, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0086', N'Tom tat AI: bai hoc so 2 cua module 15.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 15. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 15. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 15. ', 'PUBLISHED', 2, 10, '2026-04-06T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(15, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 15.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 15. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 15. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 15. ', 'PUBLISHED', 3, 10, '2026-04-06T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(15, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0088', N'Tom tat AI: bai hoc so 4 cua module 15.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 15. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 15. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 15. ', 'PUBLISHED', 4, 10, '2026-04-06T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(15, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0089', N'Tom tat AI: bai hoc so 5 cua module 15.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 15. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 15. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 15. ', 'PUBLISHED', 5, 10, '2026-04-06T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(15, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 15.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 15. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 15. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 15. ', 'PUBLISHED', 6, 10, '2026-04-06T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(16, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0091', N'Tom tat AI: bai hoc so 1 cua module 16.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 16. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 16. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 16. ', 'DRAFT', 1, 11, '2026-04-07T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(16, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0092', N'Tom tat AI: bai hoc so 2 cua module 16.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 16. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 16. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 16. ', 'PUBLISHED', 2, 11, '2026-04-07T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(16, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 16.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 16. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 16. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 16. ', 'PUBLISHED', 3, 11, '2026-04-07T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(16, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0094', N'Tom tat AI: bai hoc so 4 cua module 16.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 16. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 16. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 16. ', 'PUBLISHED', 4, 11, '2026-04-07T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(16, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0095', N'Tom tat AI: bai hoc so 5 cua module 16.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 16. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 16. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 16. ', 'PUBLISHED', 5, 11, '2026-04-07T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(16, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 16.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 16. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 16. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 16. ', 'PUBLISHED', 6, 11, '2026-04-07T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(17, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0097', N'Tom tat AI: bai hoc so 1 cua module 17.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 17. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 17. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 17. ', 'DRAFT', 1, 12, '2026-04-08T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(17, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0098', N'Tom tat AI: bai hoc so 2 cua module 17.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 17. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 17. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 17. ', 'PUBLISHED', 2, 12, '2026-04-08T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(17, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 17.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 17. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 17. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 17. ', 'PUBLISHED', 3, 12, '2026-04-08T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(17, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0100', N'Tom tat AI: bai hoc so 4 cua module 17.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 17. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 17. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 17. ', 'PUBLISHED', 4, 12, '2026-04-08T08:00:00+07:00', '2026-04-18T08:00:00+07:00');
INSERT INTO lesson (module_id, title, video_url, summary, content, status, order_no, created_by, created_at, updated_at) VALUES
(17, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0101', N'Tom tat AI: bai hoc so 5 cua module 17.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 17. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 17. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 17. ', 'PUBLISHED', 5, 12, '2026-04-08T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(17, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 17.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 17. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 17. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 17. ', 'PUBLISHED', 6, 12, '2026-04-08T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(18, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0103', N'Tom tat AI: bai hoc so 1 cua module 18.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 18. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 18. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 18. ', 'DRAFT', 1, 7, '2026-04-09T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(18, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0104', N'Tom tat AI: bai hoc so 2 cua module 18.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 18. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 18. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 18. ', 'PUBLISHED', 2, 7, '2026-04-09T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(18, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 18.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 18. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 18. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 18. ', 'PUBLISHED', 3, 7, '2026-04-09T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(18, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0106', N'Tom tat AI: bai hoc so 4 cua module 18.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 18. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 18. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 18. ', 'PUBLISHED', 4, 7, '2026-04-09T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(18, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0107', N'Tom tat AI: bai hoc so 5 cua module 18.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 18. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 18. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 18. ', 'PUBLISHED', 5, 7, '2026-04-09T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(18, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 18.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 18. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 18. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 18. ', 'PUBLISHED', 6, 7, '2026-04-09T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(19, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0109', N'Tom tat AI: bai hoc so 1 cua module 19.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 19. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 19. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 19. ', 'DRAFT', 1, 8, '2026-04-10T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(19, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0110', N'Tom tat AI: bai hoc so 2 cua module 19.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 19. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 19. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 19. ', 'PUBLISHED', 2, 8, '2026-04-10T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(19, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 19.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 19. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 19. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 19. ', 'PUBLISHED', 3, 8, '2026-04-10T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(19, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0112', N'Tom tat AI: bai hoc so 4 cua module 19.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 19. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 19. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 19. ', 'PUBLISHED', 4, 8, '2026-04-10T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(19, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0113', N'Tom tat AI: bai hoc so 5 cua module 19.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 19. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 19. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 19. ', 'PUBLISHED', 5, 8, '2026-04-10T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(19, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 19.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 19. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 19. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 19. ', 'PUBLISHED', 6, 8, '2026-04-10T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(20, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0115', N'Tom tat AI: bai hoc so 1 cua module 20.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 20. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 20. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 20. ', 'DRAFT', 1, 9, '2026-04-11T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(20, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0116', N'Tom tat AI: bai hoc so 2 cua module 20.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 20. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 20. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 20. ', 'PUBLISHED', 2, 9, '2026-04-11T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(20, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 20.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 20. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 20. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 20. ', 'PUBLISHED', 3, 9, '2026-04-11T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(20, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0118', N'Tom tat AI: bai hoc so 4 cua module 20.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 20. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 20. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 20. ', 'PUBLISHED', 4, 9, '2026-04-11T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(20, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0119', N'Tom tat AI: bai hoc so 5 cua module 20.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 20. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 20. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 20. ', 'PUBLISHED', 5, 9, '2026-04-11T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(20, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 20.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 20. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 20. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 20. ', 'PUBLISHED', 6, 9, '2026-04-11T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(21, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0121', N'Tom tat AI: bai hoc so 1 cua module 21.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 21. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 21. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 21. ', 'DRAFT', 1, 10, '2026-04-12T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(21, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0122', N'Tom tat AI: bai hoc so 2 cua module 21.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 21. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 21. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 21. ', 'PUBLISHED', 2, 10, '2026-04-12T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(21, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 21.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 21. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 21. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 21. ', 'PUBLISHED', 3, 10, '2026-04-12T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(21, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0124', N'Tom tat AI: bai hoc so 4 cua module 21.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 21. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 21. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 21. ', 'PUBLISHED', 4, 10, '2026-04-12T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(21, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0125', N'Tom tat AI: bai hoc so 5 cua module 21.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 21. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 21. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 21. ', 'PUBLISHED', 5, 10, '2026-04-12T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(21, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 21.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 21. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 21. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 21. ', 'PUBLISHED', 6, 10, '2026-04-12T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(22, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0127', N'Tom tat AI: bai hoc so 1 cua module 22.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 22. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 22. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 22. ', 'DRAFT', 1, 11, '2026-04-13T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(22, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0128', N'Tom tat AI: bai hoc so 2 cua module 22.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 22. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 22. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 22. ', 'PUBLISHED', 2, 11, '2026-04-13T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(22, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 22.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 22. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 22. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 22. ', 'PUBLISHED', 3, 11, '2026-04-13T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(22, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0130', N'Tom tat AI: bai hoc so 4 cua module 22.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 22. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 22. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 22. ', 'PUBLISHED', 4, 11, '2026-04-13T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(22, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0131', N'Tom tat AI: bai hoc so 5 cua module 22.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 22. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 22. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 22. ', 'PUBLISHED', 5, 11, '2026-04-13T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(22, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 22.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 22. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 22. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 22. ', 'PUBLISHED', 6, 11, '2026-04-13T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(23, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0133', N'Tom tat AI: bai hoc so 1 cua module 23.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 23. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 23. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 23. ', 'DRAFT', 1, 12, '2026-04-14T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(23, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0134', N'Tom tat AI: bai hoc so 2 cua module 23.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 23. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 23. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 23. ', 'PUBLISHED', 2, 12, '2026-04-14T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(23, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 23.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 23. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 23. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 23. ', 'PUBLISHED', 3, 12, '2026-04-14T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(23, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0136', N'Tom tat AI: bai hoc so 4 cua module 23.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 23. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 23. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 23. ', 'PUBLISHED', 4, 12, '2026-04-14T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(23, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0137', N'Tom tat AI: bai hoc so 5 cua module 23.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 23. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 23. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 23. ', 'PUBLISHED', 5, 12, '2026-04-14T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(23, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 23.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 23. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 23. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 23. ', 'PUBLISHED', 6, 12, '2026-04-14T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(24, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0139', N'Tom tat AI: bai hoc so 1 cua module 24.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 24. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 24. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 24. ', 'DRAFT', 1, 7, '2026-04-15T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(24, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0140', N'Tom tat AI: bai hoc so 2 cua module 24.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 24. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 24. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 24. ', 'PUBLISHED', 2, 7, '2026-04-15T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(24, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 24.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 24. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 24. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 24. ', 'PUBLISHED', 3, 7, '2026-04-15T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(24, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0142', N'Tom tat AI: bai hoc so 4 cua module 24.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 24. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 24. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 24. ', 'PUBLISHED', 4, 7, '2026-04-15T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(24, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0143', N'Tom tat AI: bai hoc so 5 cua module 24.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 24. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 24. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 24. ', 'PUBLISHED', 5, 7, '2026-04-15T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(24, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 24.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 24. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 24. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 24. ', 'PUBLISHED', 6, 7, '2026-04-15T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(25, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0145', N'Tom tat AI: bai hoc so 1 cua module 25.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 25. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 25. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 25. ', 'DRAFT', 1, 8, '2026-04-16T08:00:00+07:00', '2026-04-26T08:00:00+07:00'),
(25, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0146', N'Tom tat AI: bai hoc so 2 cua module 25.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 25. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 25. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 25. ', 'PUBLISHED', 2, 8, '2026-04-16T08:00:00+07:00', '2026-04-26T08:00:00+07:00'),
(25, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 25.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 25. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 25. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 25. ', 'PUBLISHED', 3, 8, '2026-04-16T08:00:00+07:00', '2026-04-26T08:00:00+07:00'),
(25, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0148', N'Tom tat AI: bai hoc so 4 cua module 25.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 25. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 25. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 25. ', 'PUBLISHED', 4, 8, '2026-04-16T08:00:00+07:00', '2026-04-26T08:00:00+07:00'),
(25, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0149', N'Tom tat AI: bai hoc so 5 cua module 25.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 25. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 25. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 25. ', 'PUBLISHED', 5, 8, '2026-04-16T08:00:00+07:00', '2026-04-26T08:00:00+07:00'),
(25, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 25.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 25. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 25. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 25. ', 'PUBLISHED', 6, 8, '2026-04-16T08:00:00+07:00', '2026-04-26T08:00:00+07:00');
INSERT INTO lesson (module_id, title, video_url, summary, content, status, order_no, created_by, created_at, updated_at) VALUES
(26, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0151', N'Tom tat AI: bai hoc so 1 cua module 26.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 26. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 26. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 26. ', 'DRAFT', 1, 9, '2026-04-17T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(26, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0152', N'Tom tat AI: bai hoc so 2 cua module 26.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 26. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 26. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 26. ', 'PUBLISHED', 2, 9, '2026-04-17T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(26, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 26.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 26. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 26. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 26. ', 'PUBLISHED', 3, 9, '2026-04-17T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(26, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0154', N'Tom tat AI: bai hoc so 4 cua module 26.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 26. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 26. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 26. ', 'PUBLISHED', 4, 9, '2026-04-17T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(26, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0155', N'Tom tat AI: bai hoc so 5 cua module 26.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 26. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 26. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 26. ', 'PUBLISHED', 5, 9, '2026-04-17T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(26, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 26.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 26. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 26. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 26. ', 'PUBLISHED', 6, 9, '2026-04-17T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(27, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0157', N'Tom tat AI: bai hoc so 1 cua module 27.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 27. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 27. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 27. ', 'DRAFT', 1, 10, '2026-04-18T08:00:00+07:00', '2026-04-28T08:00:00+07:00'),
(27, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0158', N'Tom tat AI: bai hoc so 2 cua module 27.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 27. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 27. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 27. ', 'PUBLISHED', 2, 10, '2026-04-18T08:00:00+07:00', '2026-04-28T08:00:00+07:00'),
(27, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 27.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 27. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 27. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 27. ', 'PUBLISHED', 3, 10, '2026-04-18T08:00:00+07:00', '2026-04-28T08:00:00+07:00'),
(27, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0160', N'Tom tat AI: bai hoc so 4 cua module 27.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 27. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 27. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 27. ', 'PUBLISHED', 4, 10, '2026-04-18T08:00:00+07:00', '2026-04-28T08:00:00+07:00'),
(27, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0161', N'Tom tat AI: bai hoc so 5 cua module 27.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 27. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 27. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 27. ', 'PUBLISHED', 5, 10, '2026-04-18T08:00:00+07:00', '2026-04-28T08:00:00+07:00'),
(27, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 27.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 27. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 27. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 27. ', 'PUBLISHED', 6, 10, '2026-04-18T08:00:00+07:00', '2026-04-28T08:00:00+07:00'),
(28, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0163', N'Tom tat AI: bai hoc so 1 cua module 28.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 28. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 28. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 28. ', 'DRAFT', 1, 11, '2026-04-19T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(28, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0164', N'Tom tat AI: bai hoc so 2 cua module 28.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 28. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 28. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 28. ', 'PUBLISHED', 2, 11, '2026-04-19T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(28, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 28.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 28. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 28. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 28. ', 'PUBLISHED', 3, 11, '2026-04-19T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(28, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0166', N'Tom tat AI: bai hoc so 4 cua module 28.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 28. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 28. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 28. ', 'PUBLISHED', 4, 11, '2026-04-19T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(28, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0167', N'Tom tat AI: bai hoc so 5 cua module 28.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 28. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 28. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 28. ', 'PUBLISHED', 5, 11, '2026-04-19T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(28, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 28.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 28. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 28. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 28. ', 'PUBLISHED', 6, 11, '2026-04-19T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(29, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0169', N'Tom tat AI: bai hoc so 1 cua module 29.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 29. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 29. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 29. ', 'DRAFT', 1, 12, '2026-04-20T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(29, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0170', N'Tom tat AI: bai hoc so 2 cua module 29.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 29. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 29. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 29. ', 'PUBLISHED', 2, 12, '2026-04-20T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(29, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 29.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 29. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 29. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 29. ', 'PUBLISHED', 3, 12, '2026-04-20T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(29, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0172', N'Tom tat AI: bai hoc so 4 cua module 29.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 29. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 29. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 29. ', 'PUBLISHED', 4, 12, '2026-04-20T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(29, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0173', N'Tom tat AI: bai hoc so 5 cua module 29.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 29. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 29. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 29. ', 'PUBLISHED', 5, 12, '2026-04-20T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(29, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 29.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 29. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 29. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 29. ', 'PUBLISHED', 6, 12, '2026-04-20T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(30, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0175', N'Tom tat AI: bai hoc so 1 cua module 30.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 30. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 30. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 30. ', 'DRAFT', 1, 7, '2026-04-21T08:00:00+07:00', '2026-05-01T08:00:00+07:00'),
(30, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0176', N'Tom tat AI: bai hoc so 2 cua module 30.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 30. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 30. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 30. ', 'PUBLISHED', 2, 7, '2026-04-21T08:00:00+07:00', '2026-05-01T08:00:00+07:00'),
(30, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 30.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 30. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 30. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 30. ', 'PUBLISHED', 3, 7, '2026-04-21T08:00:00+07:00', '2026-05-01T08:00:00+07:00'),
(30, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0178', N'Tom tat AI: bai hoc so 4 cua module 30.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 30. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 30. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 30. ', 'PUBLISHED', 4, 7, '2026-04-21T08:00:00+07:00', '2026-05-01T08:00:00+07:00'),
(30, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0179', N'Tom tat AI: bai hoc so 5 cua module 30.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 30. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 30. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 30. ', 'PUBLISHED', 5, 7, '2026-04-21T08:00:00+07:00', '2026-05-01T08:00:00+07:00'),
(30, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 30.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 30. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 30. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 30. ', 'PUBLISHED', 6, 7, '2026-04-21T08:00:00+07:00', '2026-05-01T08:00:00+07:00'),
(31, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0181', N'Tom tat AI: bai hoc so 1 cua module 31.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 31. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 31. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 31. ', 'DRAFT', 1, 8, '2026-04-22T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(31, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0182', N'Tom tat AI: bai hoc so 2 cua module 31.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 31. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 31. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 31. ', 'PUBLISHED', 2, 8, '2026-04-22T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(31, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 31.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 31. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 31. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 31. ', 'PUBLISHED', 3, 8, '2026-04-22T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(31, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0184', N'Tom tat AI: bai hoc so 4 cua module 31.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 31. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 31. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 31. ', 'PUBLISHED', 4, 8, '2026-04-22T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(31, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0185', N'Tom tat AI: bai hoc so 5 cua module 31.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 31. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 31. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 31. ', 'PUBLISHED', 5, 8, '2026-04-22T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(31, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 31.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 31. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 31. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 31. ', 'PUBLISHED', 6, 8, '2026-04-22T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(32, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0187', N'Tom tat AI: bai hoc so 1 cua module 32.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 32. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 32. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 32. ', 'DRAFT', 1, 9, '2026-04-23T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(32, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0188', N'Tom tat AI: bai hoc so 2 cua module 32.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 32. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 32. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 32. ', 'PUBLISHED', 2, 9, '2026-04-23T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(32, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 32.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 32. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 32. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 32. ', 'PUBLISHED', 3, 9, '2026-04-23T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(32, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0190', N'Tom tat AI: bai hoc so 4 cua module 32.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 32. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 32. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 32. ', 'PUBLISHED', 4, 9, '2026-04-23T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(32, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0191', N'Tom tat AI: bai hoc so 5 cua module 32.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 32. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 32. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 32. ', 'PUBLISHED', 5, 9, '2026-04-23T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(32, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 32.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 32. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 32. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 32. ', 'PUBLISHED', 6, 9, '2026-04-23T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(33, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0193', N'Tom tat AI: bai hoc so 1 cua module 33.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 33. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 33. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 33. ', 'DRAFT', 1, 10, '2026-04-24T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(33, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0194', N'Tom tat AI: bai hoc so 2 cua module 33.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 33. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 33. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 33. ', 'PUBLISHED', 2, 10, '2026-04-24T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(33, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 33.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 33. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 33. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 33. ', 'PUBLISHED', 3, 10, '2026-04-24T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(33, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0196', N'Tom tat AI: bai hoc so 4 cua module 33.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 33. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 33. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 33. ', 'PUBLISHED', 4, 10, '2026-04-24T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(33, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0197', N'Tom tat AI: bai hoc so 5 cua module 33.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 33. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 33. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 33. ', 'PUBLISHED', 5, 10, '2026-04-24T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(33, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 33.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 33. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 33. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 33. ', 'PUBLISHED', 6, 10, '2026-04-24T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(34, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0199', N'Tom tat AI: bai hoc so 1 cua module 34.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 34. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 34. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 34. ', 'DRAFT', 1, 11, '2026-04-25T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(34, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0200', N'Tom tat AI: bai hoc so 2 cua module 34.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 34. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 34. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 34. ', 'PUBLISHED', 2, 11, '2026-04-25T08:00:00+07:00', '2026-05-05T08:00:00+07:00');
INSERT INTO lesson (module_id, title, video_url, summary, content, status, order_no, created_by, created_at, updated_at) VALUES
(34, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 34.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 34. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 34. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 34. ', 'PUBLISHED', 3, 11, '2026-04-25T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(34, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0202', N'Tom tat AI: bai hoc so 4 cua module 34.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 34. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 34. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 34. ', 'PUBLISHED', 4, 11, '2026-04-25T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(34, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0203', N'Tom tat AI: bai hoc so 5 cua module 34.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 34. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 34. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 34. ', 'PUBLISHED', 5, 11, '2026-04-25T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(34, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 34.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 34. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 34. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 34. ', 'PUBLISHED', 6, 11, '2026-04-25T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(35, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0205', N'Tom tat AI: bai hoc so 1 cua module 35.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 35. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 35. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 35. ', 'DRAFT', 1, 12, '2026-04-26T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(35, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0206', N'Tom tat AI: bai hoc so 2 cua module 35.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 35. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 35. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 35. ', 'PUBLISHED', 2, 12, '2026-04-26T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(35, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 35.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 35. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 35. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 35. ', 'PUBLISHED', 3, 12, '2026-04-26T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(35, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0208', N'Tom tat AI: bai hoc so 4 cua module 35.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 35. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 35. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 35. ', 'PUBLISHED', 4, 12, '2026-04-26T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(35, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0209', N'Tom tat AI: bai hoc so 5 cua module 35.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 35. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 35. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 35. ', 'PUBLISHED', 5, 12, '2026-04-26T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(35, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 35.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 35. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 35. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 35. ', 'PUBLISHED', 6, 12, '2026-04-26T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(36, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0211', N'Tom tat AI: bai hoc so 1 cua module 36.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 36. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 36. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 36. ', 'DRAFT', 1, 7, '2026-04-27T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(36, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0212', N'Tom tat AI: bai hoc so 2 cua module 36.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 36. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 36. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 36. ', 'PUBLISHED', 2, 7, '2026-04-27T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(36, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 36.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 36. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 36. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 36. ', 'PUBLISHED', 3, 7, '2026-04-27T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(36, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0214', N'Tom tat AI: bai hoc so 4 cua module 36.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 36. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 36. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 36. ', 'PUBLISHED', 4, 7, '2026-04-27T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(36, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0215', N'Tom tat AI: bai hoc so 5 cua module 36.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 36. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 36. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 36. ', 'PUBLISHED', 5, 7, '2026-04-27T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(36, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 36.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 36. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 36. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 36. ', 'PUBLISHED', 6, 7, '2026-04-27T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(37, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0217', N'Tom tat AI: bai hoc so 1 cua module 37.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 37. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 37. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 37. ', 'DRAFT', 1, 8, '2026-04-28T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(37, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0218', N'Tom tat AI: bai hoc so 2 cua module 37.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 37. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 37. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 37. ', 'PUBLISHED', 2, 8, '2026-04-28T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(37, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 37.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 37. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 37. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 37. ', 'PUBLISHED', 3, 8, '2026-04-28T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(37, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0220', N'Tom tat AI: bai hoc so 4 cua module 37.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 37. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 37. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 37. ', 'PUBLISHED', 4, 8, '2026-04-28T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(37, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0221', N'Tom tat AI: bai hoc so 5 cua module 37.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 37. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 37. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 37. ', 'PUBLISHED', 5, 8, '2026-04-28T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(37, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 37.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 37. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 37. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 37. ', 'PUBLISHED', 6, 8, '2026-04-28T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(38, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0223', N'Tom tat AI: bai hoc so 1 cua module 38.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 38. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 38. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 38. ', 'DRAFT', 1, 9, '2026-04-29T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(38, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0224', N'Tom tat AI: bai hoc so 2 cua module 38.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 38. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 38. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 38. ', 'PUBLISHED', 2, 9, '2026-04-29T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(38, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 38.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 38. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 38. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 38. ', 'PUBLISHED', 3, 9, '2026-04-29T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(38, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0226', N'Tom tat AI: bai hoc so 4 cua module 38.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 38. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 38. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 38. ', 'PUBLISHED', 4, 9, '2026-04-29T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(38, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0227', N'Tom tat AI: bai hoc so 5 cua module 38.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 38. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 38. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 38. ', 'PUBLISHED', 5, 9, '2026-04-29T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(38, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 38.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 38. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 38. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 38. ', 'PUBLISHED', 6, 9, '2026-04-29T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(39, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0229', N'Tom tat AI: bai hoc so 1 cua module 39.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 39. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 39. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 39. ', 'DRAFT', 1, 10, '2026-04-30T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(39, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0230', N'Tom tat AI: bai hoc so 2 cua module 39.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 39. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 39. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 39. ', 'PUBLISHED', 2, 10, '2026-04-30T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(39, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 39.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 39. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 39. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 39. ', 'PUBLISHED', 3, 10, '2026-04-30T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(39, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0232', N'Tom tat AI: bai hoc so 4 cua module 39.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 39. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 39. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 39. ', 'PUBLISHED', 4, 10, '2026-04-30T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(39, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0233', N'Tom tat AI: bai hoc so 5 cua module 39.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 39. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 39. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 39. ', 'PUBLISHED', 5, 10, '2026-04-30T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(39, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 39.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 39. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 39. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 39. ', 'PUBLISHED', 6, 10, '2026-04-30T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(40, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0235', N'Tom tat AI: bai hoc so 1 cua module 40.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 40. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 40. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 40. ', 'DRAFT', 1, 11, '2026-05-01T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(40, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0236', N'Tom tat AI: bai hoc so 2 cua module 40.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 40. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 40. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 40. ', 'PUBLISHED', 2, 11, '2026-05-01T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(40, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 40.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 40. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 40. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 40. ', 'PUBLISHED', 3, 11, '2026-05-01T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(40, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0238', N'Tom tat AI: bai hoc so 4 cua module 40.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 40. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 40. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 40. ', 'PUBLISHED', 4, 11, '2026-05-01T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(40, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0239', N'Tom tat AI: bai hoc so 5 cua module 40.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 40. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 40. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 40. ', 'PUBLISHED', 5, 11, '2026-05-01T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(40, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 40.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 40. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 40. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 40. ', 'PUBLISHED', 6, 11, '2026-05-01T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(41, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0241', N'Tom tat AI: bai hoc so 1 cua module 41.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 41. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 41. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 41. ', 'DRAFT', 1, 12, '2026-05-02T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(41, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0242', N'Tom tat AI: bai hoc so 2 cua module 41.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 41. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 41. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 41. ', 'PUBLISHED', 2, 12, '2026-05-02T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(41, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 41.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 41. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 41. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 41. ', 'PUBLISHED', 3, 12, '2026-05-02T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(41, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0244', N'Tom tat AI: bai hoc so 4 cua module 41.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 41. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 41. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 41. ', 'PUBLISHED', 4, 12, '2026-05-02T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(41, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0245', N'Tom tat AI: bai hoc so 5 cua module 41.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 41. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 41. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 41. ', 'PUBLISHED', 5, 12, '2026-05-02T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(41, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 41.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 41. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 41. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 41. ', 'PUBLISHED', 6, 12, '2026-05-02T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(42, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0247', N'Tom tat AI: bai hoc so 1 cua module 42.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 42. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 42. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 42. ', 'DRAFT', 1, 7, '2026-05-03T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(42, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0248', N'Tom tat AI: bai hoc so 2 cua module 42.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 42. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 42. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 42. ', 'PUBLISHED', 2, 7, '2026-05-03T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(42, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 42.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 42. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 42. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 42. ', 'PUBLISHED', 3, 7, '2026-05-03T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(42, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0250', N'Tom tat AI: bai hoc so 4 cua module 42.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 42. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 42. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 42. ', 'PUBLISHED', 4, 7, '2026-05-03T08:00:00+07:00', '2026-05-13T08:00:00+07:00');
INSERT INTO lesson (module_id, title, video_url, summary, content, status, order_no, created_by, created_at, updated_at) VALUES
(42, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0251', N'Tom tat AI: bai hoc so 5 cua module 42.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 42. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 42. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 42. ', 'PUBLISHED', 5, 7, '2026-05-03T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(42, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 42.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 42. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 42. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 42. ', 'PUBLISHED', 6, 7, '2026-05-03T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(43, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0253', N'Tom tat AI: bai hoc so 1 cua module 43.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 43. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 43. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 43. ', 'DRAFT', 1, 8, '2026-05-04T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(43, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0254', N'Tom tat AI: bai hoc so 2 cua module 43.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 43. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 43. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 43. ', 'PUBLISHED', 2, 8, '2026-05-04T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(43, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 43.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 43. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 43. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 43. ', 'PUBLISHED', 3, 8, '2026-05-04T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(43, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0256', N'Tom tat AI: bai hoc so 4 cua module 43.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 43. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 43. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 43. ', 'PUBLISHED', 4, 8, '2026-05-04T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(43, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0257', N'Tom tat AI: bai hoc so 5 cua module 43.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 43. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 43. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 43. ', 'PUBLISHED', 5, 8, '2026-05-04T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(43, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 43.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 43. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 43. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 43. ', 'PUBLISHED', 6, 8, '2026-05-04T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(44, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0259', N'Tom tat AI: bai hoc so 1 cua module 44.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 44. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 44. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 44. ', 'DRAFT', 1, 9, '2026-05-05T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(44, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0260', N'Tom tat AI: bai hoc so 2 cua module 44.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 44. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 44. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 44. ', 'PUBLISHED', 2, 9, '2026-05-05T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(44, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 44.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 44. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 44. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 44. ', 'PUBLISHED', 3, 9, '2026-05-05T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(44, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0262', N'Tom tat AI: bai hoc so 4 cua module 44.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 44. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 44. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 44. ', 'PUBLISHED', 4, 9, '2026-05-05T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(44, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0263', N'Tom tat AI: bai hoc so 5 cua module 44.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 44. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 44. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 44. ', 'PUBLISHED', 5, 9, '2026-05-05T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(44, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 44.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 44. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 44. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 44. ', 'PUBLISHED', 6, 9, '2026-05-05T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(45, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0265', N'Tom tat AI: bai hoc so 1 cua module 45.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 45. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 45. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 45. ', 'DRAFT', 1, 10, '2026-05-06T08:00:00+07:00', '2026-05-16T08:00:00+07:00'),
(45, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0266', N'Tom tat AI: bai hoc so 2 cua module 45.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 45. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 45. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 45. ', 'PUBLISHED', 2, 10, '2026-05-06T08:00:00+07:00', '2026-05-16T08:00:00+07:00'),
(45, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 45.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 45. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 45. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 45. ', 'PUBLISHED', 3, 10, '2026-05-06T08:00:00+07:00', '2026-05-16T08:00:00+07:00'),
(45, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0268', N'Tom tat AI: bai hoc so 4 cua module 45.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 45. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 45. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 45. ', 'PUBLISHED', 4, 10, '2026-05-06T08:00:00+07:00', '2026-05-16T08:00:00+07:00'),
(45, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0269', N'Tom tat AI: bai hoc so 5 cua module 45.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 45. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 45. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 45. ', 'PUBLISHED', 5, 10, '2026-05-06T08:00:00+07:00', '2026-05-16T08:00:00+07:00'),
(45, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 45.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 45. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 45. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 45. ', 'PUBLISHED', 6, 10, '2026-05-06T08:00:00+07:00', '2026-05-16T08:00:00+07:00'),
(46, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0271', N'Tom tat AI: bai hoc so 1 cua module 46.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 46. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 46. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 46. ', 'DRAFT', 1, 11, '2026-05-07T08:00:00+07:00', '2026-05-17T08:00:00+07:00'),
(46, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0272', N'Tom tat AI: bai hoc so 2 cua module 46.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 46. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 46. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 46. ', 'PUBLISHED', 2, 11, '2026-05-07T08:00:00+07:00', '2026-05-17T08:00:00+07:00'),
(46, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 46.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 46. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 46. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 46. ', 'PUBLISHED', 3, 11, '2026-05-07T08:00:00+07:00', '2026-05-17T08:00:00+07:00'),
(46, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0274', N'Tom tat AI: bai hoc so 4 cua module 46.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 46. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 46. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 46. ', 'PUBLISHED', 4, 11, '2026-05-07T08:00:00+07:00', '2026-05-17T08:00:00+07:00'),
(46, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0275', N'Tom tat AI: bai hoc so 5 cua module 46.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 46. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 46. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 46. ', 'PUBLISHED', 5, 11, '2026-05-07T08:00:00+07:00', '2026-05-17T08:00:00+07:00'),
(46, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 46.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 46. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 46. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 46. ', 'PUBLISHED', 6, 11, '2026-05-07T08:00:00+07:00', '2026-05-17T08:00:00+07:00'),
(47, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0277', N'Tom tat AI: bai hoc so 1 cua module 47.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 47. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 47. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 47. ', 'DRAFT', 1, 12, '2026-05-08T08:00:00+07:00', '2026-05-18T08:00:00+07:00'),
(47, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0278', N'Tom tat AI: bai hoc so 2 cua module 47.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 47. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 47. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 47. ', 'PUBLISHED', 2, 12, '2026-05-08T08:00:00+07:00', '2026-05-18T08:00:00+07:00'),
(47, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 47.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 47. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 47. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 47. ', 'PUBLISHED', 3, 12, '2026-05-08T08:00:00+07:00', '2026-05-18T08:00:00+07:00'),
(47, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0280', N'Tom tat AI: bai hoc so 4 cua module 47.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 47. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 47. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 47. ', 'PUBLISHED', 4, 12, '2026-05-08T08:00:00+07:00', '2026-05-18T08:00:00+07:00'),
(47, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0281', N'Tom tat AI: bai hoc so 5 cua module 47.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 47. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 47. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 47. ', 'PUBLISHED', 5, 12, '2026-05-08T08:00:00+07:00', '2026-05-18T08:00:00+07:00'),
(47, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 47.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 47. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 47. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 47. ', 'PUBLISHED', 6, 12, '2026-05-08T08:00:00+07:00', '2026-05-18T08:00:00+07:00'),
(48, N'Bai 1: Noi dung hoc phan 1', N'https://www.youtube.com/watch?v=EduNexusDemo0283', N'Tom tat AI: bai hoc so 1 cua module 48.', N'# Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 48. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 48. # Bai 1

Noi dung Markdown chi tiet cua bai giang so 1 thuoc module 48. ', 'DRAFT', 1, 7, '2026-05-09T08:00:00+07:00', '2026-05-19T08:00:00+07:00'),
(48, N'Bai 2: Noi dung hoc phan 2', N'https://www.youtube.com/watch?v=EduNexusDemo0284', N'Tom tat AI: bai hoc so 2 cua module 48.', N'# Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 48. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 48. # Bai 2

Noi dung Markdown chi tiet cua bai giang so 2 thuoc module 48. ', 'PUBLISHED', 2, 7, '2026-05-09T08:00:00+07:00', '2026-05-19T08:00:00+07:00'),
(48, N'Bai 3: Noi dung hoc phan 3', NULL, N'Tom tat AI: bai hoc so 3 cua module 48.', N'# Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 48. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 48. # Bai 3

Noi dung Markdown chi tiet cua bai giang so 3 thuoc module 48. ', 'PUBLISHED', 3, 7, '2026-05-09T08:00:00+07:00', '2026-05-19T08:00:00+07:00'),
(48, N'Bai 4: Noi dung hoc phan 4', N'https://www.youtube.com/watch?v=EduNexusDemo0286', N'Tom tat AI: bai hoc so 4 cua module 48.', N'# Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 48. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 48. # Bai 4

Noi dung Markdown chi tiet cua bai giang so 4 thuoc module 48. ', 'PUBLISHED', 4, 7, '2026-05-09T08:00:00+07:00', '2026-05-19T08:00:00+07:00'),
(48, N'Bai 5: Noi dung hoc phan 5', N'https://www.youtube.com/watch?v=EduNexusDemo0287', N'Tom tat AI: bai hoc so 5 cua module 48.', N'# Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 48. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 48. # Bai 5

Noi dung Markdown chi tiet cua bai giang so 5 thuoc module 48. ', 'PUBLISHED', 5, 7, '2026-05-09T08:00:00+07:00', '2026-05-19T08:00:00+07:00'),
(48, N'Bai 6: Noi dung hoc phan 6', NULL, N'Tom tat AI: bai hoc so 6 cua module 48.', N'# Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 48. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 48. # Bai 6

Noi dung Markdown chi tiet cua bai giang so 6 thuoc module 48. ', 'PUBLISHED', 6, 7, '2026-05-09T08:00:00+07:00', '2026-05-19T08:00:00+07:00');
GO

-- lesson_view_event: 200 rows
INSERT INTO lesson_view_event (lesson_id, student_id, viewed_at, watch_seconds, completed) VALUES
(2, 25, '2026-04-11T08:00:00+07:00', 120, 0),
(3, 26, '2026-04-12T08:00:00+07:00', 133, 1),
(4, 27, '2026-04-13T08:00:00+07:00', 146, 1),
(5, 28, '2026-04-14T08:00:00+07:00', 159, 0),
(6, 29, '2026-04-15T08:00:00+07:00', 172, 1),
(8, 30, '2026-04-16T08:00:00+07:00', 185, 1),
(9, 31, '2026-04-17T08:00:00+07:00', 198, 0),
(10, 32, '2026-04-18T08:00:00+07:00', 211, 1),
(11, 33, '2026-04-19T08:00:00+07:00', 224, 1),
(12, 34, '2026-04-20T08:00:00+07:00', 237, 0),
(14, 35, '2026-04-21T08:00:00+07:00', 250, 1),
(15, 36, '2026-04-22T08:00:00+07:00', 263, 1),
(16, 37, '2026-04-23T08:00:00+07:00', 276, 0),
(17, 38, '2026-04-24T08:00:00+07:00', 289, 1),
(18, 39, '2026-04-25T08:00:00+07:00', 302, 1),
(20, 40, '2026-04-26T08:00:00+07:00', 315, 0),
(21, 41, '2026-04-27T08:00:00+07:00', 328, 1),
(22, 42, '2026-04-28T08:00:00+07:00', 341, 1),
(23, 43, '2026-04-29T08:00:00+07:00', 354, 0),
(24, 44, '2026-04-30T08:00:00+07:00', 367, 1),
(26, 45, '2026-05-01T08:00:00+07:00', 380, 1),
(27, 46, '2026-05-02T08:00:00+07:00', 393, 0),
(28, 47, '2026-05-03T08:00:00+07:00', 406, 1),
(29, 48, '2026-05-04T08:00:00+07:00', 419, 1),
(30, 49, '2026-05-05T08:00:00+07:00', 432, 0),
(32, 50, '2026-05-06T08:00:00+07:00', 445, 1),
(33, 51, '2026-05-07T08:00:00+07:00', 458, 1),
(34, 52, '2026-05-08T08:00:00+07:00', 471, 0),
(35, 53, '2026-05-09T08:00:00+07:00', 484, 1),
(36, 54, '2026-05-10T08:00:00+07:00', 497, 1),
(38, 25, '2026-04-11T08:00:00+07:00', 510, 0),
(39, 26, '2026-04-12T08:00:00+07:00', 523, 1),
(40, 27, '2026-04-13T08:00:00+07:00', 536, 1),
(41, 28, '2026-04-14T08:00:00+07:00', 549, 0),
(42, 29, '2026-04-15T08:00:00+07:00', 562, 1),
(44, 30, '2026-04-16T08:00:00+07:00', 575, 1),
(45, 31, '2026-04-17T08:00:00+07:00', 588, 0),
(46, 32, '2026-04-18T08:00:00+07:00', 601, 1),
(47, 33, '2026-04-19T08:00:00+07:00', 614, 1),
(48, 34, '2026-04-20T08:00:00+07:00', 627, 0),
(50, 35, '2026-04-21T08:00:00+07:00', 640, 1),
(51, 36, '2026-04-22T08:00:00+07:00', 653, 1),
(52, 37, '2026-04-23T08:00:00+07:00', 666, 0),
(53, 38, '2026-04-24T08:00:00+07:00', 679, 1),
(54, 39, '2026-04-25T08:00:00+07:00', 692, 1),
(56, 40, '2026-04-26T08:00:00+07:00', 705, 0),
(57, 41, '2026-04-27T08:00:00+07:00', 718, 1),
(58, 42, '2026-04-28T08:00:00+07:00', 731, 1),
(59, 43, '2026-04-29T08:00:00+07:00', 744, 0),
(60, 44, '2026-04-30T08:00:00+07:00', 757, 1);
INSERT INTO lesson_view_event (lesson_id, student_id, viewed_at, watch_seconds, completed) VALUES
(62, 45, '2026-05-01T08:00:00+07:00', 770, 1),
(63, 46, '2026-05-02T08:00:00+07:00', 783, 0),
(64, 47, '2026-05-03T08:00:00+07:00', 796, 1),
(65, 48, '2026-05-04T08:00:00+07:00', 809, 1),
(66, 49, '2026-05-05T08:00:00+07:00', 822, 0),
(68, 50, '2026-05-06T08:00:00+07:00', 835, 1),
(69, 51, '2026-05-07T08:00:00+07:00', 848, 1),
(70, 52, '2026-05-08T08:00:00+07:00', 861, 0),
(71, 53, '2026-05-09T08:00:00+07:00', 874, 1),
(72, 54, '2026-05-10T08:00:00+07:00', 887, 1),
(74, 25, '2026-04-11T08:00:00+07:00', 900, 0),
(75, 26, '2026-04-12T08:00:00+07:00', 913, 1),
(76, 27, '2026-04-13T08:00:00+07:00', 926, 1),
(77, 28, '2026-04-14T08:00:00+07:00', 939, 0),
(78, 29, '2026-04-15T08:00:00+07:00', 952, 1),
(80, 30, '2026-04-16T08:00:00+07:00', 965, 1),
(81, 31, '2026-04-17T08:00:00+07:00', 978, 0),
(82, 32, '2026-04-18T08:00:00+07:00', 991, 1),
(83, 33, '2026-04-19T08:00:00+07:00', 1004, 1),
(84, 34, '2026-04-20T08:00:00+07:00', 1017, 0),
(86, 35, '2026-04-21T08:00:00+07:00', 130, 1),
(87, 36, '2026-04-22T08:00:00+07:00', 143, 1),
(88, 37, '2026-04-23T08:00:00+07:00', 156, 0),
(89, 38, '2026-04-24T08:00:00+07:00', 169, 1),
(90, 39, '2026-04-25T08:00:00+07:00', 182, 1),
(92, 40, '2026-04-26T08:00:00+07:00', 195, 0),
(93, 41, '2026-04-27T08:00:00+07:00', 208, 1),
(94, 42, '2026-04-28T08:00:00+07:00', 221, 1),
(95, 43, '2026-04-29T08:00:00+07:00', 234, 0),
(96, 44, '2026-04-30T08:00:00+07:00', 247, 1),
(98, 45, '2026-05-01T08:00:00+07:00', 260, 1),
(99, 46, '2026-05-02T08:00:00+07:00', 273, 0),
(100, 47, '2026-05-03T08:00:00+07:00', 286, 1),
(101, 48, '2026-05-04T08:00:00+07:00', 299, 1),
(102, 49, '2026-05-05T08:00:00+07:00', 312, 0),
(104, 50, '2026-05-06T08:00:00+07:00', 325, 1),
(105, 51, '2026-05-07T08:00:00+07:00', 338, 1),
(106, 52, '2026-05-08T08:00:00+07:00', 351, 0),
(107, 53, '2026-05-09T08:00:00+07:00', 364, 1),
(108, 54, '2026-05-10T08:00:00+07:00', 377, 1),
(110, 25, '2026-04-11T08:00:00+07:00', 390, 0),
(111, 26, '2026-04-12T08:00:00+07:00', 403, 1),
(112, 27, '2026-04-13T08:00:00+07:00', 416, 1),
(113, 28, '2026-04-14T08:00:00+07:00', 429, 0),
(114, 29, '2026-04-15T08:00:00+07:00', 442, 1),
(116, 30, '2026-04-16T08:00:00+07:00', 455, 1),
(117, 31, '2026-04-17T08:00:00+07:00', 468, 0),
(118, 32, '2026-04-18T08:00:00+07:00', 481, 1),
(119, 33, '2026-04-19T08:00:00+07:00', 494, 1),
(120, 34, '2026-04-20T08:00:00+07:00', 507, 0);
INSERT INTO lesson_view_event (lesson_id, student_id, viewed_at, watch_seconds, completed) VALUES
(122, 35, '2026-04-21T08:00:00+07:00', 520, 1),
(123, 36, '2026-04-22T08:00:00+07:00', 533, 1),
(124, 37, '2026-04-23T08:00:00+07:00', 546, 0),
(125, 38, '2026-04-24T08:00:00+07:00', 559, 1),
(126, 39, '2026-04-25T08:00:00+07:00', 572, 1),
(128, 40, '2026-04-26T08:00:00+07:00', 585, 0),
(129, 41, '2026-04-27T08:00:00+07:00', 598, 1),
(130, 42, '2026-04-28T08:00:00+07:00', 611, 1),
(131, 43, '2026-04-29T08:00:00+07:00', 624, 0),
(132, 44, '2026-04-30T08:00:00+07:00', 637, 1),
(134, 45, '2026-05-01T08:00:00+07:00', 650, 1),
(135, 46, '2026-05-02T08:00:00+07:00', 663, 0),
(136, 47, '2026-05-03T08:00:00+07:00', 676, 1),
(137, 48, '2026-05-04T08:00:00+07:00', 689, 1),
(138, 49, '2026-05-05T08:00:00+07:00', 702, 0),
(140, 50, '2026-05-06T08:00:00+07:00', 715, 1),
(141, 51, '2026-05-07T08:00:00+07:00', 728, 1),
(142, 52, '2026-05-08T08:00:00+07:00', 741, 0),
(143, 53, '2026-05-09T08:00:00+07:00', 754, 1),
(144, 54, '2026-05-10T08:00:00+07:00', 767, 1),
(146, 25, '2026-04-11T08:00:00+07:00', 780, 0),
(147, 26, '2026-04-12T08:00:00+07:00', 793, 1),
(148, 27, '2026-04-13T08:00:00+07:00', 806, 1),
(149, 28, '2026-04-14T08:00:00+07:00', 819, 0),
(150, 29, '2026-04-15T08:00:00+07:00', 832, 1),
(152, 30, '2026-04-16T08:00:00+07:00', 845, 1),
(153, 31, '2026-04-17T08:00:00+07:00', 858, 0),
(154, 32, '2026-04-18T08:00:00+07:00', 871, 1),
(155, 33, '2026-04-19T08:00:00+07:00', 884, 1),
(156, 34, '2026-04-20T08:00:00+07:00', 897, 0),
(158, 35, '2026-04-21T08:00:00+07:00', 910, 1),
(159, 36, '2026-04-22T08:00:00+07:00', 923, 1),
(160, 37, '2026-04-23T08:00:00+07:00', 936, 0),
(161, 38, '2026-04-24T08:00:00+07:00', 949, 1),
(162, 39, '2026-04-25T08:00:00+07:00', 962, 1),
(164, 40, '2026-04-26T08:00:00+07:00', 975, 0),
(165, 41, '2026-04-27T08:00:00+07:00', 988, 1),
(166, 42, '2026-04-28T08:00:00+07:00', 1001, 1),
(167, 43, '2026-04-29T08:00:00+07:00', 1014, 0),
(168, 44, '2026-04-30T08:00:00+07:00', 127, 1),
(170, 45, '2026-05-01T08:00:00+07:00', 140, 1),
(171, 46, '2026-05-02T08:00:00+07:00', 153, 0),
(172, 47, '2026-05-03T08:00:00+07:00', 166, 1),
(173, 48, '2026-05-04T08:00:00+07:00', 179, 1),
(174, 49, '2026-05-05T08:00:00+07:00', 192, 0),
(176, 50, '2026-05-06T08:00:00+07:00', 205, 1),
(177, 51, '2026-05-07T08:00:00+07:00', 218, 1),
(178, 52, '2026-05-08T08:00:00+07:00', 231, 0),
(179, 53, '2026-05-09T08:00:00+07:00', 244, 1),
(180, 54, '2026-05-10T08:00:00+07:00', 257, 1);
INSERT INTO lesson_view_event (lesson_id, student_id, viewed_at, watch_seconds, completed) VALUES
(182, 25, '2026-04-11T08:00:00+07:00', 270, 0),
(183, 26, '2026-04-12T08:00:00+07:00', 283, 1),
(184, 27, '2026-04-13T08:00:00+07:00', 296, 1),
(185, 28, '2026-04-14T08:00:00+07:00', 309, 0),
(186, 29, '2026-04-15T08:00:00+07:00', 322, 1),
(188, 30, '2026-04-16T08:00:00+07:00', 335, 1),
(189, 31, '2026-04-17T08:00:00+07:00', 348, 0),
(190, 32, '2026-04-18T08:00:00+07:00', 361, 1),
(191, 33, '2026-04-19T08:00:00+07:00', 374, 1),
(192, 34, '2026-04-20T08:00:00+07:00', 387, 0),
(194, 35, '2026-04-21T08:00:00+07:00', 400, 1),
(195, 36, '2026-04-22T08:00:00+07:00', 413, 1),
(196, 37, '2026-04-23T08:00:00+07:00', 426, 0),
(197, 38, '2026-04-24T08:00:00+07:00', 439, 1),
(198, 39, '2026-04-25T08:00:00+07:00', 452, 1),
(200, 40, '2026-04-26T08:00:00+07:00', 465, 0),
(201, 41, '2026-04-27T08:00:00+07:00', 478, 1),
(202, 42, '2026-04-28T08:00:00+07:00', 491, 1),
(203, 43, '2026-04-29T08:00:00+07:00', 504, 0),
(204, 44, '2026-04-30T08:00:00+07:00', 517, 1),
(206, 45, '2026-05-01T08:00:00+07:00', 530, 1),
(207, 46, '2026-05-02T08:00:00+07:00', 543, 0),
(208, 47, '2026-05-03T08:00:00+07:00', 556, 1),
(209, 48, '2026-05-04T08:00:00+07:00', 569, 1),
(210, 49, '2026-05-05T08:00:00+07:00', 582, 0),
(212, 50, '2026-05-06T08:00:00+07:00', 595, 1),
(213, 51, '2026-05-07T08:00:00+07:00', 608, 1),
(214, 52, '2026-05-08T08:00:00+07:00', 621, 0),
(215, 53, '2026-05-09T08:00:00+07:00', 634, 1),
(216, 54, '2026-05-10T08:00:00+07:00', 647, 1),
(218, 25, '2026-04-11T08:00:00+07:00', 660, 0),
(219, 26, '2026-04-12T08:00:00+07:00', 673, 1),
(220, 27, '2026-04-13T08:00:00+07:00', 686, 1),
(221, 28, '2026-04-14T08:00:00+07:00', 699, 0),
(222, 29, '2026-04-15T08:00:00+07:00', 712, 1),
(224, 30, '2026-04-16T08:00:00+07:00', 725, 1),
(225, 31, '2026-04-17T08:00:00+07:00', 738, 0),
(226, 32, '2026-04-18T08:00:00+07:00', 751, 1),
(227, 33, '2026-04-19T08:00:00+07:00', 764, 1),
(228, 34, '2026-04-20T08:00:00+07:00', 777, 0),
(230, 35, '2026-04-21T08:00:00+07:00', 790, 1),
(231, 36, '2026-04-22T08:00:00+07:00', 803, 1),
(232, 37, '2026-04-23T08:00:00+07:00', 816, 0),
(233, 38, '2026-04-24T08:00:00+07:00', 829, 1),
(234, 39, '2026-04-25T08:00:00+07:00', 842, 1),
(236, 40, '2026-04-26T08:00:00+07:00', 855, 0),
(237, 41, '2026-04-27T08:00:00+07:00', 868, 1),
(238, 42, '2026-04-28T08:00:00+07:00', 881, 1),
(239, 43, '2026-04-29T08:00:00+07:00', 894, 0),
(240, 44, '2026-04-30T08:00:00+07:00', 907, 1);
GO

-- question: 144 rows
INSERT INTO question (module_id, content, option_a, option_b, option_c, option_d, correct_option, difficulty, ai_explanation, source, status, created_by, approved_by, created_at) VALUES
(1, N'Cau hoi 1 cua module 1: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-02T08:00:00+07:00'),
(1, N'Cau hoi 2 cua module 1: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-02T08:00:00+07:00'),
(1, N'Cau hoi 3 cua module 1: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-02T08:00:00+07:00'),
(2, N'Cau hoi 1 cua module 2: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-03T08:00:00+07:00'),
(2, N'Cau hoi 2 cua module 2: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-03T08:00:00+07:00'),
(2, N'Cau hoi 3 cua module 2: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-03T08:00:00+07:00'),
(3, N'Cau hoi 1 cua module 3: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-04T08:00:00+07:00'),
(3, N'Cau hoi 2 cua module 3: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-04T08:00:00+07:00'),
(3, N'Cau hoi 3 cua module 3: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-04T08:00:00+07:00'),
(4, N'Cau hoi 1 cua module 4: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-05T08:00:00+07:00'),
(4, N'Cau hoi 2 cua module 4: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-05T08:00:00+07:00'),
(4, N'Cau hoi 3 cua module 4: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-05T08:00:00+07:00'),
(5, N'Cau hoi 1 cua module 5: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-06T08:00:00+07:00'),
(5, N'Cau hoi 2 cua module 5: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-06T08:00:00+07:00'),
(5, N'Cau hoi 3 cua module 5: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-06T08:00:00+07:00'),
(6, N'Cau hoi 1 cua module 6: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-07T08:00:00+07:00'),
(6, N'Cau hoi 2 cua module 6: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-07T08:00:00+07:00'),
(6, N'Cau hoi 3 cua module 6: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-07T08:00:00+07:00'),
(7, N'Cau hoi 1 cua module 7: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-08T08:00:00+07:00'),
(7, N'Cau hoi 2 cua module 7: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-08T08:00:00+07:00'),
(7, N'Cau hoi 3 cua module 7: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-08T08:00:00+07:00'),
(8, N'Cau hoi 1 cua module 8: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-09T08:00:00+07:00'),
(8, N'Cau hoi 2 cua module 8: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-09T08:00:00+07:00'),
(8, N'Cau hoi 3 cua module 8: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-09T08:00:00+07:00'),
(9, N'Cau hoi 1 cua module 9: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-10T08:00:00+07:00'),
(9, N'Cau hoi 2 cua module 9: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-10T08:00:00+07:00'),
(9, N'Cau hoi 3 cua module 9: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-10T08:00:00+07:00'),
(10, N'Cau hoi 1 cua module 10: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-11T08:00:00+07:00'),
(10, N'Cau hoi 2 cua module 10: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-11T08:00:00+07:00'),
(10, N'Cau hoi 3 cua module 10: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-11T08:00:00+07:00'),
(11, N'Cau hoi 1 cua module 11: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-12T08:00:00+07:00'),
(11, N'Cau hoi 2 cua module 11: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-12T08:00:00+07:00'),
(11, N'Cau hoi 3 cua module 11: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-12T08:00:00+07:00'),
(12, N'Cau hoi 1 cua module 12: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-13T08:00:00+07:00'),
(12, N'Cau hoi 2 cua module 12: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-13T08:00:00+07:00'),
(12, N'Cau hoi 3 cua module 12: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-13T08:00:00+07:00'),
(13, N'Cau hoi 1 cua module 13: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-14T08:00:00+07:00'),
(13, N'Cau hoi 2 cua module 13: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-14T08:00:00+07:00'),
(13, N'Cau hoi 3 cua module 13: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-14T08:00:00+07:00'),
(14, N'Cau hoi 1 cua module 14: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-15T08:00:00+07:00'),
(14, N'Cau hoi 2 cua module 14: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-15T08:00:00+07:00'),
(14, N'Cau hoi 3 cua module 14: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-15T08:00:00+07:00'),
(15, N'Cau hoi 1 cua module 15: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-16T08:00:00+07:00'),
(15, N'Cau hoi 2 cua module 15: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-16T08:00:00+07:00'),
(15, N'Cau hoi 3 cua module 15: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-16T08:00:00+07:00'),
(16, N'Cau hoi 1 cua module 16: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-17T08:00:00+07:00'),
(16, N'Cau hoi 2 cua module 16: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-17T08:00:00+07:00'),
(16, N'Cau hoi 3 cua module 16: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-17T08:00:00+07:00'),
(17, N'Cau hoi 1 cua module 17: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-18T08:00:00+07:00'),
(17, N'Cau hoi 2 cua module 17: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-18T08:00:00+07:00');
INSERT INTO question (module_id, content, option_a, option_b, option_c, option_d, correct_option, difficulty, ai_explanation, source, status, created_by, approved_by, created_at) VALUES
(17, N'Cau hoi 3 cua module 17: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-18T08:00:00+07:00'),
(18, N'Cau hoi 1 cua module 18: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-19T08:00:00+07:00'),
(18, N'Cau hoi 2 cua module 18: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-19T08:00:00+07:00'),
(18, N'Cau hoi 3 cua module 18: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-19T08:00:00+07:00'),
(19, N'Cau hoi 1 cua module 19: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-20T08:00:00+07:00'),
(19, N'Cau hoi 2 cua module 19: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-20T08:00:00+07:00'),
(19, N'Cau hoi 3 cua module 19: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-20T08:00:00+07:00'),
(20, N'Cau hoi 1 cua module 20: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-21T08:00:00+07:00'),
(20, N'Cau hoi 2 cua module 20: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-21T08:00:00+07:00'),
(20, N'Cau hoi 3 cua module 20: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-21T08:00:00+07:00'),
(21, N'Cau hoi 1 cua module 21: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-22T08:00:00+07:00'),
(21, N'Cau hoi 2 cua module 21: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-22T08:00:00+07:00'),
(21, N'Cau hoi 3 cua module 21: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-22T08:00:00+07:00'),
(22, N'Cau hoi 1 cua module 22: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-23T08:00:00+07:00'),
(22, N'Cau hoi 2 cua module 22: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-23T08:00:00+07:00'),
(22, N'Cau hoi 3 cua module 22: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-23T08:00:00+07:00'),
(23, N'Cau hoi 1 cua module 23: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-24T08:00:00+07:00'),
(23, N'Cau hoi 2 cua module 23: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-24T08:00:00+07:00'),
(23, N'Cau hoi 3 cua module 23: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-24T08:00:00+07:00'),
(24, N'Cau hoi 1 cua module 24: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-25T08:00:00+07:00'),
(24, N'Cau hoi 2 cua module 24: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-25T08:00:00+07:00'),
(24, N'Cau hoi 3 cua module 24: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-25T08:00:00+07:00'),
(25, N'Cau hoi 1 cua module 25: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-26T08:00:00+07:00'),
(25, N'Cau hoi 2 cua module 25: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-26T08:00:00+07:00'),
(25, N'Cau hoi 3 cua module 25: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-26T08:00:00+07:00'),
(26, N'Cau hoi 1 cua module 26: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-27T08:00:00+07:00'),
(26, N'Cau hoi 2 cua module 26: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-27T08:00:00+07:00'),
(26, N'Cau hoi 3 cua module 26: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-27T08:00:00+07:00'),
(27, N'Cau hoi 1 cua module 27: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-28T08:00:00+07:00'),
(27, N'Cau hoi 2 cua module 27: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-28T08:00:00+07:00'),
(27, N'Cau hoi 3 cua module 27: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-28T08:00:00+07:00'),
(28, N'Cau hoi 1 cua module 28: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-04-29T08:00:00+07:00'),
(28, N'Cau hoi 2 cua module 28: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-04-29T08:00:00+07:00'),
(28, N'Cau hoi 3 cua module 28: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-04-29T08:00:00+07:00'),
(29, N'Cau hoi 1 cua module 29: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-04-30T08:00:00+07:00'),
(29, N'Cau hoi 2 cua module 29: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-04-30T08:00:00+07:00'),
(29, N'Cau hoi 3 cua module 29: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-04-30T08:00:00+07:00'),
(30, N'Cau hoi 1 cua module 30: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-01T08:00:00+07:00'),
(30, N'Cau hoi 2 cua module 30: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-01T08:00:00+07:00'),
(30, N'Cau hoi 3 cua module 30: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-01T08:00:00+07:00'),
(31, N'Cau hoi 1 cua module 31: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-02T08:00:00+07:00'),
(31, N'Cau hoi 2 cua module 31: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-02T08:00:00+07:00'),
(31, N'Cau hoi 3 cua module 31: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-02T08:00:00+07:00'),
(32, N'Cau hoi 1 cua module 32: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-03T08:00:00+07:00'),
(32, N'Cau hoi 2 cua module 32: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-03T08:00:00+07:00'),
(32, N'Cau hoi 3 cua module 32: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-03T08:00:00+07:00'),
(33, N'Cau hoi 1 cua module 33: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-04T08:00:00+07:00'),
(33, N'Cau hoi 2 cua module 33: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-04T08:00:00+07:00'),
(33, N'Cau hoi 3 cua module 33: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-04T08:00:00+07:00'),
(34, N'Cau hoi 1 cua module 34: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-05T08:00:00+07:00');
INSERT INTO question (module_id, content, option_a, option_b, option_c, option_d, correct_option, difficulty, ai_explanation, source, status, created_by, approved_by, created_at) VALUES
(34, N'Cau hoi 2 cua module 34: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-05T08:00:00+07:00'),
(34, N'Cau hoi 3 cua module 34: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-05T08:00:00+07:00'),
(35, N'Cau hoi 1 cua module 35: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-06T08:00:00+07:00'),
(35, N'Cau hoi 2 cua module 35: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-06T08:00:00+07:00'),
(35, N'Cau hoi 3 cua module 35: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-06T08:00:00+07:00'),
(36, N'Cau hoi 1 cua module 36: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-07T08:00:00+07:00'),
(36, N'Cau hoi 2 cua module 36: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-07T08:00:00+07:00'),
(36, N'Cau hoi 3 cua module 36: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-07T08:00:00+07:00'),
(37, N'Cau hoi 1 cua module 37: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-08T08:00:00+07:00'),
(37, N'Cau hoi 2 cua module 37: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-08T08:00:00+07:00'),
(37, N'Cau hoi 3 cua module 37: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-08T08:00:00+07:00'),
(38, N'Cau hoi 1 cua module 38: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-09T08:00:00+07:00'),
(38, N'Cau hoi 2 cua module 38: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-09T08:00:00+07:00'),
(38, N'Cau hoi 3 cua module 38: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-09T08:00:00+07:00'),
(39, N'Cau hoi 1 cua module 39: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-10T08:00:00+07:00'),
(39, N'Cau hoi 2 cua module 39: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-10T08:00:00+07:00'),
(39, N'Cau hoi 3 cua module 39: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-10T08:00:00+07:00'),
(40, N'Cau hoi 1 cua module 40: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-11T08:00:00+07:00'),
(40, N'Cau hoi 2 cua module 40: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-11T08:00:00+07:00'),
(40, N'Cau hoi 3 cua module 40: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-11T08:00:00+07:00'),
(41, N'Cau hoi 1 cua module 41: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-12T08:00:00+07:00'),
(41, N'Cau hoi 2 cua module 41: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-12T08:00:00+07:00'),
(41, N'Cau hoi 3 cua module 41: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-12T08:00:00+07:00'),
(42, N'Cau hoi 1 cua module 42: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-13T08:00:00+07:00'),
(42, N'Cau hoi 2 cua module 42: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-13T08:00:00+07:00'),
(42, N'Cau hoi 3 cua module 42: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-13T08:00:00+07:00'),
(43, N'Cau hoi 1 cua module 43: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-14T08:00:00+07:00'),
(43, N'Cau hoi 2 cua module 43: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-14T08:00:00+07:00'),
(43, N'Cau hoi 3 cua module 43: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-14T08:00:00+07:00'),
(44, N'Cau hoi 1 cua module 44: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-15T08:00:00+07:00'),
(44, N'Cau hoi 2 cua module 44: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-15T08:00:00+07:00'),
(44, N'Cau hoi 3 cua module 44: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-15T08:00:00+07:00'),
(45, N'Cau hoi 1 cua module 45: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-16T08:00:00+07:00'),
(45, N'Cau hoi 2 cua module 45: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-16T08:00:00+07:00'),
(45, N'Cau hoi 3 cua module 45: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-16T08:00:00+07:00'),
(46, N'Cau hoi 1 cua module 46: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-17T08:00:00+07:00'),
(46, N'Cau hoi 2 cua module 46: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-17T08:00:00+07:00'),
(46, N'Cau hoi 3 cua module 46: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-17T08:00:00+07:00'),
(47, N'Cau hoi 1 cua module 47: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'APPROVED', 8, 8, '2026-05-18T08:00:00+07:00'),
(47, N'Cau hoi 2 cua module 47: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'REJECTED', 9, NULL, '2026-05-18T08:00:00+07:00'),
(47, N'Cau hoi 3 cua module 47: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'B', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'DRAFT', 10, NULL, '2026-05-18T08:00:00+07:00'),
(48, N'Cau hoi 1 cua module 48: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'C', 'MEDIUM', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'APPROVED', 11, 11, '2026-05-19T08:00:00+07:00'),
(48, N'Cau hoi 2 cua module 48: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'D', 'HARD', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'AI_GENERATED', 'REJECTED', 12, NULL, '2026-05-19T08:00:00+07:00'),
(48, N'Cau hoi 3 cua module 48: Dau la phat bieu dung?', N'Dap an A', N'Dap an B', N'Dap an C', N'Dap an D', 'A', 'EASY', N'Giai thich AI: day la dap an dung vi phu hop voi noi dung bai giang.', 'MANUAL', 'DRAFT', 7, NULL, '2026-05-19T08:00:00+07:00');
GO

-- quiz: 36 rows
INSERT INTO quiz (course_id, created_by, name, difficulty, question_count, status, is_practice_generated, created_at) VALUES
(1, 8, N'Bai kiem tra chinh thuc - Nhap Mon HTML/CSS', 'MEDIUM', 5, 'DRAFT', 0, '2026-04-07T08:00:00+07:00'),
(2, 9, N'Bai kiem tra chinh thuc - JavaScript Co Ban', 'HARD', 5, 'PUBLISHED', 0, '2026-04-08T08:00:00+07:00'),
(3, 10, N'Bai kiem tra chinh thuc - ReactJS Tu Dau', 'EASY', 5, 'DRAFT', 0, '2026-04-09T08:00:00+07:00'),
(4, 11, N'Bai kiem tra chinh thuc - Python Cho Nguoi Moi', 'MEDIUM', 5, 'PUBLISHED', 0, '2026-04-10T08:00:00+07:00'),
(5, 12, N'Bai kiem tra chinh thuc - Phan Tich Du Lieu Voi Pandas', 'HARD', 5, 'DRAFT', 0, '2026-04-11T08:00:00+07:00'),
(6, 7, N'Bai kiem tra chinh thuc - Machine Learning Nhap Mon', 'EASY', 5, 'PUBLISHED', 0, '2026-04-12T08:00:00+07:00'),
(7, 8, N'Bai kiem tra chinh thuc - Tieng Anh Giao Tiep A1', 'MEDIUM', 5, 'DRAFT', 0, '2026-04-13T08:00:00+07:00'),
(8, 9, N'Bai kiem tra chinh thuc - Tieng Anh Giao Tiep A2', 'HARD', 5, 'PUBLISHED', 0, '2026-04-14T08:00:00+07:00'),
(9, 10, N'Bai kiem tra chinh thuc - Luyen Thi IELTS 6.5', 'EASY', 5, 'DRAFT', 0, '2026-04-15T08:00:00+07:00'),
(10, 11, N'Bai kiem tra chinh thuc - Facebook Ads Tu Xa La Den Chuyen Nghiep', 'MEDIUM', 5, 'PUBLISHED', 0, '2026-04-16T08:00:00+07:00'),
(11, 12, N'Bai kiem tra chinh thuc - SEO Website Can Ban', 'HARD', 5, 'DRAFT', 0, '2026-04-17T08:00:00+07:00'),
(12, 7, N'Bai kiem tra chinh thuc - Content Marketing', 'EASY', 5, 'PUBLISHED', 0, '2026-04-18T08:00:00+07:00'),
(13, 8, N'Bai kiem tra chinh thuc - Photoshop Can Ban', 'MEDIUM', 5, 'DRAFT', 0, '2026-04-19T08:00:00+07:00'),
(14, 9, N'Bai kiem tra chinh thuc - Illustrator Nang Cao', 'HARD', 5, 'PUBLISHED', 0, '2026-04-20T08:00:00+07:00'),
(15, 10, N'Bai kiem tra chinh thuc - Figma UI/UX', 'EASY', 5, 'DRAFT', 0, '2026-04-21T08:00:00+07:00'),
(16, 11, N'Bai kiem tra chinh thuc - Ky Nang Thuyet Trinh', 'MEDIUM', 5, 'PUBLISHED', 0, '2026-04-22T08:00:00+07:00'),
(17, 12, N'Bai kiem tra chinh thuc - Quan Ly Thoi Gian', 'HARD', 5, 'DRAFT', 0, '2026-04-23T08:00:00+07:00'),
(18, 7, N'Bai kiem tra chinh thuc - Tu Duy Phan Bien', 'EASY', 5, 'PUBLISHED', 0, '2026-04-24T08:00:00+07:00'),
(19, 8, N'Bai kiem tra chinh thuc - Giai Tich 1', 'MEDIUM', 5, 'DRAFT', 0, '2026-04-25T08:00:00+07:00'),
(20, 9, N'Bai kiem tra chinh thuc - Dai So Tuyen Tinh', 'HARD', 5, 'PUBLISHED', 0, '2026-04-26T08:00:00+07:00'),
(21, 10, N'Bai kiem tra chinh thuc - Xac Suat Thong Ke', 'EASY', 5, 'DRAFT', 0, '2026-04-27T08:00:00+07:00'),
(22, 11, N'Bai kiem tra chinh thuc - Dau Tu Chung Khoan Co Ban', 'MEDIUM', 5, 'PUBLISHED', 0, '2026-04-28T08:00:00+07:00'),
(23, 12, N'Bai kiem tra chinh thuc - Quan Ly Tai Chinh Ca Nhan', 'HARD', 5, 'DRAFT', 0, '2026-04-29T08:00:00+07:00'),
(24, 7, N'Bai kiem tra chinh thuc - Bao Mat Ung Dung Web', 'EASY', 5, 'PUBLISHED', 0, '2026-04-30T08:00:00+07:00'),
(13, 25, N'Quiz tu luyen tap #1', 'EASY', 5, 'PUBLISHED', 1, '2026-04-21T08:00:00+07:00'),
(14, 26, N'Quiz tu luyen tap #2', 'MEDIUM', 5, 'PUBLISHED', 1, '2026-04-22T08:00:00+07:00'),
(15, 27, N'Quiz tu luyen tap #3', 'HARD', 5, 'PUBLISHED', 1, '2026-04-23T08:00:00+07:00'),
(16, 28, N'Quiz tu luyen tap #4', 'EASY', 5, 'PUBLISHED', 1, '2026-04-24T08:00:00+07:00'),
(17, 29, N'Quiz tu luyen tap #5', 'MEDIUM', 5, 'PUBLISHED', 1, '2026-04-25T08:00:00+07:00'),
(18, 30, N'Quiz tu luyen tap #6', 'HARD', 5, 'PUBLISHED', 1, '2026-04-26T08:00:00+07:00'),
(13, 31, N'Quiz tu luyen tap #7', 'EASY', 5, 'PUBLISHED', 1, '2026-04-27T08:00:00+07:00'),
(14, 32, N'Quiz tu luyen tap #8', 'MEDIUM', 5, 'PUBLISHED', 1, '2026-04-28T08:00:00+07:00'),
(15, 33, N'Quiz tu luyen tap #9', 'HARD', 5, 'PUBLISHED', 1, '2026-04-29T08:00:00+07:00'),
(16, 34, N'Quiz tu luyen tap #10', 'EASY', 5, 'PUBLISHED', 1, '2026-04-30T08:00:00+07:00'),
(17, 35, N'Quiz tu luyen tap #11', 'MEDIUM', 5, 'PUBLISHED', 1, '2026-05-01T08:00:00+07:00'),
(18, 36, N'Quiz tu luyen tap #12', 'HARD', 5, 'PUBLISHED', 1, '2026-05-02T08:00:00+07:00');
GO

-- quiz_question: 180 rows
INSERT INTO quiz_question (quiz_id, question_id, order_no) VALUES
(1, 1, 1),
(1, 2, 2),
(1, 3, 3),
(1, 4, 4),
(1, 5, 5),
(2, 7, 1),
(2, 8, 2),
(2, 9, 3),
(2, 10, 4),
(2, 11, 5),
(3, 13, 1),
(3, 14, 2),
(3, 15, 3),
(3, 16, 4),
(3, 17, 5),
(4, 19, 1),
(4, 20, 2),
(4, 21, 3),
(4, 22, 4),
(4, 23, 5),
(5, 25, 1),
(5, 26, 2),
(5, 27, 3),
(5, 28, 4),
(5, 29, 5),
(6, 31, 1),
(6, 32, 2),
(6, 33, 3),
(6, 34, 4),
(6, 35, 5),
(7, 37, 1),
(7, 38, 2),
(7, 39, 3),
(7, 40, 4),
(7, 41, 5),
(8, 43, 1),
(8, 44, 2),
(8, 45, 3),
(8, 46, 4),
(8, 47, 5),
(9, 49, 1),
(9, 50, 2),
(9, 51, 3),
(9, 52, 4),
(9, 53, 5),
(10, 55, 1),
(10, 56, 2),
(10, 57, 3),
(10, 58, 4),
(10, 59, 5);
INSERT INTO quiz_question (quiz_id, question_id, order_no) VALUES
(11, 61, 1),
(11, 62, 2),
(11, 63, 3),
(11, 64, 4),
(11, 65, 5),
(12, 67, 1),
(12, 68, 2),
(12, 69, 3),
(12, 70, 4),
(12, 71, 5),
(13, 73, 1),
(13, 74, 2),
(13, 75, 3),
(13, 76, 4),
(13, 77, 5),
(14, 79, 1),
(14, 80, 2),
(14, 81, 3),
(14, 82, 4),
(14, 83, 5),
(15, 85, 1),
(15, 86, 2),
(15, 87, 3),
(15, 88, 4),
(15, 89, 5),
(16, 91, 1),
(16, 92, 2),
(16, 93, 3),
(16, 94, 4),
(16, 95, 5),
(17, 97, 1),
(17, 98, 2),
(17, 99, 3),
(17, 100, 4),
(17, 101, 5),
(18, 103, 1),
(18, 104, 2),
(18, 105, 3),
(18, 106, 4),
(18, 107, 5),
(19, 109, 1),
(19, 110, 2),
(19, 111, 3),
(19, 112, 4),
(19, 113, 5),
(20, 115, 1),
(20, 116, 2),
(20, 117, 3),
(20, 118, 4),
(20, 119, 5);
INSERT INTO quiz_question (quiz_id, question_id, order_no) VALUES
(21, 121, 1),
(21, 122, 2),
(21, 123, 3),
(21, 124, 4),
(21, 125, 5),
(22, 127, 1),
(22, 128, 2),
(22, 129, 3),
(22, 130, 4),
(22, 131, 5),
(23, 133, 1),
(23, 134, 2),
(23, 135, 3),
(23, 136, 4),
(23, 137, 5),
(24, 139, 1),
(24, 140, 2),
(24, 141, 3),
(24, 142, 4),
(24, 143, 5),
(25, 73, 1),
(25, 74, 2),
(25, 75, 3),
(25, 76, 4),
(25, 77, 5),
(26, 79, 1),
(26, 80, 2),
(26, 81, 3),
(26, 82, 4),
(26, 83, 5),
(27, 85, 1),
(27, 86, 2),
(27, 87, 3),
(27, 88, 4),
(27, 89, 5),
(28, 91, 1),
(28, 92, 2),
(28, 93, 3),
(28, 94, 4),
(28, 95, 5),
(29, 97, 1),
(29, 98, 2),
(29, 99, 3),
(29, 100, 4),
(29, 101, 5),
(30, 103, 1),
(30, 104, 2),
(30, 105, 3),
(30, 106, 4),
(30, 107, 5);
INSERT INTO quiz_question (quiz_id, question_id, order_no) VALUES
(31, 73, 1),
(31, 74, 2),
(31, 75, 3),
(31, 76, 4),
(31, 77, 5),
(32, 79, 1),
(32, 80, 2),
(32, 81, 3),
(32, 82, 4),
(32, 83, 5),
(33, 85, 1),
(33, 86, 2),
(33, 87, 3),
(33, 88, 4),
(33, 89, 5),
(34, 91, 1),
(34, 92, 2),
(34, 93, 3),
(34, 94, 4),
(34, 95, 5),
(35, 97, 1),
(35, 98, 2),
(35, 99, 3),
(35, 100, 4),
(35, 101, 5),
(36, 103, 1),
(36, 104, 2),
(36, 105, 3),
(36, 106, 4),
(36, 107, 5);
GO

-- flashcard_deck: 16 rows
INSERT INTO flashcard_deck (course_id, module_id, name, category, status, created_by, created_at) VALUES
(1, 1, N'Bo the ghi nho #1 - Nhap Mon HTML/CSS', N'Tu Vung', 'DRAFT', 7, '2026-04-03T08:00:00+07:00'),
(2, NULL, N'Bo the ghi nho #2 - JavaScript Co Ban', N'Cong Thuc', 'DRAFT', 8, '2026-04-04T08:00:00+07:00'),
(3, 5, N'Bo the ghi nho #3 - ReactJS Tu Dau', N'Khai Niem', 'DRAFT', 9, '2026-04-05T08:00:00+07:00'),
(4, NULL, N'Bo the ghi nho #4 - Python Cho Nguoi Moi', N'Thuat Ngu', 'DRAFT', 10, '2026-04-06T08:00:00+07:00'),
(5, 9, N'Bo the ghi nho #5 - Phan Tich Du Lieu Voi Pandas', N'Tu Vung', 'DRAFT', 11, '2026-04-07T08:00:00+07:00'),
(6, NULL, N'Bo the ghi nho #6 - Machine Learning Nhap Mon', N'Cong Thuc', 'DRAFT', 12, '2026-04-08T08:00:00+07:00'),
(7, 13, N'Bo the ghi nho #7 - Tieng Anh Giao Tiep A1', N'Khai Niem', 'DRAFT', 7, '2026-04-09T08:00:00+07:00'),
(8, NULL, N'Bo the ghi nho #8 - Tieng Anh Giao Tiep A2', N'Thuat Ngu', 'DRAFT', 8, '2026-04-10T08:00:00+07:00'),
(9, 17, N'Bo the ghi nho #9 - Luyen Thi IELTS 6.5', N'Tu Vung', 'PUBLISHED', 9, '2026-04-11T08:00:00+07:00'),
(10, NULL, N'Bo the ghi nho #10 - Facebook Ads Tu Xa La Den Chuyen Nghiep', N'Cong Thuc', 'PUBLISHED', 10, '2026-04-12T08:00:00+07:00'),
(11, 21, N'Bo the ghi nho #11 - SEO Website Can Ban', N'Khai Niem', 'PUBLISHED', 11, '2026-04-13T08:00:00+07:00'),
(12, NULL, N'Bo the ghi nho #12 - Content Marketing', N'Thuat Ngu', 'PUBLISHED', 12, '2026-04-14T08:00:00+07:00'),
(13, 25, N'Bo the ghi nho #13 - Photoshop Can Ban', N'Tu Vung', 'PUBLISHED', 7, '2026-04-15T08:00:00+07:00'),
(14, NULL, N'Bo the ghi nho #14 - Illustrator Nang Cao', N'Cong Thuc', 'PUBLISHED', 8, '2026-04-16T08:00:00+07:00'),
(15, 29, N'Bo the ghi nho #15 - Figma UI/UX', N'Khai Niem', 'PUBLISHED', 9, '2026-04-17T08:00:00+07:00'),
(16, NULL, N'Bo the ghi nho #16 - Ky Nang Thuyet Trinh', N'Thuat Ngu', 'PUBLISHED', 10, '2026-04-18T08:00:00+07:00');
GO

-- flashcard: 96 rows
INSERT INTO flashcard (deck_id, front_text, back_text, status, created_at) VALUES
(1, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 1.', 'ACTIVE', '2026-04-07T08:00:00+07:00'),
(1, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 1.', 'ACTIVE', '2026-04-07T08:00:00+07:00'),
(1, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 1.', 'ACTIVE', '2026-04-07T08:00:00+07:00'),
(1, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 1.', 'ACTIVE', '2026-04-07T08:00:00+07:00'),
(1, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 1.', 'ACTIVE', '2026-04-07T08:00:00+07:00'),
(1, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 1.', 'ACTIVE', '2026-04-07T08:00:00+07:00'),
(2, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 2.', 'ACTIVE', '2026-04-08T08:00:00+07:00'),
(2, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 2.', 'ACTIVE', '2026-04-08T08:00:00+07:00'),
(2, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 2.', 'ACTIVE', '2026-04-08T08:00:00+07:00'),
(2, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 2.', 'ACTIVE', '2026-04-08T08:00:00+07:00'),
(2, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 2.', 'ACTIVE', '2026-04-08T08:00:00+07:00'),
(2, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 2.', 'ACTIVE', '2026-04-08T08:00:00+07:00'),
(3, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 3.', 'ACTIVE', '2026-04-09T08:00:00+07:00'),
(3, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 3.', 'ACTIVE', '2026-04-09T08:00:00+07:00'),
(3, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 3.', 'ACTIVE', '2026-04-09T08:00:00+07:00'),
(3, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 3.', 'ACTIVE', '2026-04-09T08:00:00+07:00'),
(3, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 3.', 'ACTIVE', '2026-04-09T08:00:00+07:00'),
(3, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 3.', 'ACTIVE', '2026-04-09T08:00:00+07:00'),
(4, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 4.', 'ACTIVE', '2026-04-10T08:00:00+07:00'),
(4, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 4.', 'ACTIVE', '2026-04-10T08:00:00+07:00'),
(4, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 4.', 'ACTIVE', '2026-04-10T08:00:00+07:00'),
(4, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 4.', 'ACTIVE', '2026-04-10T08:00:00+07:00'),
(4, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 4.', 'ACTIVE', '2026-04-10T08:00:00+07:00'),
(4, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 4.', 'ACTIVE', '2026-04-10T08:00:00+07:00'),
(5, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 5.', 'ACTIVE', '2026-04-11T08:00:00+07:00'),
(5, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 5.', 'ACTIVE', '2026-04-11T08:00:00+07:00'),
(5, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 5.', 'ACTIVE', '2026-04-11T08:00:00+07:00'),
(5, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 5.', 'ACTIVE', '2026-04-11T08:00:00+07:00'),
(5, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 5.', 'ACTIVE', '2026-04-11T08:00:00+07:00'),
(5, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 5.', 'ACTIVE', '2026-04-11T08:00:00+07:00'),
(6, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 6.', 'ACTIVE', '2026-04-12T08:00:00+07:00'),
(6, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 6.', 'ACTIVE', '2026-04-12T08:00:00+07:00'),
(6, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 6.', 'ACTIVE', '2026-04-12T08:00:00+07:00'),
(6, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 6.', 'ACTIVE', '2026-04-12T08:00:00+07:00'),
(6, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 6.', 'ACTIVE', '2026-04-12T08:00:00+07:00'),
(6, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 6.', 'ACTIVE', '2026-04-12T08:00:00+07:00'),
(7, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 7.', 'ACTIVE', '2026-04-13T08:00:00+07:00'),
(7, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 7.', 'ACTIVE', '2026-04-13T08:00:00+07:00'),
(7, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 7.', 'ACTIVE', '2026-04-13T08:00:00+07:00'),
(7, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 7.', 'ACTIVE', '2026-04-13T08:00:00+07:00'),
(7, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 7.', 'ACTIVE', '2026-04-13T08:00:00+07:00'),
(7, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 7.', 'ACTIVE', '2026-04-13T08:00:00+07:00'),
(8, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 8.', 'ACTIVE', '2026-04-14T08:00:00+07:00'),
(8, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 8.', 'ACTIVE', '2026-04-14T08:00:00+07:00'),
(8, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 8.', 'ACTIVE', '2026-04-14T08:00:00+07:00'),
(8, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 8.', 'ACTIVE', '2026-04-14T08:00:00+07:00'),
(8, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 8.', 'ACTIVE', '2026-04-14T08:00:00+07:00'),
(8, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 8.', 'ACTIVE', '2026-04-14T08:00:00+07:00'),
(9, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 9.', 'ACTIVE', '2026-04-15T08:00:00+07:00'),
(9, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 9.', 'ACTIVE', '2026-04-15T08:00:00+07:00');
INSERT INTO flashcard (deck_id, front_text, back_text, status, created_at) VALUES
(9, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 9.', 'ACTIVE', '2026-04-15T08:00:00+07:00'),
(9, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 9.', 'ACTIVE', '2026-04-15T08:00:00+07:00'),
(9, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 9.', 'ACTIVE', '2026-04-15T08:00:00+07:00'),
(9, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 9.', 'ACTIVE', '2026-04-15T08:00:00+07:00'),
(10, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 10.', 'ACTIVE', '2026-04-16T08:00:00+07:00'),
(10, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 10.', 'ACTIVE', '2026-04-16T08:00:00+07:00'),
(10, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 10.', 'ACTIVE', '2026-04-16T08:00:00+07:00'),
(10, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 10.', 'ACTIVE', '2026-04-16T08:00:00+07:00'),
(10, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 10.', 'ACTIVE', '2026-04-16T08:00:00+07:00'),
(10, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 10.', 'ACTIVE', '2026-04-16T08:00:00+07:00'),
(11, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 11.', 'ACTIVE', '2026-04-17T08:00:00+07:00'),
(11, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 11.', 'ACTIVE', '2026-04-17T08:00:00+07:00'),
(11, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 11.', 'ACTIVE', '2026-04-17T08:00:00+07:00'),
(11, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 11.', 'ACTIVE', '2026-04-17T08:00:00+07:00'),
(11, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 11.', 'ACTIVE', '2026-04-17T08:00:00+07:00'),
(11, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 11.', 'ACTIVE', '2026-04-17T08:00:00+07:00'),
(12, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 12.', 'ACTIVE', '2026-04-18T08:00:00+07:00'),
(12, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 12.', 'ACTIVE', '2026-04-18T08:00:00+07:00'),
(12, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 12.', 'ACTIVE', '2026-04-18T08:00:00+07:00'),
(12, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 12.', 'ACTIVE', '2026-04-18T08:00:00+07:00'),
(12, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 12.', 'ACTIVE', '2026-04-18T08:00:00+07:00'),
(12, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 12.', 'ACTIVE', '2026-04-18T08:00:00+07:00'),
(13, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 13.', 'ACTIVE', '2026-04-19T08:00:00+07:00'),
(13, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 13.', 'ACTIVE', '2026-04-19T08:00:00+07:00'),
(13, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 13.', 'ACTIVE', '2026-04-19T08:00:00+07:00'),
(13, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 13.', 'ACTIVE', '2026-04-19T08:00:00+07:00'),
(13, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 13.', 'ACTIVE', '2026-04-19T08:00:00+07:00'),
(13, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 13.', 'ACTIVE', '2026-04-19T08:00:00+07:00'),
(14, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 14.', 'ACTIVE', '2026-04-20T08:00:00+07:00'),
(14, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 14.', 'ACTIVE', '2026-04-20T08:00:00+07:00'),
(14, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 14.', 'ACTIVE', '2026-04-20T08:00:00+07:00'),
(14, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 14.', 'ACTIVE', '2026-04-20T08:00:00+07:00'),
(14, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 14.', 'ACTIVE', '2026-04-20T08:00:00+07:00'),
(14, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 14.', 'ACTIVE', '2026-04-20T08:00:00+07:00'),
(15, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 15.', 'ACTIVE', '2026-04-21T08:00:00+07:00'),
(15, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 15.', 'ACTIVE', '2026-04-21T08:00:00+07:00'),
(15, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 15.', 'ACTIVE', '2026-04-21T08:00:00+07:00'),
(15, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 15.', 'ACTIVE', '2026-04-21T08:00:00+07:00'),
(15, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 15.', 'ACTIVE', '2026-04-21T08:00:00+07:00'),
(15, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 15.', 'ACTIVE', '2026-04-21T08:00:00+07:00'),
(16, N'Thuat ngu 1', N'Dinh nghia chi tiet cho thuat ngu 1 cua bo the 16.', 'ACTIVE', '2026-04-22T08:00:00+07:00'),
(16, N'Thuat ngu 2', N'Dinh nghia chi tiet cho thuat ngu 2 cua bo the 16.', 'ACTIVE', '2026-04-22T08:00:00+07:00'),
(16, N'Thuat ngu 3', N'Dinh nghia chi tiet cho thuat ngu 3 cua bo the 16.', 'ACTIVE', '2026-04-22T08:00:00+07:00'),
(16, N'Thuat ngu 4', N'Dinh nghia chi tiet cho thuat ngu 4 cua bo the 16.', 'ACTIVE', '2026-04-22T08:00:00+07:00'),
(16, N'Thuat ngu 5', N'Dinh nghia chi tiet cho thuat ngu 5 cua bo the 16.', 'ACTIVE', '2026-04-22T08:00:00+07:00'),
(16, N'Thuat ngu 6', N'Dinh nghia chi tiet cho thuat ngu 6 cua bo the 16.', 'ACTIVE', '2026-04-22T08:00:00+07:00');
GO

-- flashcard_review_log: 200 rows
INSERT INTO flashcard_review_log (flashcard_id, student_id, memory_state, reviewed_at, next_review_at) VALUES
(1, 25, 'FORGOT', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(2, 26, 'REMEMBERED', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(3, 27, 'MASTERED', '2026-04-18T08:00:00+07:00', NULL),
(4, 28, 'FORGOT', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(5, 29, 'REMEMBERED', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(6, 30, 'MASTERED', '2026-04-21T08:00:00+07:00', NULL),
(7, 31, 'FORGOT', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(8, 32, 'REMEMBERED', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(9, 33, 'MASTERED', '2026-04-24T08:00:00+07:00', NULL),
(10, 34, 'FORGOT', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(11, 35, 'REMEMBERED', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(12, 36, 'MASTERED', '2026-04-27T08:00:00+07:00', NULL),
(13, 37, 'FORGOT', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(14, 38, 'REMEMBERED', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(15, 39, 'MASTERED', '2026-04-30T08:00:00+07:00', NULL),
(16, 40, 'FORGOT', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(17, 41, 'REMEMBERED', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(18, 42, 'MASTERED', '2026-05-03T08:00:00+07:00', NULL),
(19, 43, 'FORGOT', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(20, 44, 'REMEMBERED', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(21, 45, 'MASTERED', '2026-04-16T08:00:00+07:00', NULL),
(22, 46, 'FORGOT', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(23, 47, 'REMEMBERED', '2026-04-18T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(24, 48, 'MASTERED', '2026-04-19T08:00:00+07:00', NULL),
(25, 49, 'FORGOT', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(26, 50, 'REMEMBERED', '2026-04-21T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(27, 51, 'MASTERED', '2026-04-22T08:00:00+07:00', NULL),
(28, 52, 'FORGOT', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(29, 53, 'REMEMBERED', '2026-04-24T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(30, 54, 'MASTERED', '2026-04-25T08:00:00+07:00', NULL),
(31, 25, 'FORGOT', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(32, 26, 'REMEMBERED', '2026-04-27T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(33, 27, 'MASTERED', '2026-04-28T08:00:00+07:00', NULL),
(34, 28, 'FORGOT', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(35, 29, 'REMEMBERED', '2026-04-30T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(36, 30, 'MASTERED', '2026-05-01T08:00:00+07:00', NULL),
(37, 31, 'FORGOT', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(38, 32, 'REMEMBERED', '2026-05-03T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(39, 33, 'MASTERED', '2026-05-04T08:00:00+07:00', NULL),
(40, 34, 'FORGOT', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(41, 35, 'REMEMBERED', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(42, 36, 'MASTERED', '2026-04-17T08:00:00+07:00', NULL),
(43, 37, 'FORGOT', '2026-04-18T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(44, 38, 'REMEMBERED', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(45, 39, 'MASTERED', '2026-04-20T08:00:00+07:00', NULL),
(46, 40, 'FORGOT', '2026-04-21T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(47, 41, 'REMEMBERED', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(48, 42, 'MASTERED', '2026-04-23T08:00:00+07:00', NULL),
(49, 43, 'FORGOT', '2026-04-24T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(50, 44, 'REMEMBERED', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00');
INSERT INTO flashcard_review_log (flashcard_id, student_id, memory_state, reviewed_at, next_review_at) VALUES
(51, 45, 'MASTERED', '2026-04-26T08:00:00+07:00', NULL),
(52, 46, 'FORGOT', '2026-04-27T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(53, 47, 'REMEMBERED', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(54, 48, 'MASTERED', '2026-04-29T08:00:00+07:00', NULL),
(55, 49, 'FORGOT', '2026-04-30T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(56, 50, 'REMEMBERED', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(57, 51, 'MASTERED', '2026-05-02T08:00:00+07:00', NULL),
(58, 52, 'FORGOT', '2026-05-03T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(59, 53, 'REMEMBERED', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(60, 54, 'MASTERED', '2026-05-05T08:00:00+07:00', NULL),
(61, 25, 'FORGOT', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(62, 26, 'REMEMBERED', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(63, 27, 'MASTERED', '2026-04-18T08:00:00+07:00', NULL),
(64, 28, 'FORGOT', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(65, 29, 'REMEMBERED', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(66, 30, 'MASTERED', '2026-04-21T08:00:00+07:00', NULL),
(67, 31, 'FORGOT', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(68, 32, 'REMEMBERED', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(69, 33, 'MASTERED', '2026-04-24T08:00:00+07:00', NULL),
(70, 34, 'FORGOT', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(71, 35, 'REMEMBERED', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(72, 36, 'MASTERED', '2026-04-27T08:00:00+07:00', NULL),
(73, 37, 'FORGOT', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(74, 38, 'REMEMBERED', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(75, 39, 'MASTERED', '2026-04-30T08:00:00+07:00', NULL),
(76, 40, 'FORGOT', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(77, 41, 'REMEMBERED', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(78, 42, 'MASTERED', '2026-05-03T08:00:00+07:00', NULL),
(79, 43, 'FORGOT', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(80, 44, 'REMEMBERED', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(81, 45, 'MASTERED', '2026-04-16T08:00:00+07:00', NULL),
(82, 46, 'FORGOT', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(83, 47, 'REMEMBERED', '2026-04-18T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(84, 48, 'MASTERED', '2026-04-19T08:00:00+07:00', NULL),
(85, 49, 'FORGOT', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(86, 50, 'REMEMBERED', '2026-04-21T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(87, 51, 'MASTERED', '2026-04-22T08:00:00+07:00', NULL),
(88, 52, 'FORGOT', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(89, 53, 'REMEMBERED', '2026-04-24T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(90, 54, 'MASTERED', '2026-04-25T08:00:00+07:00', NULL),
(91, 25, 'FORGOT', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(92, 26, 'REMEMBERED', '2026-04-27T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(93, 27, 'MASTERED', '2026-04-28T08:00:00+07:00', NULL),
(94, 28, 'FORGOT', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(95, 29, 'REMEMBERED', '2026-04-30T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(96, 30, 'MASTERED', '2026-05-01T08:00:00+07:00', NULL),
(1, 31, 'FORGOT', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(2, 32, 'REMEMBERED', '2026-05-03T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(3, 33, 'MASTERED', '2026-05-04T08:00:00+07:00', NULL),
(4, 34, 'FORGOT', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00');
INSERT INTO flashcard_review_log (flashcard_id, student_id, memory_state, reviewed_at, next_review_at) VALUES
(5, 35, 'REMEMBERED', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(6, 36, 'MASTERED', '2026-04-17T08:00:00+07:00', NULL),
(7, 37, 'FORGOT', '2026-04-18T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(8, 38, 'REMEMBERED', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(9, 39, 'MASTERED', '2026-04-20T08:00:00+07:00', NULL),
(10, 40, 'FORGOT', '2026-04-21T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(11, 41, 'REMEMBERED', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(12, 42, 'MASTERED', '2026-04-23T08:00:00+07:00', NULL),
(13, 43, 'FORGOT', '2026-04-24T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(14, 44, 'REMEMBERED', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(15, 45, 'MASTERED', '2026-04-26T08:00:00+07:00', NULL),
(16, 46, 'FORGOT', '2026-04-27T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(17, 47, 'REMEMBERED', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(18, 48, 'MASTERED', '2026-04-29T08:00:00+07:00', NULL),
(19, 49, 'FORGOT', '2026-04-30T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(20, 50, 'REMEMBERED', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(21, 51, 'MASTERED', '2026-05-02T08:00:00+07:00', NULL),
(22, 52, 'FORGOT', '2026-05-03T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(23, 53, 'REMEMBERED', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(24, 54, 'MASTERED', '2026-05-05T08:00:00+07:00', NULL),
(25, 25, 'FORGOT', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(26, 26, 'REMEMBERED', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(27, 27, 'MASTERED', '2026-04-18T08:00:00+07:00', NULL),
(28, 28, 'FORGOT', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(29, 29, 'REMEMBERED', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(30, 30, 'MASTERED', '2026-04-21T08:00:00+07:00', NULL),
(31, 31, 'FORGOT', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(32, 32, 'REMEMBERED', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(33, 33, 'MASTERED', '2026-04-24T08:00:00+07:00', NULL),
(34, 34, 'FORGOT', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(35, 35, 'REMEMBERED', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(36, 36, 'MASTERED', '2026-04-27T08:00:00+07:00', NULL),
(37, 37, 'FORGOT', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(38, 38, 'REMEMBERED', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(39, 39, 'MASTERED', '2026-04-30T08:00:00+07:00', NULL),
(40, 40, 'FORGOT', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(41, 41, 'REMEMBERED', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(42, 42, 'MASTERED', '2026-05-03T08:00:00+07:00', NULL),
(43, 43, 'FORGOT', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(44, 44, 'REMEMBERED', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(45, 45, 'MASTERED', '2026-04-16T08:00:00+07:00', NULL),
(46, 46, 'FORGOT', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(47, 47, 'REMEMBERED', '2026-04-18T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(48, 48, 'MASTERED', '2026-04-19T08:00:00+07:00', NULL),
(49, 49, 'FORGOT', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(50, 50, 'REMEMBERED', '2026-04-21T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(51, 51, 'MASTERED', '2026-04-22T08:00:00+07:00', NULL),
(52, 52, 'FORGOT', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(53, 53, 'REMEMBERED', '2026-04-24T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(54, 54, 'MASTERED', '2026-04-25T08:00:00+07:00', NULL);
INSERT INTO flashcard_review_log (flashcard_id, student_id, memory_state, reviewed_at, next_review_at) VALUES
(55, 25, 'FORGOT', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(56, 26, 'REMEMBERED', '2026-04-27T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(57, 27, 'MASTERED', '2026-04-28T08:00:00+07:00', NULL),
(58, 28, 'FORGOT', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(59, 29, 'REMEMBERED', '2026-04-30T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(60, 30, 'MASTERED', '2026-05-01T08:00:00+07:00', NULL),
(61, 31, 'FORGOT', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(62, 32, 'REMEMBERED', '2026-05-03T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(63, 33, 'MASTERED', '2026-05-04T08:00:00+07:00', NULL),
(64, 34, 'FORGOT', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(65, 35, 'REMEMBERED', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(66, 36, 'MASTERED', '2026-04-17T08:00:00+07:00', NULL),
(67, 37, 'FORGOT', '2026-04-18T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(68, 38, 'REMEMBERED', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(69, 39, 'MASTERED', '2026-04-20T08:00:00+07:00', NULL),
(70, 40, 'FORGOT', '2026-04-21T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(71, 41, 'REMEMBERED', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(72, 42, 'MASTERED', '2026-04-23T08:00:00+07:00', NULL),
(73, 43, 'FORGOT', '2026-04-24T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(74, 44, 'REMEMBERED', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(75, 45, 'MASTERED', '2026-04-26T08:00:00+07:00', NULL),
(76, 46, 'FORGOT', '2026-04-27T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(77, 47, 'REMEMBERED', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(78, 48, 'MASTERED', '2026-04-29T08:00:00+07:00', NULL),
(79, 49, 'FORGOT', '2026-04-30T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(80, 50, 'REMEMBERED', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(81, 51, 'MASTERED', '2026-05-02T08:00:00+07:00', NULL),
(82, 52, 'FORGOT', '2026-05-03T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(83, 53, 'REMEMBERED', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(84, 54, 'MASTERED', '2026-05-05T08:00:00+07:00', NULL),
(85, 25, 'FORGOT', '2026-04-16T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(86, 26, 'REMEMBERED', '2026-04-17T08:00:00+07:00', '2026-05-05T08:00:00+07:00'),
(87, 27, 'MASTERED', '2026-04-18T08:00:00+07:00', NULL),
(88, 28, 'FORGOT', '2026-04-19T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(89, 29, 'REMEMBERED', '2026-04-20T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(90, 30, 'MASTERED', '2026-04-21T08:00:00+07:00', NULL),
(91, 31, 'FORGOT', '2026-04-22T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(92, 32, 'REMEMBERED', '2026-04-23T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(93, 33, 'MASTERED', '2026-04-24T08:00:00+07:00', NULL),
(94, 34, 'FORGOT', '2026-04-25T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(95, 35, 'REMEMBERED', '2026-04-26T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(96, 36, 'MASTERED', '2026-04-27T08:00:00+07:00', NULL),
(1, 37, 'FORGOT', '2026-04-28T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(2, 38, 'REMEMBERED', '2026-04-29T08:00:00+07:00', '2026-05-07T08:00:00+07:00'),
(3, 39, 'MASTERED', '2026-04-30T08:00:00+07:00', NULL),
(4, 40, 'FORGOT', '2026-05-01T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(5, 41, 'REMEMBERED', '2026-05-02T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(6, 42, 'MASTERED', '2026-05-03T08:00:00+07:00', NULL),
(7, 43, 'FORGOT', '2026-05-04T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(8, 44, 'REMEMBERED', '2026-05-05T08:00:00+07:00', '2026-05-13T08:00:00+07:00');
GO

-- class: 30 rows
INSERT INTO class (course_id, teacher_id, name, start_date, end_date, capacity, price, status, created_by, created_at) VALUES
(13, 19, N'Lop Photoshop Can Ban - Khoa 01', '2026-03-02', '2026-05-01', 20, 0, 'PLANNED', 1, '2026-03-02T08:00:00+07:00'),
(14, 20, N'Lop Illustrator Nang Cao - Khoa 02', '2026-03-05', '2026-05-04', 21, 520000, 'PLANNED', 2, '2026-03-05T08:00:00+07:00'),
(15, 21, N'Lop Figma UI/UX - Khoa 03', '2026-03-08', '2026-05-07', 22, 540000, 'PLANNED', 3, '2026-03-08T08:00:00+07:00'),
(16, 22, N'Lop Ky Nang Thuyet Trinh - Khoa 04', '2026-03-11', '2026-05-10', 23, 560000, 'PLANNED', 4, '2026-03-11T08:00:00+07:00'),
(17, 23, N'Lop Quan Ly Thoi Gian - Khoa 05', '2026-03-14', '2026-05-13', 24, 580000, 'PLANNED', 5, '2026-03-14T08:00:00+07:00'),
(18, 24, N'Lop Tu Duy Phan Bien - Khoa 06', '2026-03-17', '2026-05-16', 25, 600000, 'PLANNED', 6, '2026-03-17T08:00:00+07:00'),
(13, 19, N'Lop Photoshop Can Ban - Khoa 07', '2026-03-20', '2026-05-19', 26, 0, 'ACTIVE', 13, '2026-03-20T08:00:00+07:00'),
(14, 20, N'Lop Illustrator Nang Cao - Khoa 08', '2026-03-23', '2026-05-22', 27, 640000, 'ACTIVE', 14, '2026-03-23T08:00:00+07:00'),
(15, 21, N'Lop Figma UI/UX - Khoa 09', '2026-03-26', '2026-05-25', 28, 660000, 'ACTIVE', 15, '2026-03-26T08:00:00+07:00'),
(16, 22, N'Lop Ky Nang Thuyet Trinh - Khoa 10', '2026-03-29', '2026-05-28', 29, 680000, 'ACTIVE', 16, '2026-03-29T08:00:00+07:00'),
(17, 23, N'Lop Quan Ly Thoi Gian - Khoa 11', '2026-04-01', '2026-05-31', 30, 700000, 'ACTIVE', 17, '2026-04-01T08:00:00+07:00'),
(18, 24, N'Lop Tu Duy Phan Bien - Khoa 12', '2026-04-04', '2026-06-03', 31, 720000, 'ACTIVE', 18, '2026-04-04T08:00:00+07:00'),
(13, 19, N'Lop Photoshop Can Ban - Khoa 13', '2026-04-07', '2026-06-06', 32, 0, 'COMPLETED', 1, '2026-04-07T08:00:00+07:00'),
(14, 20, N'Lop Illustrator Nang Cao - Khoa 14', '2026-04-10', '2026-06-09', 33, 760000, 'COMPLETED', 2, '2026-04-10T08:00:00+07:00'),
(15, 21, N'Lop Figma UI/UX - Khoa 15', '2026-04-13', '2026-06-12', 34, 780000, 'COMPLETED', 3, '2026-04-13T08:00:00+07:00'),
(16, 22, N'Lop Ky Nang Thuyet Trinh - Khoa 16', '2026-04-16', '2026-06-15', 35, 800000, 'COMPLETED', 4, '2026-04-16T08:00:00+07:00'),
(17, 23, N'Lop Quan Ly Thoi Gian - Khoa 17', '2026-04-19', '2026-06-18', 36, 820000, 'COMPLETED', 5, '2026-04-19T08:00:00+07:00'),
(18, 24, N'Lop Tu Duy Phan Bien - Khoa 18', '2026-04-22', '2026-06-21', 37, 840000, 'COMPLETED', 6, '2026-04-22T08:00:00+07:00'),
(13, 19, N'Lop Photoshop Can Ban - Khoa 19', '2026-04-25', '2026-06-24', 38, 0, 'EXPIRED', 13, '2026-04-25T08:00:00+07:00'),
(14, 20, N'Lop Illustrator Nang Cao - Khoa 20', '2026-04-28', '2026-06-27', 39, 880000, 'EXPIRED', 14, '2026-04-28T08:00:00+07:00'),
(15, 21, N'Lop Figma UI/UX - Khoa 21', '2026-05-01', '2026-06-30', 40, 900000, 'EXPIRED', 15, '2026-05-01T08:00:00+07:00'),
(16, 22, N'Lop Ky Nang Thuyet Trinh - Khoa 22', '2026-05-04', '2026-07-03', 41, 920000, 'EXPIRED', 16, '2026-05-04T08:00:00+07:00'),
(17, 23, N'Lop Quan Ly Thoi Gian - Khoa 23', '2026-05-07', '2026-07-06', 42, 940000, 'EXPIRED', 17, '2026-05-07T08:00:00+07:00'),
(18, 24, N'Lop Tu Duy Phan Bien - Khoa 24', '2026-05-10', '2026-07-09', 43, 960000, 'EXPIRED', 18, '2026-05-10T08:00:00+07:00'),
(13, 19, N'Lop Photoshop Can Ban - Khoa 25', '2026-05-13', '2026-07-12', 44, 0, 'CLOSED', 1, '2026-05-13T08:00:00+07:00'),
(14, 20, N'Lop Illustrator Nang Cao - Khoa 26', '2026-05-16', '2026-07-15', 45, 1000000, 'CLOSED', 2, '2026-05-16T08:00:00+07:00'),
(15, 21, N'Lop Figma UI/UX - Khoa 27', '2026-05-19', '2026-07-18', 46, 1020000, 'CLOSED', 3, '2026-05-19T08:00:00+07:00'),
(16, 22, N'Lop Ky Nang Thuyet Trinh - Khoa 28', '2026-05-22', '2026-07-21', 47, 1040000, 'CLOSED', 4, '2026-05-22T08:00:00+07:00'),
(17, 23, N'Lop Quan Ly Thoi Gian - Khoa 29', '2026-05-25', '2026-07-24', 48, 1060000, 'CLOSED', 5, '2026-05-25T08:00:00+07:00'),
(18, 24, N'Lop Tu Duy Phan Bien - Khoa 30', '2026-05-28', '2026-07-27', 49, 1080000, 'CLOSED', 6, '2026-05-28T08:00:00+07:00');
GO

-- subscription_package: 12 rows
INSERT INTO subscription_package (course_group_id, name, price, duration_days, status, created_by, created_at) VALUES
(1, N'Goi Membership 30 ngay - Nhom 1', 300000, 30, 'ACTIVE', 1, '2026-03-12T08:00:00+07:00'),
(2, N'Goi Membership 90 ngay - Nhom 2', 350000, 90, 'ACTIVE', 2, '2026-03-13T08:00:00+07:00'),
(3, N'Goi Membership 180 ngay - Nhom 3', 400000, 180, 'ACTIVE', 3, '2026-03-14T08:00:00+07:00'),
(4, N'Goi Membership 365 ngay - Nhom 4', 450000, 365, 'ACTIVE', 4, '2026-03-15T08:00:00+07:00'),
(5, N'Goi Membership 30 ngay - Nhom 5', 500000, 30, 'ACTIVE', 5, '2026-03-16T08:00:00+07:00'),
(6, N'Goi Membership 90 ngay - Nhom 6', 550000, 90, 'ACTIVE', 6, '2026-03-17T08:00:00+07:00'),
(7, N'Goi Membership 180 ngay - Nhom 7', 600000, 180, 'INACTIVE', 13, '2026-03-18T08:00:00+07:00'),
(8, N'Goi Membership 365 ngay - Nhom 8', 650000, 365, 'INACTIVE', 14, '2026-03-19T08:00:00+07:00'),
(9, N'Goi Membership 30 ngay - Nhom 9', 700000, 30, 'INACTIVE', 15, '2026-03-20T08:00:00+07:00'),
(10, N'Goi Membership 90 ngay - Nhom 10', 750000, 90, 'INACTIVE', 16, '2026-03-21T08:00:00+07:00'),
(11, N'Goi Membership 180 ngay - Nhom 11', 800000, 180, 'INACTIVE', 17, '2026-03-22T08:00:00+07:00'),
(12, N'Goi Membership 365 ngay - Nhom 12', 850000, 365, 'INACTIVE', 18, '2026-03-23T08:00:00+07:00');
GO

-- class_material: 60 rows
INSERT INTO class_material (class_id, teacher_id, title, body, file_url, created_at) VALUES
(1, 19, N'Tai lieu bo sung #1 cho lop 1', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class1_1.pdf', '2026-04-11T08:00:00+07:00'),
(1, 19, N'Tai lieu bo sung #2 cho lop 1', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class1_2.pdf', '2026-04-11T08:00:00+07:00'),
(2, 20, N'Tai lieu bo sung #1 cho lop 2', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class2_1.pdf', '2026-04-12T08:00:00+07:00'),
(2, 20, N'Tai lieu bo sung #2 cho lop 2', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class2_2.pdf', '2026-04-12T08:00:00+07:00'),
(3, 21, N'Tai lieu bo sung #1 cho lop 3', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class3_1.pdf', '2026-04-13T08:00:00+07:00'),
(3, 21, N'Tai lieu bo sung #2 cho lop 3', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class3_2.pdf', '2026-04-13T08:00:00+07:00'),
(4, 22, N'Tai lieu bo sung #1 cho lop 4', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class4_1.pdf', '2026-04-14T08:00:00+07:00'),
(4, 22, N'Tai lieu bo sung #2 cho lop 4', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class4_2.pdf', '2026-04-14T08:00:00+07:00'),
(5, 23, N'Tai lieu bo sung #1 cho lop 5', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class5_1.pdf', '2026-04-15T08:00:00+07:00'),
(5, 23, N'Tai lieu bo sung #2 cho lop 5', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class5_2.pdf', '2026-04-15T08:00:00+07:00'),
(6, 24, N'Tai lieu bo sung #1 cho lop 6', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class6_1.pdf', '2026-04-16T08:00:00+07:00'),
(6, 24, N'Tai lieu bo sung #2 cho lop 6', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class6_2.pdf', '2026-04-16T08:00:00+07:00'),
(7, 19, N'Tai lieu bo sung #1 cho lop 7', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class7_1.pdf', '2026-04-17T08:00:00+07:00'),
(7, 19, N'Tai lieu bo sung #2 cho lop 7', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class7_2.pdf', '2026-04-17T08:00:00+07:00'),
(8, 20, N'Tai lieu bo sung #1 cho lop 8', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class8_1.pdf', '2026-04-18T08:00:00+07:00'),
(8, 20, N'Tai lieu bo sung #2 cho lop 8', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class8_2.pdf', '2026-04-18T08:00:00+07:00'),
(9, 21, N'Tai lieu bo sung #1 cho lop 9', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class9_1.pdf', '2026-04-19T08:00:00+07:00'),
(9, 21, N'Tai lieu bo sung #2 cho lop 9', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class9_2.pdf', '2026-04-19T08:00:00+07:00'),
(10, 22, N'Tai lieu bo sung #1 cho lop 10', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class10_1.pdf', '2026-04-20T08:00:00+07:00'),
(10, 22, N'Tai lieu bo sung #2 cho lop 10', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class10_2.pdf', '2026-04-20T08:00:00+07:00'),
(11, 23, N'Tai lieu bo sung #1 cho lop 11', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class11_1.pdf', '2026-04-21T08:00:00+07:00'),
(11, 23, N'Tai lieu bo sung #2 cho lop 11', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class11_2.pdf', '2026-04-21T08:00:00+07:00'),
(12, 24, N'Tai lieu bo sung #1 cho lop 12', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class12_1.pdf', '2026-04-22T08:00:00+07:00'),
(12, 24, N'Tai lieu bo sung #2 cho lop 12', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class12_2.pdf', '2026-04-22T08:00:00+07:00'),
(13, 19, N'Tai lieu bo sung #1 cho lop 13', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class13_1.pdf', '2026-04-23T08:00:00+07:00'),
(13, 19, N'Tai lieu bo sung #2 cho lop 13', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class13_2.pdf', '2026-04-23T08:00:00+07:00'),
(14, 20, N'Tai lieu bo sung #1 cho lop 14', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class14_1.pdf', '2026-04-24T08:00:00+07:00'),
(14, 20, N'Tai lieu bo sung #2 cho lop 14', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class14_2.pdf', '2026-04-24T08:00:00+07:00'),
(15, 21, N'Tai lieu bo sung #1 cho lop 15', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class15_1.pdf', '2026-04-25T08:00:00+07:00'),
(15, 21, N'Tai lieu bo sung #2 cho lop 15', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class15_2.pdf', '2026-04-25T08:00:00+07:00'),
(16, 22, N'Tai lieu bo sung #1 cho lop 16', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class16_1.pdf', '2026-04-26T08:00:00+07:00'),
(16, 22, N'Tai lieu bo sung #2 cho lop 16', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class16_2.pdf', '2026-04-26T08:00:00+07:00'),
(17, 23, N'Tai lieu bo sung #1 cho lop 17', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class17_1.pdf', '2026-04-27T08:00:00+07:00'),
(17, 23, N'Tai lieu bo sung #2 cho lop 17', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class17_2.pdf', '2026-04-27T08:00:00+07:00'),
(18, 24, N'Tai lieu bo sung #1 cho lop 18', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class18_1.pdf', '2026-04-28T08:00:00+07:00'),
(18, 24, N'Tai lieu bo sung #2 cho lop 18', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class18_2.pdf', '2026-04-28T08:00:00+07:00'),
(19, 19, N'Tai lieu bo sung #1 cho lop 19', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class19_1.pdf', '2026-04-29T08:00:00+07:00'),
(19, 19, N'Tai lieu bo sung #2 cho lop 19', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class19_2.pdf', '2026-04-29T08:00:00+07:00'),
(20, 20, N'Tai lieu bo sung #1 cho lop 20', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class20_1.pdf', '2026-04-30T08:00:00+07:00'),
(20, 20, N'Tai lieu bo sung #2 cho lop 20', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class20_2.pdf', '2026-04-30T08:00:00+07:00'),
(21, 21, N'Tai lieu bo sung #1 cho lop 21', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class21_1.pdf', '2026-05-01T08:00:00+07:00'),
(21, 21, N'Tai lieu bo sung #2 cho lop 21', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class21_2.pdf', '2026-05-01T08:00:00+07:00'),
(22, 22, N'Tai lieu bo sung #1 cho lop 22', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class22_1.pdf', '2026-05-02T08:00:00+07:00'),
(22, 22, N'Tai lieu bo sung #2 cho lop 22', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class22_2.pdf', '2026-05-02T08:00:00+07:00'),
(23, 23, N'Tai lieu bo sung #1 cho lop 23', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class23_1.pdf', '2026-05-03T08:00:00+07:00'),
(23, 23, N'Tai lieu bo sung #2 cho lop 23', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class23_2.pdf', '2026-05-03T08:00:00+07:00'),
(24, 24, N'Tai lieu bo sung #1 cho lop 24', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class24_1.pdf', '2026-05-04T08:00:00+07:00'),
(24, 24, N'Tai lieu bo sung #2 cho lop 24', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class24_2.pdf', '2026-05-04T08:00:00+07:00'),
(25, 19, N'Tai lieu bo sung #1 cho lop 25', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class25_1.pdf', '2026-05-05T08:00:00+07:00'),
(25, 19, N'Tai lieu bo sung #2 cho lop 25', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class25_2.pdf', '2026-05-05T08:00:00+07:00');
INSERT INTO class_material (class_id, teacher_id, title, body, file_url, created_at) VALUES
(26, 20, N'Tai lieu bo sung #1 cho lop 26', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class26_1.pdf', '2026-05-06T08:00:00+07:00'),
(26, 20, N'Tai lieu bo sung #2 cho lop 26', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class26_2.pdf', '2026-05-06T08:00:00+07:00'),
(27, 21, N'Tai lieu bo sung #1 cho lop 27', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class27_1.pdf', '2026-05-07T08:00:00+07:00'),
(27, 21, N'Tai lieu bo sung #2 cho lop 27', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class27_2.pdf', '2026-05-07T08:00:00+07:00'),
(28, 22, N'Tai lieu bo sung #1 cho lop 28', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class28_1.pdf', '2026-05-08T08:00:00+07:00'),
(28, 22, N'Tai lieu bo sung #2 cho lop 28', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class28_2.pdf', '2026-05-08T08:00:00+07:00'),
(29, 23, N'Tai lieu bo sung #1 cho lop 29', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class29_1.pdf', '2026-05-09T08:00:00+07:00'),
(29, 23, N'Tai lieu bo sung #2 cho lop 29', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class29_2.pdf', '2026-05-09T08:00:00+07:00'),
(30, 24, N'Tai lieu bo sung #1 cho lop 30', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class30_1.pdf', '2026-05-10T08:00:00+07:00'),
(30, 24, N'Tai lieu bo sung #2 cho lop 30', N'Noi dung bo sung rieng cho lop, khong anh huong course goc.', N'https://cdn.edunexus.vn/materials/class30_2.pdf', '2026-05-10T08:00:00+07:00');
GO

-- enrollment: 84 rows
INSERT INTO enrollment (student_id, enrollment_type, course_id, class_id, subscription_package_id, status, enrolled_at, expires_at, progress_percent, created_at) VALUES
(25, 'H1', 13, NULL, NULL, 'ACTIVE', '2026-03-12T08:00:00+07:00', NULL, 10, '2026-03-12T08:00:00+07:00'),
(26, 'H1', 14, NULL, NULL, 'COMPLETED', '2026-03-13T08:00:00+07:00', NULL, 17, '2026-03-13T08:00:00+07:00'),
(27, 'H1', 15, NULL, NULL, 'CANCELLED', '2026-03-14T08:00:00+07:00', NULL, 24, '2026-03-14T08:00:00+07:00'),
(28, 'H1', 16, NULL, NULL, 'EXPIRED', '2026-03-15T08:00:00+07:00', NULL, 31, '2026-03-15T08:00:00+07:00'),
(29, 'H1', 17, NULL, NULL, 'ACTIVE', '2026-03-16T08:00:00+07:00', NULL, 38, '2026-03-16T08:00:00+07:00'),
(30, 'H1', 18, NULL, NULL, 'COMPLETED', '2026-03-17T08:00:00+07:00', NULL, 45, '2026-03-17T08:00:00+07:00'),
(31, 'H1', 13, NULL, NULL, 'CANCELLED', '2026-03-18T08:00:00+07:00', NULL, 52, '2026-03-18T08:00:00+07:00'),
(32, 'H1', 14, NULL, NULL, 'EXPIRED', '2026-03-19T08:00:00+07:00', NULL, 59, '2026-03-19T08:00:00+07:00'),
(33, 'H1', 15, NULL, NULL, 'ACTIVE', '2026-03-20T08:00:00+07:00', NULL, 66, '2026-03-20T08:00:00+07:00'),
(34, 'H1', 16, NULL, NULL, 'COMPLETED', '2026-03-21T08:00:00+07:00', NULL, 73, '2026-03-21T08:00:00+07:00'),
(35, 'H1', 17, NULL, NULL, 'CANCELLED', '2026-03-22T08:00:00+07:00', NULL, 80, '2026-03-22T08:00:00+07:00'),
(36, 'H1', 18, NULL, NULL, 'EXPIRED', '2026-03-23T08:00:00+07:00', NULL, 87, '2026-03-23T08:00:00+07:00'),
(25, 'H2', NULL, 1, NULL, 'ACTIVE', '2026-03-17T08:00:00+07:00', '2026-05-31T08:00:00+07:00', 5, '2026-03-17T08:00:00+07:00'),
(26, 'H2', NULL, 1, NULL, 'COMPLETED', '2026-03-18T08:00:00+07:00', NULL, 6, '2026-03-18T08:00:00+07:00'),
(27, 'H2', NULL, 2, NULL, 'CANCELLED', '2026-03-19T08:00:00+07:00', NULL, 7, '2026-03-19T08:00:00+07:00'),
(28, 'H2', NULL, 2, NULL, 'EXPIRED', '2026-03-20T08:00:00+07:00', '2026-06-03T08:00:00+07:00', 8, '2026-03-20T08:00:00+07:00'),
(29, 'H2', NULL, 3, NULL, 'ACTIVE', '2026-03-21T08:00:00+07:00', '2026-06-04T08:00:00+07:00', 9, '2026-03-21T08:00:00+07:00'),
(30, 'H2', NULL, 3, NULL, 'COMPLETED', '2026-03-22T08:00:00+07:00', NULL, 10, '2026-03-22T08:00:00+07:00'),
(31, 'H2', NULL, 4, NULL, 'CANCELLED', '2026-03-23T08:00:00+07:00', NULL, 11, '2026-03-23T08:00:00+07:00'),
(32, 'H2', NULL, 4, NULL, 'EXPIRED', '2026-03-24T08:00:00+07:00', '2026-06-07T08:00:00+07:00', 12, '2026-03-24T08:00:00+07:00'),
(33, 'H2', NULL, 5, NULL, 'ACTIVE', '2026-03-25T08:00:00+07:00', '2026-06-08T08:00:00+07:00', 13, '2026-03-25T08:00:00+07:00'),
(34, 'H2', NULL, 5, NULL, 'COMPLETED', '2026-03-26T08:00:00+07:00', NULL, 14, '2026-03-26T08:00:00+07:00'),
(35, 'H2', NULL, 6, NULL, 'CANCELLED', '2026-03-27T08:00:00+07:00', NULL, 15, '2026-03-27T08:00:00+07:00'),
(36, 'H2', NULL, 6, NULL, 'EXPIRED', '2026-03-28T08:00:00+07:00', '2026-06-11T08:00:00+07:00', 16, '2026-03-28T08:00:00+07:00'),
(37, 'H2', NULL, 7, NULL, 'ACTIVE', '2026-03-29T08:00:00+07:00', '2026-06-12T08:00:00+07:00', 17, '2026-03-29T08:00:00+07:00'),
(38, 'H2', NULL, 7, NULL, 'COMPLETED', '2026-03-30T08:00:00+07:00', NULL, 18, '2026-03-30T08:00:00+07:00'),
(39, 'H2', NULL, 8, NULL, 'CANCELLED', '2026-03-31T08:00:00+07:00', NULL, 19, '2026-03-31T08:00:00+07:00'),
(40, 'H2', NULL, 8, NULL, 'EXPIRED', '2026-04-01T08:00:00+07:00', '2026-06-15T08:00:00+07:00', 20, '2026-04-01T08:00:00+07:00'),
(41, 'H2', NULL, 9, NULL, 'ACTIVE', '2026-04-02T08:00:00+07:00', '2026-06-16T08:00:00+07:00', 21, '2026-04-02T08:00:00+07:00'),
(42, 'H2', NULL, 9, NULL, 'COMPLETED', '2026-04-03T08:00:00+07:00', NULL, 22, '2026-04-03T08:00:00+07:00'),
(43, 'H2', NULL, 10, NULL, 'CANCELLED', '2026-04-04T08:00:00+07:00', NULL, 23, '2026-04-04T08:00:00+07:00'),
(44, 'H2', NULL, 10, NULL, 'EXPIRED', '2026-04-05T08:00:00+07:00', '2026-06-19T08:00:00+07:00', 24, '2026-04-05T08:00:00+07:00'),
(45, 'H2', NULL, 11, NULL, 'ACTIVE', '2026-04-06T08:00:00+07:00', '2026-06-20T08:00:00+07:00', 25, '2026-04-06T08:00:00+07:00'),
(46, 'H2', NULL, 11, NULL, 'COMPLETED', '2026-04-07T08:00:00+07:00', NULL, 26, '2026-04-07T08:00:00+07:00'),
(47, 'H2', NULL, 12, NULL, 'CANCELLED', '2026-04-08T08:00:00+07:00', NULL, 27, '2026-04-08T08:00:00+07:00'),
(48, 'H2', NULL, 12, NULL, 'EXPIRED', '2026-04-09T08:00:00+07:00', '2026-06-23T08:00:00+07:00', 28, '2026-04-09T08:00:00+07:00'),
(49, 'H2', NULL, 13, NULL, 'ACTIVE', '2026-04-10T08:00:00+07:00', '2026-06-24T08:00:00+07:00', 29, '2026-04-10T08:00:00+07:00'),
(50, 'H2', NULL, 13, NULL, 'COMPLETED', '2026-04-11T08:00:00+07:00', NULL, 30, '2026-04-11T08:00:00+07:00'),
(51, 'H2', NULL, 14, NULL, 'CANCELLED', '2026-04-12T08:00:00+07:00', NULL, 31, '2026-04-12T08:00:00+07:00'),
(52, 'H2', NULL, 14, NULL, 'EXPIRED', '2026-04-13T08:00:00+07:00', '2026-06-27T08:00:00+07:00', 32, '2026-04-13T08:00:00+07:00'),
(53, 'H2', NULL, 15, NULL, 'ACTIVE', '2026-04-14T08:00:00+07:00', '2026-06-28T08:00:00+07:00', 33, '2026-04-14T08:00:00+07:00'),
(54, 'H2', NULL, 15, NULL, 'COMPLETED', '2026-04-15T08:00:00+07:00', NULL, 34, '2026-04-15T08:00:00+07:00'),
(25, 'H2', NULL, 16, NULL, 'CANCELLED', '2026-04-16T08:00:00+07:00', NULL, 35, '2026-04-16T08:00:00+07:00'),
(26, 'H2', NULL, 16, NULL, 'EXPIRED', '2026-04-17T08:00:00+07:00', '2026-07-01T08:00:00+07:00', 36, '2026-04-17T08:00:00+07:00'),
(27, 'H2', NULL, 17, NULL, 'ACTIVE', '2026-04-18T08:00:00+07:00', '2026-07-02T08:00:00+07:00', 37, '2026-04-18T08:00:00+07:00'),
(28, 'H2', NULL, 17, NULL, 'COMPLETED', '2026-04-19T08:00:00+07:00', NULL, 38, '2026-04-19T08:00:00+07:00'),
(29, 'H2', NULL, 18, NULL, 'CANCELLED', '2026-04-20T08:00:00+07:00', NULL, 39, '2026-04-20T08:00:00+07:00'),
(30, 'H2', NULL, 18, NULL, 'EXPIRED', '2026-04-21T08:00:00+07:00', '2026-07-05T08:00:00+07:00', 40, '2026-04-21T08:00:00+07:00'),
(31, 'H2', NULL, 19, NULL, 'ACTIVE', '2026-04-22T08:00:00+07:00', '2026-07-06T08:00:00+07:00', 41, '2026-04-22T08:00:00+07:00'),
(32, 'H2', NULL, 19, NULL, 'COMPLETED', '2026-04-23T08:00:00+07:00', NULL, 42, '2026-04-23T08:00:00+07:00');
INSERT INTO enrollment (student_id, enrollment_type, course_id, class_id, subscription_package_id, status, enrolled_at, expires_at, progress_percent, created_at) VALUES
(33, 'H2', NULL, 20, NULL, 'CANCELLED', '2026-04-24T08:00:00+07:00', NULL, 43, '2026-04-24T08:00:00+07:00'),
(34, 'H2', NULL, 20, NULL, 'EXPIRED', '2026-04-25T08:00:00+07:00', '2026-07-09T08:00:00+07:00', 44, '2026-04-25T08:00:00+07:00'),
(35, 'H2', NULL, 21, NULL, 'ACTIVE', '2026-04-26T08:00:00+07:00', '2026-07-10T08:00:00+07:00', 45, '2026-04-26T08:00:00+07:00'),
(36, 'H2', NULL, 21, NULL, 'COMPLETED', '2026-04-27T08:00:00+07:00', NULL, 46, '2026-04-27T08:00:00+07:00'),
(37, 'H2', NULL, 22, NULL, 'CANCELLED', '2026-04-28T08:00:00+07:00', NULL, 47, '2026-04-28T08:00:00+07:00'),
(38, 'H2', NULL, 22, NULL, 'EXPIRED', '2026-04-29T08:00:00+07:00', '2026-07-13T08:00:00+07:00', 48, '2026-04-29T08:00:00+07:00'),
(39, 'H2', NULL, 23, NULL, 'ACTIVE', '2026-04-30T08:00:00+07:00', '2026-07-14T08:00:00+07:00', 49, '2026-04-30T08:00:00+07:00'),
(40, 'H2', NULL, 23, NULL, 'COMPLETED', '2026-05-01T08:00:00+07:00', NULL, 50, '2026-05-01T08:00:00+07:00'),
(41, 'H2', NULL, 24, NULL, 'CANCELLED', '2026-05-02T08:00:00+07:00', NULL, 51, '2026-05-02T08:00:00+07:00'),
(42, 'H2', NULL, 24, NULL, 'EXPIRED', '2026-05-03T08:00:00+07:00', '2026-07-17T08:00:00+07:00', 52, '2026-05-03T08:00:00+07:00'),
(43, 'H2', NULL, 25, NULL, 'ACTIVE', '2026-05-04T08:00:00+07:00', '2026-07-18T08:00:00+07:00', 53, '2026-05-04T08:00:00+07:00'),
(44, 'H2', NULL, 25, NULL, 'COMPLETED', '2026-05-05T08:00:00+07:00', NULL, 54, '2026-05-05T08:00:00+07:00'),
(45, 'H2', NULL, 26, NULL, 'CANCELLED', '2026-05-06T08:00:00+07:00', NULL, 55, '2026-05-06T08:00:00+07:00'),
(46, 'H2', NULL, 26, NULL, 'EXPIRED', '2026-05-07T08:00:00+07:00', '2026-07-21T08:00:00+07:00', 56, '2026-05-07T08:00:00+07:00'),
(47, 'H2', NULL, 27, NULL, 'ACTIVE', '2026-05-08T08:00:00+07:00', '2026-07-22T08:00:00+07:00', 57, '2026-05-08T08:00:00+07:00'),
(48, 'H2', NULL, 27, NULL, 'COMPLETED', '2026-05-09T08:00:00+07:00', NULL, 58, '2026-05-09T08:00:00+07:00'),
(49, 'H2', NULL, 28, NULL, 'CANCELLED', '2026-05-10T08:00:00+07:00', NULL, 59, '2026-05-10T08:00:00+07:00'),
(50, 'H2', NULL, 28, NULL, 'EXPIRED', '2026-05-11T08:00:00+07:00', '2026-07-25T08:00:00+07:00', 60, '2026-05-11T08:00:00+07:00'),
(51, 'H2', NULL, 29, NULL, 'ACTIVE', '2026-05-12T08:00:00+07:00', '2026-07-26T08:00:00+07:00', 61, '2026-05-12T08:00:00+07:00'),
(52, 'H2', NULL, 29, NULL, 'COMPLETED', '2026-05-13T08:00:00+07:00', NULL, 62, '2026-05-13T08:00:00+07:00'),
(53, 'H2', NULL, 30, NULL, 'CANCELLED', '2026-05-14T08:00:00+07:00', NULL, 63, '2026-05-14T08:00:00+07:00'),
(54, 'H2', NULL, 30, NULL, 'EXPIRED', '2026-05-15T08:00:00+07:00', '2026-07-29T08:00:00+07:00', 64, '2026-05-15T08:00:00+07:00'),
(30, 'H3', NULL, NULL, 1, 'ACTIVE', '2026-03-22T08:00:00+07:00', '2026-05-31T08:00:00+07:00', 8, '2026-03-22T08:00:00+07:00'),
(31, 'H3', NULL, NULL, 2, 'COMPLETED', '2026-03-23T08:00:00+07:00', '2026-06-01T08:00:00+07:00', 14, '2026-03-23T08:00:00+07:00'),
(32, 'H3', NULL, NULL, 3, 'CANCELLED', '2026-03-24T08:00:00+07:00', '2026-06-02T08:00:00+07:00', 20, '2026-03-24T08:00:00+07:00'),
(33, 'H3', NULL, NULL, 4, 'EXPIRED', '2026-03-25T08:00:00+07:00', '2026-06-03T08:00:00+07:00', 26, '2026-03-25T08:00:00+07:00'),
(34, 'H3', NULL, NULL, 5, 'ACTIVE', '2026-03-26T08:00:00+07:00', '2026-06-04T08:00:00+07:00', 32, '2026-03-26T08:00:00+07:00'),
(35, 'H3', NULL, NULL, 6, 'COMPLETED', '2026-03-27T08:00:00+07:00', '2026-06-05T08:00:00+07:00', 38, '2026-03-27T08:00:00+07:00'),
(36, 'H3', NULL, NULL, 7, 'CANCELLED', '2026-03-28T08:00:00+07:00', '2026-06-06T08:00:00+07:00', 44, '2026-03-28T08:00:00+07:00'),
(37, 'H3', NULL, NULL, 8, 'EXPIRED', '2026-03-29T08:00:00+07:00', '2026-06-07T08:00:00+07:00', 50, '2026-03-29T08:00:00+07:00'),
(38, 'H3', NULL, NULL, 9, 'ACTIVE', '2026-03-30T08:00:00+07:00', '2026-06-08T08:00:00+07:00', 56, '2026-03-30T08:00:00+07:00'),
(39, 'H3', NULL, NULL, 10, 'COMPLETED', '2026-03-31T08:00:00+07:00', '2026-06-09T08:00:00+07:00', 62, '2026-03-31T08:00:00+07:00'),
(40, 'H3', NULL, NULL, 11, 'CANCELLED', '2026-04-01T08:00:00+07:00', '2026-06-10T08:00:00+07:00', 68, '2026-04-01T08:00:00+07:00'),
(41, 'H3', NULL, NULL, 12, 'EXPIRED', '2026-04-02T08:00:00+07:00', '2026-06-11T08:00:00+07:00', 74, '2026-04-02T08:00:00+07:00');
GO

-- payment: 84 rows
INSERT INTO payment (enrollment_id, user_id, amount, gateway, status, transaction_ref, paid_at, created_at) VALUES
(1, 25, 115000, 'SEPAY', 'PAID', N'TXN-2026-00001', '2026-03-23T08:00:00+07:00', '2026-03-18T08:00:00+07:00'),
(2, 26, 130000, 'VNPAY', 'PAID', N'TXN-2026-00002', '2026-03-24T08:00:00+07:00', '2026-03-19T08:00:00+07:00'),
(3, 27, 145000, 'SEPAY', 'REFUNDED', N'TXN-2026-00003', '2026-03-25T08:00:00+07:00', '2026-03-20T08:00:00+07:00'),
(4, 28, 160000, 'VNPAY', 'PAID', N'TXN-2026-00004', '2026-03-26T08:00:00+07:00', '2026-03-21T08:00:00+07:00'),
(5, 29, 175000, 'SEPAY', 'PAID', N'TXN-2026-00005', '2026-03-27T08:00:00+07:00', '2026-03-22T08:00:00+07:00'),
(6, 30, 190000, 'VNPAY', 'PAID', N'TXN-2026-00006', '2026-03-28T08:00:00+07:00', '2026-03-23T08:00:00+07:00'),
(7, 31, 205000, 'SEPAY', 'REFUNDED', N'TXN-2026-00007', '2026-03-29T08:00:00+07:00', '2026-03-24T08:00:00+07:00'),
(8, 32, 220000, 'VNPAY', 'PAID', N'TXN-2026-00008', '2026-03-30T08:00:00+07:00', '2026-03-25T08:00:00+07:00'),
(9, 33, 235000, 'SEPAY', 'PAID', N'TXN-2026-00009', '2026-03-31T08:00:00+07:00', '2026-03-26T08:00:00+07:00'),
(10, 34, 250000, 'VNPAY', 'PAID', N'TXN-2026-00010', '2026-04-01T08:00:00+07:00', '2026-03-27T08:00:00+07:00'),
(11, 35, 265000, 'SEPAY', 'REFUNDED', N'TXN-2026-00011', '2026-04-02T08:00:00+07:00', '2026-03-28T08:00:00+07:00'),
(12, 36, 280000, 'VNPAY', 'PAID', N'TXN-2026-00012', '2026-04-03T08:00:00+07:00', '2026-03-29T08:00:00+07:00'),
(13, 25, 295000, 'SEPAY', 'FAILED', NULL, NULL, '2026-03-30T08:00:00+07:00'),
(14, 26, 310000, 'VNPAY', 'PENDING', NULL, NULL, '2026-03-31T08:00:00+07:00'),
(15, 27, 325000, 'SEPAY', 'REFUNDED', N'TXN-2026-00015', '2026-04-06T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(16, 28, 340000, 'VNPAY', 'PAID', N'TXN-2026-00016', '2026-04-07T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(17, 29, 355000, 'SEPAY', 'PAID', N'TXN-2026-00017', '2026-04-08T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(18, 30, 370000, 'VNPAY', 'PAID', N'TXN-2026-00018', '2026-04-09T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(19, 31, 385000, 'SEPAY', 'REFUNDED', N'TXN-2026-00019', '2026-04-10T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(20, 32, 400000, 'VNPAY', 'PAID', N'TXN-2026-00020', '2026-04-11T08:00:00+07:00', '2026-04-06T08:00:00+07:00'),
(21, 33, 415000, 'SEPAY', 'PAID', N'TXN-2026-00021', '2026-04-12T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(22, 34, 430000, 'VNPAY', 'PAID', N'TXN-2026-00022', '2026-04-13T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(23, 35, 445000, 'SEPAY', 'REFUNDED', N'TXN-2026-00023', '2026-04-14T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(24, 36, 460000, 'VNPAY', 'PAID', N'TXN-2026-00024', '2026-04-15T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(25, 37, 475000, 'SEPAY', 'PAID', N'TXN-2026-00025', '2026-04-16T08:00:00+07:00', '2026-04-11T08:00:00+07:00'),
(26, 38, 490000, 'VNPAY', 'FAILED', NULL, NULL, '2026-04-12T08:00:00+07:00'),
(27, 39, 505000, 'SEPAY', 'REFUNDED', N'TXN-2026-00027', '2026-04-18T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(28, 40, 520000, 'VNPAY', 'PENDING', NULL, NULL, '2026-04-14T08:00:00+07:00'),
(29, 41, 535000, 'SEPAY', 'PAID', N'TXN-2026-00029', '2026-04-20T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(30, 42, 550000, 'VNPAY', 'PAID', N'TXN-2026-00030', '2026-04-21T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(31, 43, 565000, 'SEPAY', 'REFUNDED', N'TXN-2026-00031', '2026-04-22T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(32, 44, 580000, 'VNPAY', 'PAID', N'TXN-2026-00032', '2026-04-23T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(33, 45, 595000, 'SEPAY', 'PAID', N'TXN-2026-00033', '2026-04-24T08:00:00+07:00', '2026-04-19T08:00:00+07:00'),
(34, 46, 610000, 'VNPAY', 'PAID', N'TXN-2026-00034', '2026-04-25T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(35, 47, 625000, 'SEPAY', 'REFUNDED', N'TXN-2026-00035', '2026-04-26T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(36, 48, 640000, 'VNPAY', 'PAID', N'TXN-2026-00036', '2026-04-27T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(37, 49, 655000, 'SEPAY', 'PAID', N'TXN-2026-00037', '2026-04-28T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(38, 50, 670000, 'VNPAY', 'PAID', N'TXN-2026-00038', '2026-04-29T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(39, 51, 685000, 'SEPAY', 'FAILED', NULL, NULL, '2026-04-25T08:00:00+07:00'),
(40, 52, 700000, 'VNPAY', 'PAID', N'TXN-2026-00040', '2026-03-22T08:00:00+07:00', '2026-04-26T08:00:00+07:00'),
(41, 53, 715000, 'SEPAY', 'PAID', N'TXN-2026-00041', '2026-03-23T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(42, 54, 730000, 'VNPAY', 'PENDING', NULL, NULL, '2026-04-28T08:00:00+07:00'),
(43, 25, 745000, 'SEPAY', 'REFUNDED', N'TXN-2026-00043', '2026-03-25T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(44, 26, 760000, 'VNPAY', 'PAID', N'TXN-2026-00044', '2026-03-26T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(45, 27, 775000, 'SEPAY', 'PAID', N'TXN-2026-00045', '2026-03-27T08:00:00+07:00', '2026-03-17T08:00:00+07:00'),
(46, 28, 790000, 'VNPAY', 'PAID', N'TXN-2026-00046', '2026-03-28T08:00:00+07:00', '2026-03-18T08:00:00+07:00'),
(47, 29, 805000, 'SEPAY', 'REFUNDED', N'TXN-2026-00047', '2026-03-29T08:00:00+07:00', '2026-03-19T08:00:00+07:00'),
(48, 30, 820000, 'VNPAY', 'PAID', N'TXN-2026-00048', '2026-03-30T08:00:00+07:00', '2026-03-20T08:00:00+07:00'),
(49, 31, 835000, 'SEPAY', 'PAID', N'TXN-2026-00049', '2026-03-31T08:00:00+07:00', '2026-03-21T08:00:00+07:00'),
(50, 32, 850000, 'VNPAY', 'PAID', N'TXN-2026-00050', '2026-04-01T08:00:00+07:00', '2026-03-22T08:00:00+07:00');
INSERT INTO payment (enrollment_id, user_id, amount, gateway, status, transaction_ref, paid_at, created_at) VALUES
(51, 33, 865000, 'SEPAY', 'REFUNDED', N'TXN-2026-00051', '2026-04-02T08:00:00+07:00', '2026-03-23T08:00:00+07:00'),
(52, 34, 880000, 'VNPAY', 'FAILED', NULL, NULL, '2026-03-24T08:00:00+07:00'),
(53, 35, 895000, 'SEPAY', 'PAID', N'TXN-2026-00053', '2026-04-04T08:00:00+07:00', '2026-03-25T08:00:00+07:00'),
(54, 36, 910000, 'VNPAY', 'PAID', N'TXN-2026-00054', '2026-04-05T08:00:00+07:00', '2026-03-26T08:00:00+07:00'),
(55, 37, 925000, 'SEPAY', 'REFUNDED', N'TXN-2026-00055', '2026-04-06T08:00:00+07:00', '2026-03-27T08:00:00+07:00'),
(56, 38, 940000, 'VNPAY', 'PENDING', NULL, NULL, '2026-03-28T08:00:00+07:00'),
(57, 39, 955000, 'SEPAY', 'PAID', N'TXN-2026-00057', '2026-04-08T08:00:00+07:00', '2026-03-29T08:00:00+07:00'),
(58, 40, 970000, 'VNPAY', 'PAID', N'TXN-2026-00058', '2026-04-09T08:00:00+07:00', '2026-03-30T08:00:00+07:00'),
(59, 41, 985000, 'SEPAY', 'REFUNDED', N'TXN-2026-00059', '2026-04-10T08:00:00+07:00', '2026-03-31T08:00:00+07:00'),
(60, 42, 100000, 'VNPAY', 'PAID', N'TXN-2026-00060', '2026-04-11T08:00:00+07:00', '2026-04-01T08:00:00+07:00'),
(61, 43, 115000, 'SEPAY', 'PAID', N'TXN-2026-00061', '2026-04-12T08:00:00+07:00', '2026-04-02T08:00:00+07:00'),
(62, 44, 130000, 'VNPAY', 'PAID', N'TXN-2026-00062', '2026-04-13T08:00:00+07:00', '2026-04-03T08:00:00+07:00'),
(63, 45, 145000, 'SEPAY', 'REFUNDED', N'TXN-2026-00063', '2026-04-14T08:00:00+07:00', '2026-04-04T08:00:00+07:00'),
(64, 46, 160000, 'VNPAY', 'PAID', N'TXN-2026-00064', '2026-04-15T08:00:00+07:00', '2026-04-05T08:00:00+07:00'),
(65, 47, 175000, 'SEPAY', 'FAILED', NULL, NULL, '2026-04-06T08:00:00+07:00'),
(66, 48, 190000, 'VNPAY', 'PAID', N'TXN-2026-00066', '2026-04-17T08:00:00+07:00', '2026-04-07T08:00:00+07:00'),
(67, 49, 205000, 'SEPAY', 'REFUNDED', N'TXN-2026-00067', '2026-04-18T08:00:00+07:00', '2026-04-08T08:00:00+07:00'),
(68, 50, 220000, 'VNPAY', 'PAID', N'TXN-2026-00068', '2026-04-19T08:00:00+07:00', '2026-04-09T08:00:00+07:00'),
(69, 51, 235000, 'SEPAY', 'PAID', N'TXN-2026-00069', '2026-04-20T08:00:00+07:00', '2026-04-10T08:00:00+07:00'),
(70, 52, 250000, 'VNPAY', 'PENDING', NULL, NULL, '2026-04-11T08:00:00+07:00'),
(71, 53, 265000, 'SEPAY', 'REFUNDED', N'TXN-2026-00071', '2026-04-22T08:00:00+07:00', '2026-04-12T08:00:00+07:00'),
(72, 54, 280000, 'VNPAY', 'PAID', N'TXN-2026-00072', '2026-04-23T08:00:00+07:00', '2026-04-13T08:00:00+07:00'),
(73, 30, 295000, 'SEPAY', 'PAID', N'TXN-2026-00073', '2026-04-24T08:00:00+07:00', '2026-04-14T08:00:00+07:00'),
(74, 31, 310000, 'VNPAY', 'PAID', N'TXN-2026-00074', '2026-04-25T08:00:00+07:00', '2026-04-15T08:00:00+07:00'),
(75, 32, 325000, 'SEPAY', 'REFUNDED', N'TXN-2026-00075', '2026-04-26T08:00:00+07:00', '2026-04-16T08:00:00+07:00'),
(76, 33, 340000, 'VNPAY', 'PAID', N'TXN-2026-00076', '2026-04-27T08:00:00+07:00', '2026-04-17T08:00:00+07:00'),
(77, 34, 355000, 'SEPAY', 'PAID', N'TXN-2026-00077', '2026-04-28T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(78, 35, 370000, 'VNPAY', 'FAILED', NULL, NULL, '2026-04-19T08:00:00+07:00'),
(79, 36, 385000, 'SEPAY', 'REFUNDED', N'TXN-2026-00079', '2026-04-30T08:00:00+07:00', '2026-04-20T08:00:00+07:00'),
(80, 37, 400000, 'VNPAY', 'PAID', N'TXN-2026-00080', '2026-03-22T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(81, 38, 415000, 'SEPAY', 'PAID', N'TXN-2026-00081', '2026-03-23T08:00:00+07:00', '2026-04-22T08:00:00+07:00'),
(82, 39, 430000, 'VNPAY', 'PAID', N'TXN-2026-00082', '2026-03-24T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(83, 40, 445000, 'SEPAY', 'REFUNDED', N'TXN-2026-00083', '2026-03-25T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(84, 41, 460000, 'VNPAY', 'PENDING', NULL, NULL, '2026-04-25T08:00:00+07:00');
GO

-- refund_request: 24 rows
INSERT INTO refund_request (payment_id, student_id, reason, status, reviewed_by, reviewed_at, refunded_at, created_at) VALUES
(1, 25, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'PENDING', NULL, NULL, NULL, '2026-04-23T08:00:00+07:00'),
(2, 26, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'PENDING', NULL, NULL, NULL, '2026-04-24T08:00:00+07:00'),
(3, 27, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'PENDING', NULL, NULL, NULL, '2026-04-25T08:00:00+07:00'),
(4, 28, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'PENDING', NULL, NULL, NULL, '2026-04-26T08:00:00+07:00'),
(5, 29, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'PENDING', NULL, NULL, NULL, '2026-04-27T08:00:00+07:00'),
(6, 30, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'PENDING', NULL, NULL, NULL, '2026-04-28T08:00:00+07:00'),
(7, 31, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'APPROVED', 1, '2026-05-02T08:00:00+07:00', NULL, '2026-04-29T08:00:00+07:00'),
(8, 32, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'APPROVED', 2, '2026-05-03T08:00:00+07:00', NULL, '2026-04-30T08:00:00+07:00'),
(9, 33, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'APPROVED', 3, '2026-05-04T08:00:00+07:00', NULL, '2026-05-01T08:00:00+07:00'),
(10, 34, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'APPROVED', 4, '2026-05-05T08:00:00+07:00', NULL, '2026-05-02T08:00:00+07:00'),
(11, 35, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'APPROVED', 5, '2026-05-06T08:00:00+07:00', NULL, '2026-05-03T08:00:00+07:00'),
(12, 36, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'APPROVED', 6, '2026-05-07T08:00:00+07:00', NULL, '2026-05-04T08:00:00+07:00'),
(15, 27, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'REJECTED', 13, '2026-05-08T08:00:00+07:00', NULL, '2026-05-05T08:00:00+07:00'),
(16, 28, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'REJECTED', 14, '2026-05-09T08:00:00+07:00', NULL, '2026-05-06T08:00:00+07:00'),
(17, 29, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'REJECTED', 15, '2026-05-10T08:00:00+07:00', NULL, '2026-05-07T08:00:00+07:00'),
(18, 30, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'REJECTED', 16, '2026-05-11T08:00:00+07:00', NULL, '2026-05-08T08:00:00+07:00'),
(19, 31, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'REJECTED', 17, '2026-05-12T08:00:00+07:00', NULL, '2026-05-09T08:00:00+07:00'),
(20, 32, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'REJECTED', 18, '2026-05-13T08:00:00+07:00', NULL, '2026-05-10T08:00:00+07:00'),
(21, 33, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'COMPLETED', 1, '2026-05-14T08:00:00+07:00', '2026-05-16T08:00:00+07:00', '2026-05-11T08:00:00+07:00'),
(22, 34, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'COMPLETED', 2, '2026-05-15T08:00:00+07:00', '2026-05-17T08:00:00+07:00', '2026-05-12T08:00:00+07:00'),
(23, 35, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'COMPLETED', 3, '2026-05-16T08:00:00+07:00', '2026-05-18T08:00:00+07:00', '2026-05-13T08:00:00+07:00'),
(24, 36, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'COMPLETED', 4, '2026-05-17T08:00:00+07:00', '2026-05-19T08:00:00+07:00', '2026-05-14T08:00:00+07:00'),
(25, 37, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'COMPLETED', 5, '2026-05-18T08:00:00+07:00', '2026-05-20T08:00:00+07:00', '2026-05-15T08:00:00+07:00'),
(27, 39, N'Hoc vien yeu cau hoan tien do khong con nhu cau hoc tiep.', 'COMPLETED', 6, '2026-05-19T08:00:00+07:00', '2026-05-21T08:00:00+07:00', '2026-05-16T08:00:00+07:00');
GO

-- assignment: 18 rows
INSERT INTO assignment (class_id, lesson_id, title, description_md, max_score, due_date, status, created_by, created_at) VALUES
(1, 145, N'Bai tap tu luan #1 - Photoshop Can Ban', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-05T08:00:00+07:00', 'DRAFT', 7, '2026-03-22T08:00:00+07:00'),
(2, NULL, N'Bai tap tu luan #2 - Illustrator Nang Cao', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-06T08:00:00+07:00', 'DRAFT', 8, '2026-03-23T08:00:00+07:00'),
(3, 171, N'Bai tap tu luan #3 - Figma UI/UX', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-07T08:00:00+07:00', 'DRAFT', 9, '2026-03-24T08:00:00+07:00'),
(4, NULL, N'Bai tap tu luan #4 - Ky Nang Thuyet Trinh', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-08T08:00:00+07:00', 'DRAFT', 10, '2026-03-25T08:00:00+07:00'),
(5, 197, N'Bai tap tu luan #5 - Quan Ly Thoi Gian', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-09T08:00:00+07:00', 'DRAFT', 11, '2026-03-26T08:00:00+07:00'),
(6, NULL, N'Bai tap tu luan #6 - Tu Duy Phan Bien', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-10T08:00:00+07:00', 'DRAFT', 12, '2026-03-27T08:00:00+07:00'),
(7, 151, N'Bai tap tu luan #7 - Photoshop Can Ban', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-11T08:00:00+07:00', 'DRAFT', 19, '2026-03-28T08:00:00+07:00'),
(8, NULL, N'Bai tap tu luan #8 - Illustrator Nang Cao', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-12T08:00:00+07:00', 'DRAFT', 20, '2026-03-29T08:00:00+07:00'),
(9, 177, N'Bai tap tu luan #9 - Figma UI/UX', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-13T08:00:00+07:00', 'DRAFT', 21, '2026-03-30T08:00:00+07:00'),
(10, NULL, N'Bai tap tu luan #10 - Ky Nang Thuyet Trinh', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-14T08:00:00+07:00', 'DRAFT', 22, '2026-03-31T08:00:00+07:00'),
(11, 203, N'Bai tap tu luan #11 - Quan Ly Thoi Gian', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-15T08:00:00+07:00', 'DRAFT', 23, '2026-04-01T08:00:00+07:00'),
(12, NULL, N'Bai tap tu luan #12 - Tu Duy Phan Bien', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-16T08:00:00+07:00', 'DRAFT', 24, '2026-04-02T08:00:00+07:00'),
(13, 145, N'Bai tap tu luan #13 - Photoshop Can Ban', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-17T08:00:00+07:00', 'DRAFT', 7, '2026-04-03T08:00:00+07:00'),
(14, NULL, N'Bai tap tu luan #14 - Illustrator Nang Cao', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-18T08:00:00+07:00', 'DRAFT', 8, '2026-04-04T08:00:00+07:00'),
(15, 171, N'Bai tap tu luan #15 - Figma UI/UX', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-19T08:00:00+07:00', 'DRAFT', 9, '2026-04-05T08:00:00+07:00'),
(16, NULL, N'Bai tap tu luan #16 - Ky Nang Thuyet Trinh', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-20T08:00:00+07:00', 'DRAFT', 10, '2026-04-06T08:00:00+07:00'),
(17, 197, N'Bai tap tu luan #17 - Quan Ly Thoi Gian', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-21T08:00:00+07:00', 'DRAFT', 11, '2026-04-07T08:00:00+07:00'),
(18, NULL, N'Bai tap tu luan #18 - Tu Duy Phan Bien', N'De bai: hay trinh bay quan diem cua ban ve chu de da hoc trong module nay (toi thieu 300 tu).', 10, '2026-04-22T08:00:00+07:00', 'DRAFT', 12, '2026-04-08T08:00:00+07:00');
GO

-- assignment_rubric_criterion: 54 rows
INSERT INTO assignment_rubric_criterion (assignment_id, name, max_score, weight_percent, order_no) VALUES
(1, N'Cau Truc (Structure)', 10, 40, 1),
(1, N'Van Phong (Style)', 10, 30, 2),
(1, N'Lap Luan (Argumentation)', 10, 30, 3),
(2, N'Cau Truc (Structure)', 10, 40, 1),
(2, N'Van Phong (Style)', 10, 30, 2),
(2, N'Lap Luan (Argumentation)', 10, 30, 3),
(3, N'Cau Truc (Structure)', 10, 40, 1),
(3, N'Van Phong (Style)', 10, 30, 2),
(3, N'Lap Luan (Argumentation)', 10, 30, 3),
(4, N'Cau Truc (Structure)', 10, 40, 1),
(4, N'Van Phong (Style)', 10, 30, 2),
(4, N'Lap Luan (Argumentation)', 10, 30, 3),
(5, N'Cau Truc (Structure)', 10, 40, 1),
(5, N'Van Phong (Style)', 10, 30, 2),
(5, N'Lap Luan (Argumentation)', 10, 30, 3),
(6, N'Cau Truc (Structure)', 10, 40, 1),
(6, N'Van Phong (Style)', 10, 30, 2),
(6, N'Lap Luan (Argumentation)', 10, 30, 3),
(7, N'Cau Truc (Structure)', 10, 40, 1),
(7, N'Van Phong (Style)', 10, 30, 2),
(7, N'Lap Luan (Argumentation)', 10, 30, 3),
(8, N'Cau Truc (Structure)', 10, 40, 1),
(8, N'Van Phong (Style)', 10, 30, 2),
(8, N'Lap Luan (Argumentation)', 10, 30, 3),
(9, N'Cau Truc (Structure)', 10, 40, 1),
(9, N'Van Phong (Style)', 10, 30, 2),
(9, N'Lap Luan (Argumentation)', 10, 30, 3),
(10, N'Cau Truc (Structure)', 10, 40, 1),
(10, N'Van Phong (Style)', 10, 30, 2),
(10, N'Lap Luan (Argumentation)', 10, 30, 3),
(11, N'Cau Truc (Structure)', 10, 40, 1),
(11, N'Van Phong (Style)', 10, 30, 2),
(11, N'Lap Luan (Argumentation)', 10, 30, 3),
(12, N'Cau Truc (Structure)', 10, 40, 1),
(12, N'Van Phong (Style)', 10, 30, 2),
(12, N'Lap Luan (Argumentation)', 10, 30, 3),
(13, N'Cau Truc (Structure)', 10, 40, 1),
(13, N'Van Phong (Style)', 10, 30, 2),
(13, N'Lap Luan (Argumentation)', 10, 30, 3),
(14, N'Cau Truc (Structure)', 10, 40, 1),
(14, N'Van Phong (Style)', 10, 30, 2),
(14, N'Lap Luan (Argumentation)', 10, 30, 3),
(15, N'Cau Truc (Structure)', 10, 40, 1),
(15, N'Van Phong (Style)', 10, 30, 2),
(15, N'Lap Luan (Argumentation)', 10, 30, 3),
(16, N'Cau Truc (Structure)', 10, 40, 1),
(16, N'Van Phong (Style)', 10, 30, 2),
(16, N'Lap Luan (Argumentation)', 10, 30, 3),
(17, N'Cau Truc (Structure)', 10, 40, 1),
(17, N'Van Phong (Style)', 10, 30, 2);
INSERT INTO assignment_rubric_criterion (assignment_id, name, max_score, weight_percent, order_no) VALUES
(17, N'Lap Luan (Argumentation)', 10, 30, 3),
(18, N'Cau Truc (Structure)', 10, 40, 1),
(18, N'Van Phong (Style)', 10, 30, 2),
(18, N'Lap Luan (Argumentation)', 10, 30, 3);
GO

-- Cap nhat trang thai cuoi cung cho assignment (sau khi rubric da du 100%),
-- tranh vi pham trigger trg_rubric_weight_check trong luc insert tung tieu chi.
UPDATE assignment SET status = 'PUBLISHED' WHERE id = 2;
UPDATE assignment SET status = 'CLOSED' WHERE id = 3;
UPDATE assignment SET status = 'PUBLISHED' WHERE id = 5;
UPDATE assignment SET status = 'CLOSED' WHERE id = 6;
UPDATE assignment SET status = 'PUBLISHED' WHERE id = 8;
UPDATE assignment SET status = 'CLOSED' WHERE id = 9;
UPDATE assignment SET status = 'PUBLISHED' WHERE id = 11;
UPDATE assignment SET status = 'CLOSED' WHERE id = 12;
UPDATE assignment SET status = 'PUBLISHED' WHERE id = 14;
UPDATE assignment SET status = 'CLOSED' WHERE id = 15;
UPDATE assignment SET status = 'PUBLISHED' WHERE id = 17;
UPDATE assignment SET status = 'CLOSED' WHERE id = 18;
GO

-- submission: 24 rows
INSERT INTO submission (assignment_id, student_id, content, file_url, final_score, ai_score, feedback, status, graded_by, graded_at, submitted_at) VALUES
(2, 25, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 7, NULL, 'AI_GRADED', NULL, NULL, '2026-04-17T08:00:00+07:00'),
(2, 26, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 8, 8, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 21, '2026-04-28T08:00:00+07:00', '2026-04-18T08:00:00+07:00'),
(3, 27, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-04-19T08:00:00+07:00'),
(3, 28, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 6, NULL, 'AI_GRADED', NULL, NULL, '2026-04-20T08:00:00+07:00'),
(5, 29, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 7, 7, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 24, '2026-05-01T08:00:00+07:00', '2026-04-21T08:00:00+07:00'),
(5, 30, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-04-22T08:00:00+07:00'),
(6, 31, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 9, NULL, 'AI_GRADED', NULL, NULL, '2026-04-23T08:00:00+07:00'),
(6, 32, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 6, 6, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 21, '2026-05-04T08:00:00+07:00', '2026-04-24T08:00:00+07:00'),
(8, 33, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-04-25T08:00:00+07:00'),
(8, 34, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 8, NULL, 'AI_GRADED', NULL, NULL, '2026-04-26T08:00:00+07:00'),
(9, 35, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 9, 9, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 24, '2026-05-07T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(9, 36, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-04-28T08:00:00+07:00'),
(11, 37, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 7, NULL, 'AI_GRADED', NULL, NULL, '2026-04-29T08:00:00+07:00'),
(11, 38, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 8, 8, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 21, '2026-05-10T08:00:00+07:00', '2026-04-30T08:00:00+07:00'),
(12, 39, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-05-01T08:00:00+07:00'),
(12, 40, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 6, NULL, 'AI_GRADED', NULL, NULL, '2026-05-02T08:00:00+07:00'),
(14, 41, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 7, 7, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 24, '2026-05-13T08:00:00+07:00', '2026-05-03T08:00:00+07:00'),
(14, 42, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-05-04T08:00:00+07:00'),
(15, 43, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 9, NULL, 'AI_GRADED', NULL, NULL, '2026-05-05T08:00:00+07:00'),
(15, 44, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 6, 6, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 21, '2026-05-16T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(17, 45, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-05-07T08:00:00+07:00'),
(17, 46, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, 8, NULL, 'AI_GRADED', NULL, NULL, '2026-05-08T08:00:00+07:00'),
(18, 47, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, 9, 9, N'Bai lam tot, can bo sung them vi du thuc te.', 'GRADED', 24, '2026-05-19T08:00:00+07:00', '2026-05-09T08:00:00+07:00'),
(18, 48, N'Noi dung bai luan cua hoc vien: Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. Lap luan chi tiet ve chu de. ', NULL, NULL, NULL, NULL, 'SUBMITTED', NULL, NULL, '2026-05-10T08:00:00+07:00');
GO

-- submission_criterion_score: 48 rows
INSERT INTO submission_criterion_score (submission_id, criterion_id, ai_score, final_score, ai_feedback, teacher_feedback) VALUES
(1, 4, 7, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(1, 5, 7, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(1, 6, 7, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(2, 4, 8, 8, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(2, 5, 8, 8, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(2, 6, 8, 8, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(4, 7, 6, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(4, 8, 6, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(4, 9, 6, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(5, 13, 7, 7, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(5, 14, 7, 7, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(5, 15, 7, 7, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(7, 16, 9, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(7, 17, 9, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(7, 18, 9, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(8, 16, 6, 6, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(8, 17, 6, 6, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(8, 18, 6, 6, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(10, 22, 8, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(10, 23, 8, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(10, 24, 8, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(11, 25, 9, 9, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(11, 26, 9, 9, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(11, 27, 9, 9, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(13, 31, 7, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(13, 32, 7, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(13, 33, 7, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(14, 31, 8, 8, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(14, 32, 8, 8, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(14, 33, 8, 8, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(16, 34, 6, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(16, 35, 6, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(16, 36, 6, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(17, 40, 7, 7, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(17, 41, 7, 7, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(17, 42, 7, 7, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(19, 43, 9, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(19, 44, 9, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(19, 45, 9, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(20, 43, 6, 6, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(20, 44, 6, 6, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(20, 45, 6, 6, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(22, 49, 8, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(22, 50, 8, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(22, 51, 8, NULL, N'AI: dap ung phan lon yeu cau tieu chi.', NULL),
(23, 52, 9, 9, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(23, 53, 9, 9, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.'),
(23, 54, 9, 9, N'AI: dap ung phan lon yeu cau tieu chi.', N'Dat yeu cau tieu chi nay.');
GO

-- quiz_attempt: 20 rows
INSERT INTO quiz_attempt (quiz_id, student_id, start_time, submit_time, score, status) VALUES
(1, 25, '2026-04-21T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(2, 26, '2026-04-22T08:00:00+07:00', '2026-04-22T08:30:00+07:00', 5, 'SUBMITTED'),
(3, 27, '2026-04-23T08:00:00+07:00', '2026-04-23T08:30:00+07:00', 6, 'SUBMITTED'),
(4, 28, '2026-04-24T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(5, 29, '2026-04-25T08:00:00+07:00', '2026-04-25T08:30:00+07:00', 8, 'SUBMITTED'),
(6, 30, '2026-04-26T08:00:00+07:00', '2026-04-26T08:30:00+07:00', 9, 'SUBMITTED'),
(7, 31, '2026-04-27T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(8, 32, '2026-04-28T08:00:00+07:00', '2026-04-28T08:30:00+07:00', 5, 'SUBMITTED'),
(9, 33, '2026-04-29T08:00:00+07:00', '2026-04-29T08:30:00+07:00', 6, 'SUBMITTED'),
(10, 34, '2026-04-30T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(11, 35, '2026-05-01T08:00:00+07:00', '2026-05-01T08:30:00+07:00', 8, 'SUBMITTED'),
(12, 36, '2026-05-02T08:00:00+07:00', '2026-05-02T08:30:00+07:00', 9, 'SUBMITTED'),
(13, 37, '2026-05-03T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(14, 38, '2026-05-04T08:00:00+07:00', '2026-05-04T08:30:00+07:00', 5, 'SUBMITTED'),
(15, 39, '2026-05-05T08:00:00+07:00', '2026-05-05T08:30:00+07:00', 6, 'SUBMITTED'),
(16, 40, '2026-05-06T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(17, 41, '2026-05-07T08:00:00+07:00', '2026-05-07T08:30:00+07:00', 8, 'SUBMITTED'),
(18, 42, '2026-05-08T08:00:00+07:00', '2026-05-08T08:30:00+07:00', 9, 'SUBMITTED'),
(19, 43, '2026-05-09T08:00:00+07:00', NULL, NULL, 'IN_PROGRESS'),
(20, 44, '2026-05-10T08:00:00+07:00', '2026-05-10T08:30:00+07:00', 5, 'SUBMITTED');
GO

-- quiz_attempt_answer: 65 rows
INSERT INTO quiz_attempt_answer (attempt_id, question_id, selected_option, is_correct) VALUES
(2, 7, 'A', 0),
(2, 8, 'A', 1),
(2, 9, 'B', 1),
(2, 10, 'D', 0),
(2, 11, 'D', 1),
(3, 13, 'B', 1),
(3, 14, 'C', 1),
(3, 15, 'A', 0),
(3, 16, 'A', 1),
(3, 17, 'B', 1),
(5, 25, 'C', 0),
(5, 26, 'C', 1),
(5, 27, 'D', 1),
(5, 28, 'B', 0),
(5, 29, 'B', 1),
(6, 31, 'D', 1),
(6, 32, 'A', 1),
(6, 33, 'C', 0),
(6, 34, 'C', 1),
(6, 35, 'D', 1),
(8, 43, 'A', 0),
(8, 44, 'A', 1),
(8, 45, 'B', 1),
(8, 46, 'D', 0),
(8, 47, 'D', 1),
(9, 49, 'B', 1),
(9, 50, 'C', 1),
(9, 51, 'A', 0),
(9, 52, 'A', 1),
(9, 53, 'B', 1),
(11, 61, 'C', 0),
(11, 62, 'C', 1),
(11, 63, 'D', 1),
(11, 64, 'B', 0),
(11, 65, 'B', 1),
(12, 67, 'D', 1),
(12, 68, 'A', 1),
(12, 69, 'C', 0),
(12, 70, 'C', 1),
(12, 71, 'D', 1),
(14, 79, 'A', 0),
(14, 80, 'A', 1),
(14, 81, 'B', 1),
(14, 82, 'D', 0),
(14, 83, 'D', 1),
(15, 85, 'B', 1),
(15, 86, 'C', 1),
(15, 87, 'A', 0),
(15, 88, 'A', 1),
(15, 89, 'B', 1);
INSERT INTO quiz_attempt_answer (attempt_id, question_id, selected_option, is_correct) VALUES
(17, 97, 'C', 0),
(17, 98, 'C', 1),
(17, 99, 'D', 1),
(17, 100, 'B', 0),
(17, 101, 'B', 1),
(18, 103, 'D', 1),
(18, 104, 'A', 1),
(18, 105, 'C', 0),
(18, 106, 'C', 1),
(18, 107, 'D', 1),
(20, 115, 'A', 0),
(20, 116, 'A', 1),
(20, 117, 'B', 1),
(20, 118, 'D', 0),
(20, 119, 'D', 1);
GO

-- learning_progress: 48 rows
INSERT INTO learning_progress (student_id, class_id, lesson_id, activity_type, completion_status, score, time_spent_seconds, attempt_count, last_active_at) VALUES
(25, 1, 2, 'LESSON', N'NOT_STARTED', NULL, 300, 1, '2026-04-26T08:00:00+07:00'),
(26, 2, 3, 'LESSON', N'IN_PROGRESS', NULL, 320, 2, '2026-04-27T08:00:00+07:00'),
(27, 3, 4, 'LESSON', N'COMPLETED', NULL, 340, 3, '2026-04-28T08:00:00+07:00'),
(28, 4, 5, 'LESSON', N'NOT_STARTED', NULL, 360, 4, '2026-04-29T08:00:00+07:00'),
(29, 5, 6, 'LESSON', N'IN_PROGRESS', NULL, 380, 1, '2026-04-30T08:00:00+07:00'),
(30, 6, 8, 'LESSON', N'COMPLETED', NULL, 400, 2, '2026-05-01T08:00:00+07:00'),
(31, 7, 9, 'LESSON', N'NOT_STARTED', NULL, 420, 3, '2026-05-02T08:00:00+07:00'),
(32, 8, 10, 'LESSON', N'IN_PROGRESS', NULL, 440, 4, '2026-05-03T08:00:00+07:00'),
(33, 9, 11, 'LESSON', N'COMPLETED', NULL, 460, 1, '2026-05-04T08:00:00+07:00'),
(34, 10, 12, 'LESSON', N'NOT_STARTED', NULL, 480, 2, '2026-05-05T08:00:00+07:00'),
(35, 11, 14, 'LESSON', N'IN_PROGRESS', NULL, 500, 3, '2026-04-26T08:00:00+07:00'),
(36, 12, 15, 'LESSON', N'COMPLETED', NULL, 520, 4, '2026-04-27T08:00:00+07:00'),
(37, 13, NULL, 'QUIZ', N'NOT_STARTED', 7, 540, 1, '2026-04-28T08:00:00+07:00'),
(38, 14, NULL, 'QUIZ', N'IN_PROGRESS', 8, 560, 2, '2026-04-29T08:00:00+07:00'),
(39, 15, NULL, 'QUIZ', N'COMPLETED', 9, 580, 3, '2026-04-30T08:00:00+07:00'),
(40, 16, NULL, 'QUIZ', N'NOT_STARTED', 5, 600, 4, '2026-05-01T08:00:00+07:00'),
(41, 17, NULL, 'QUIZ', N'IN_PROGRESS', 6, 620, 1, '2026-05-02T08:00:00+07:00'),
(42, 18, NULL, 'QUIZ', N'COMPLETED', 7, 640, 2, '2026-05-03T08:00:00+07:00'),
(43, 19, NULL, 'QUIZ', N'NOT_STARTED', 8, 660, 3, '2026-05-04T08:00:00+07:00'),
(44, 20, NULL, 'QUIZ', N'IN_PROGRESS', 9, 680, 4, '2026-05-05T08:00:00+07:00'),
(45, 21, NULL, 'QUIZ', N'COMPLETED', 5, 700, 1, '2026-04-26T08:00:00+07:00'),
(46, 22, NULL, 'QUIZ', N'NOT_STARTED', 6, 720, 2, '2026-04-27T08:00:00+07:00'),
(47, 23, NULL, 'QUIZ', N'IN_PROGRESS', 7, 740, 3, '2026-04-28T08:00:00+07:00'),
(48, 24, NULL, 'QUIZ', N'COMPLETED', 8, 760, 4, '2026-04-29T08:00:00+07:00'),
(49, 25, NULL, 'FLASHCARD', N'NOT_STARTED', NULL, 780, 1, '2026-04-30T08:00:00+07:00'),
(50, 26, NULL, 'FLASHCARD', N'IN_PROGRESS', NULL, 800, 2, '2026-05-01T08:00:00+07:00'),
(51, 27, NULL, 'FLASHCARD', N'COMPLETED', NULL, 820, 3, '2026-05-02T08:00:00+07:00'),
(52, 28, NULL, 'FLASHCARD', N'NOT_STARTED', NULL, 840, 4, '2026-05-03T08:00:00+07:00'),
(53, 29, NULL, 'FLASHCARD', N'IN_PROGRESS', NULL, 860, 1, '2026-05-04T08:00:00+07:00'),
(54, 30, NULL, 'FLASHCARD', N'COMPLETED', NULL, 880, 2, '2026-05-05T08:00:00+07:00'),
(25, 1, NULL, 'FLASHCARD', N'NOT_STARTED', NULL, 900, 3, '2026-04-26T08:00:00+07:00'),
(26, 2, NULL, 'FLASHCARD', N'IN_PROGRESS', NULL, 920, 4, '2026-04-27T08:00:00+07:00'),
(27, 3, NULL, 'FLASHCARD', N'COMPLETED', NULL, 940, 1, '2026-04-28T08:00:00+07:00'),
(28, 4, NULL, 'FLASHCARD', N'NOT_STARTED', NULL, 960, 2, '2026-04-29T08:00:00+07:00'),
(29, 5, NULL, 'FLASHCARD', N'IN_PROGRESS', NULL, 980, 3, '2026-04-30T08:00:00+07:00'),
(30, 6, NULL, 'FLASHCARD', N'COMPLETED', NULL, 1000, 4, '2026-05-01T08:00:00+07:00'),
(31, 7, NULL, 'ASSIGNMENT', N'NOT_STARTED', 6, 1020, 1, '2026-05-02T08:00:00+07:00'),
(32, 8, NULL, 'ASSIGNMENT', N'IN_PROGRESS', 7, 1040, 2, '2026-05-03T08:00:00+07:00'),
(33, 9, NULL, 'ASSIGNMENT', N'COMPLETED', 8, 1060, 3, '2026-05-04T08:00:00+07:00'),
(34, 10, NULL, 'ASSIGNMENT', N'NOT_STARTED', 9, 1080, 4, '2026-05-05T08:00:00+07:00'),
(35, 11, NULL, 'ASSIGNMENT', N'IN_PROGRESS', 5, 1100, 1, '2026-04-26T08:00:00+07:00'),
(36, 12, NULL, 'ASSIGNMENT', N'COMPLETED', 6, 1120, 2, '2026-04-27T08:00:00+07:00'),
(37, 13, NULL, 'ASSIGNMENT', N'NOT_STARTED', 7, 1140, 3, '2026-04-28T08:00:00+07:00'),
(38, 14, NULL, 'ASSIGNMENT', N'IN_PROGRESS', 8, 1160, 4, '2026-04-29T08:00:00+07:00'),
(39, 15, NULL, 'ASSIGNMENT', N'COMPLETED', 9, 1180, 1, '2026-04-30T08:00:00+07:00'),
(40, 16, NULL, 'ASSIGNMENT', N'NOT_STARTED', 5, 1200, 2, '2026-05-01T08:00:00+07:00'),
(41, 17, NULL, 'ASSIGNMENT', N'IN_PROGRESS', 6, 1220, 3, '2026-05-02T08:00:00+07:00'),
(42, 18, NULL, 'ASSIGNMENT', N'COMPLETED', 7, 1240, 4, '2026-05-03T08:00:00+07:00');
GO

-- ai_request: 40 rows
INSERT INTO ai_request (requester_id, task_type, source_ref_type, source_ref_id, status, created_at) VALUES
(7, 'GEN_QUIZ', N'LESSON', 1, 'PENDING', '2026-04-11T08:00:00+07:00'),
(8, 'GEN_FLASHCARD', N'LESSON', 2, 'SUCCESS', '2026-04-12T08:00:00+07:00'),
(9, 'EXPAND_OUTLINE', N'LESSON', 3, 'FAILED', '2026-04-13T08:00:00+07:00'),
(10, 'SUMMARIZE_VIDEO', N'LESSON', 4, 'TIMEOUT', '2026-04-14T08:00:00+07:00'),
(11, 'GRADE_ESSAY', N'SUBMISSION', 5, 'PENDING', '2026-04-15T08:00:00+07:00'),
(12, 'GEN_QUIZ', N'LESSON', 6, 'SUCCESS', '2026-04-16T08:00:00+07:00'),
(19, 'GEN_FLASHCARD', N'LESSON', 7, 'FAILED', '2026-04-17T08:00:00+07:00'),
(20, 'EXPAND_OUTLINE', N'LESSON', 8, 'TIMEOUT', '2026-04-18T08:00:00+07:00'),
(21, 'SUMMARIZE_VIDEO', N'LESSON', 9, 'PENDING', '2026-04-19T08:00:00+07:00'),
(22, 'GRADE_ESSAY', N'SUBMISSION', 10, 'SUCCESS', '2026-04-20T08:00:00+07:00'),
(23, 'GEN_QUIZ', N'LESSON', 11, 'FAILED', '2026-04-21T08:00:00+07:00'),
(24, 'GEN_FLASHCARD', N'LESSON', 12, 'TIMEOUT', '2026-04-22T08:00:00+07:00'),
(7, 'EXPAND_OUTLINE', N'LESSON', 13, 'PENDING', '2026-04-23T08:00:00+07:00'),
(8, 'SUMMARIZE_VIDEO', N'LESSON', 14, 'SUCCESS', '2026-04-24T08:00:00+07:00'),
(9, 'GRADE_ESSAY', N'SUBMISSION', 15, 'FAILED', '2026-04-25T08:00:00+07:00'),
(10, 'GEN_QUIZ', N'LESSON', 16, 'TIMEOUT', '2026-04-26T08:00:00+07:00'),
(11, 'GEN_FLASHCARD', N'LESSON', 17, 'PENDING', '2026-04-27T08:00:00+07:00'),
(12, 'EXPAND_OUTLINE', N'LESSON', 18, 'SUCCESS', '2026-04-28T08:00:00+07:00'),
(19, 'SUMMARIZE_VIDEO', N'LESSON', 19, 'FAILED', '2026-04-29T08:00:00+07:00'),
(20, 'GRADE_ESSAY', N'SUBMISSION', 20, 'TIMEOUT', '2026-04-30T08:00:00+07:00'),
(21, 'GEN_QUIZ', N'LESSON', 21, 'PENDING', '2026-05-01T08:00:00+07:00'),
(22, 'GEN_FLASHCARD', N'LESSON', 22, 'SUCCESS', '2026-05-02T08:00:00+07:00'),
(23, 'EXPAND_OUTLINE', N'LESSON', 23, 'FAILED', '2026-05-03T08:00:00+07:00'),
(24, 'SUMMARIZE_VIDEO', N'LESSON', 24, 'TIMEOUT', '2026-05-04T08:00:00+07:00'),
(7, 'GRADE_ESSAY', N'SUBMISSION', 25, 'PENDING', '2026-05-05T08:00:00+07:00'),
(8, 'GEN_QUIZ', N'LESSON', 26, 'SUCCESS', '2026-05-06T08:00:00+07:00'),
(9, 'GEN_FLASHCARD', N'LESSON', 27, 'FAILED', '2026-05-07T08:00:00+07:00'),
(10, 'EXPAND_OUTLINE', N'LESSON', 28, 'TIMEOUT', '2026-05-08T08:00:00+07:00'),
(11, 'SUMMARIZE_VIDEO', N'LESSON', 29, 'PENDING', '2026-05-09T08:00:00+07:00'),
(12, 'GRADE_ESSAY', N'SUBMISSION', 30, 'SUCCESS', '2026-05-10T08:00:00+07:00'),
(19, 'GEN_QUIZ', N'LESSON', 31, 'FAILED', '2026-05-11T08:00:00+07:00'),
(20, 'GEN_FLASHCARD', N'LESSON', 32, 'TIMEOUT', '2026-05-12T08:00:00+07:00'),
(21, 'EXPAND_OUTLINE', N'LESSON', 33, 'PENDING', '2026-05-13T08:00:00+07:00'),
(22, 'SUMMARIZE_VIDEO', N'LESSON', 34, 'SUCCESS', '2026-05-14T08:00:00+07:00'),
(23, 'GRADE_ESSAY', N'SUBMISSION', 35, 'FAILED', '2026-05-15T08:00:00+07:00'),
(24, 'GEN_QUIZ', N'LESSON', 36, 'TIMEOUT', '2026-05-16T08:00:00+07:00'),
(7, 'GEN_FLASHCARD', N'LESSON', 37, 'PENDING', '2026-05-17T08:00:00+07:00'),
(8, 'EXPAND_OUTLINE', N'LESSON', 38, 'SUCCESS', '2026-05-18T08:00:00+07:00'),
(9, 'SUMMARIZE_VIDEO', N'LESSON', 39, 'FAILED', '2026-05-19T08:00:00+07:00'),
(10, 'GRADE_ESSAY', N'SUBMISSION', 40, 'TIMEOUT', '2026-05-20T08:00:00+07:00');
GO

-- ai_response: 10 rows
INSERT INTO ai_response (ai_request_id, model, generated_content, token_consumed, processing_time_ms, created_at) VALUES
(2, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 500, 1200, '2026-04-12T08:00:00+07:00'),
(6, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 530, 1300, '2026-04-13T08:00:00+07:00'),
(10, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 560, 1400, '2026-04-14T08:00:00+07:00'),
(14, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 590, 1500, '2026-04-15T08:00:00+07:00'),
(18, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 620, 1600, '2026-04-16T08:00:00+07:00'),
(22, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 650, 1700, '2026-04-17T08:00:00+07:00'),
(26, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 680, 1800, '2026-04-18T08:00:00+07:00'),
(30, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 710, 1900, '2026-04-19T08:00:00+07:00'),
(34, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 740, 2000, '2026-04-20T08:00:00+07:00'),
(38, N'gemini-2.5-pro', N'{"result":"noi dung AI sinh ra mau"}', 770, 2100, '2026-04-21T08:00:00+07:00');
GO

-- ai_quota: 24 rows
INSERT INTO ai_quota (user_id, month_year, quota_limit, used_count) VALUES
(7, '2026-05', 50, 10),
(8, '2026-05', 50, 11),
(9, '2026-05', 50, 12),
(10, '2026-05', 50, 13),
(11, '2026-05', 50, 14),
(12, '2026-05', 50, 15),
(19, '2026-05', 50, 16),
(20, '2026-05', 50, 17),
(21, '2026-05', 50, 18),
(22, '2026-05', 50, 19),
(23, '2026-05', 50, 20),
(24, '2026-05', 50, 21),
(7, '2026-06', 50, 10),
(8, '2026-06', 50, 11),
(9, '2026-06', 50, 12),
(10, '2026-06', 50, 13),
(11, '2026-06', 50, 14),
(12, '2026-06', 50, 15),
(19, '2026-06', 50, 16),
(20, '2026-06', 50, 17),
(21, '2026-06', 50, 18),
(22, '2026-06', 50, 19),
(23, '2026-06', 50, 20),
(24, '2026-06', 50, 21);
GO

-- knowledge_gap_analysis: 10 rows
INSERT INTO knowledge_gap_analysis (student_id, weak_topics, roadmap, generated_at, cache_expires_at) VALUES
(25, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-04-30T08:00:00+07:00', '2026-05-02T08:00:00+07:00'),
(26, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-01T08:00:00+07:00', '2026-04-29T08:00:00+07:00'),
(27, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-02T08:00:00+07:00', '2026-05-04T08:00:00+07:00'),
(28, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-03T08:00:00+07:00', '2026-04-27T08:00:00+07:00'),
(29, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-04T08:00:00+07:00', '2026-05-06T08:00:00+07:00'),
(30, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-05T08:00:00+07:00', '2026-04-25T08:00:00+07:00'),
(31, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-06T08:00:00+07:00', '2026-05-08T08:00:00+07:00'),
(32, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-07T08:00:00+07:00', '2026-04-23T08:00:00+07:00'),
(33, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-08T08:00:00+07:00', '2026-05-10T08:00:00+07:00'),
(34, N'{"weak_topics":["Chu de A","Chu de B"]}', N'{"roadmap":["Buoc 1: On lai ly thuyet","Buoc 2: Lam bai tap","Buoc 3: Kiem tra lai"]}', '2026-05-09T08:00:00+07:00', '2026-04-21T08:00:00+07:00');
GO

-- system_setting: 10 rows
INSERT INTO system_setting (setting_key, setting_type, setting_value, display_order, description, is_active, updated_by, updated_at) VALUES
(N'CFG-B01', N'FILE_SIZE_MB', N'20', 0, N'Gioi han dung luong file dinh kem (MB)', 1, 1, '2026-03-02T08:00:00+07:00'),
(N'CFG-B02', N'AI_GEN_MAX_ITEMS', N'20', 1, N'So luong toi da AI sinh moi lan (cau hoi/flashcard)', 1, 2, '2026-03-03T08:00:00+07:00'),
(N'CFG-B09', N'AUDIT_LOG_RETENTION_DAYS', N'365', 2, N'Thoi gian luu giu audit log (ngay)', 1, 3, '2026-03-04T08:00:00+07:00'),
(N'CFG-CLASS-CAPACITY-MAX', N'MAX_CLASS_CAPACITY', N'500', 3, N'Si so toi da 1 lop hoc', 1, 4, '2026-03-05T08:00:00+07:00'),
(N'CFG-GUEST-QUESTION-LIMIT', N'GUEST_TRIAL_QUESTIONS', N'10', 4, N'So cau hoi mau toi da cho Guest', 1, 5, '2026-03-06T08:00:00+07:00'),
(N'CFG-GUEST-FLASHCARD-LIMIT', N'GUEST_TRIAL_FLASHCARDS', N'5', 5, N'So flashcard mau toi da cho Guest', 1, 6, '2026-03-07T08:00:00+07:00'),
(N'CFG-PACKAGE-GRACE-DAYS', N'PACKAGE_RENEWAL_GRACE_DAYS', N'3', 6, N'So ngay gia han khi goi het han', 1, 1, '2026-03-08T08:00:00+07:00'),
(N'CFG-FAILED-LOGIN-LIMIT', N'MAX_FAILED_LOGIN', N'5', 7, N'So lan dang nhap sai toi da truoc khi khoa tai khoan', 1, 2, '2026-03-09T08:00:00+07:00'),
(N'CFG-AI-TIMEOUT-SEC', N'AI_TIMEOUT_SECONDS', N'30', 8, N'Thoi gian cho toi da khi goi AI Engine (giay)', 0, 3, '2026-03-10T08:00:00+07:00'),
(N'CFG-PAYMENT-WEBHOOK-RETRY', N'PAYMENT_WEBHOOK_RETRY_COUNT', N'3', 9, N'So lan retry khi webhook thanh toan loi tam thoi', 0, 4, '2026-03-11T08:00:00+07:00');
GO

-- audit_log: 36 rows
INSERT INTO audit_log (actor_id, action_type, resource_type, resource_id, metadata, created_at) VALUES
(1, N'COURSE_PUBLISHED', 'COURSE', 1, N'{"note":"audit seed record"}', '2026-04-01T08:00:00+07:00'),
(2, N'USER_STATUS_CHANGED', 'USER', 2, N'{"note":"audit seed record"}', '2026-04-02T08:00:00+07:00'),
(3, N'PAYMENT_CONFIRMED', 'PAYMENT', 3, N'{"note":"audit seed record"}', '2026-04-03T08:00:00+07:00'),
(4, N'REFUND_APPROVED', 'REFUND_REQUEST', 4, N'{"note":"audit seed record"}', '2026-04-04T08:00:00+07:00'),
(5, N'ASSIGNMENT_PUBLISHED', 'ASSIGNMENT', 5, N'{"note":"audit seed record"}', '2026-04-05T08:00:00+07:00'),
(6, N'ENROLLMENT_CREATED', 'ENROLLMENT', 6, N'{"note":"audit seed record"}', '2026-04-06T08:00:00+07:00'),
(13, N'COURSE_PUBLISHED', 'COURSE', 7, N'{"note":"audit seed record"}', '2026-04-07T08:00:00+07:00'),
(14, N'USER_STATUS_CHANGED', 'USER', 8, N'{"note":"audit seed record"}', '2026-04-08T08:00:00+07:00'),
(15, N'PAYMENT_CONFIRMED', 'PAYMENT', 9, N'{"note":"audit seed record"}', '2026-04-09T08:00:00+07:00'),
(16, N'REFUND_APPROVED', 'REFUND_REQUEST', 10, N'{"note":"audit seed record"}', '2026-04-10T08:00:00+07:00'),
(17, N'ASSIGNMENT_PUBLISHED', 'ASSIGNMENT', 11, N'{"note":"audit seed record"}', '2026-04-11T08:00:00+07:00'),
(18, N'ENROLLMENT_CREATED', 'ENROLLMENT', 12, N'{"note":"audit seed record"}', '2026-04-12T08:00:00+07:00'),
(7, N'COURSE_PUBLISHED', 'COURSE', 13, N'{"note":"audit seed record"}', '2026-04-13T08:00:00+07:00'),
(8, N'USER_STATUS_CHANGED', 'USER', 14, N'{"note":"audit seed record"}', '2026-04-14T08:00:00+07:00'),
(9, N'PAYMENT_CONFIRMED', 'PAYMENT', 15, N'{"note":"audit seed record"}', '2026-04-15T08:00:00+07:00'),
(10, N'REFUND_APPROVED', 'REFUND_REQUEST', 16, N'{"note":"audit seed record"}', '2026-04-16T08:00:00+07:00'),
(11, N'ASSIGNMENT_PUBLISHED', 'ASSIGNMENT', 17, N'{"note":"audit seed record"}', '2026-04-17T08:00:00+07:00'),
(12, N'ENROLLMENT_CREATED', 'ENROLLMENT', 18, N'{"note":"audit seed record"}', '2026-04-18T08:00:00+07:00'),
(1, N'COURSE_PUBLISHED', 'COURSE', 19, N'{"note":"audit seed record"}', '2026-04-19T08:00:00+07:00'),
(2, N'USER_STATUS_CHANGED', 'USER', 20, N'{"note":"audit seed record"}', '2026-04-20T08:00:00+07:00'),
(3, N'PAYMENT_CONFIRMED', 'PAYMENT', 1, N'{"note":"audit seed record"}', '2026-04-21T08:00:00+07:00'),
(4, N'REFUND_APPROVED', 'REFUND_REQUEST', 2, N'{"note":"audit seed record"}', '2026-04-22T08:00:00+07:00'),
(5, N'ASSIGNMENT_PUBLISHED', 'ASSIGNMENT', 3, N'{"note":"audit seed record"}', '2026-04-23T08:00:00+07:00'),
(6, N'ENROLLMENT_CREATED', 'ENROLLMENT', 4, N'{"note":"audit seed record"}', '2026-04-24T08:00:00+07:00'),
(13, N'COURSE_PUBLISHED', 'COURSE', 5, N'{"note":"audit seed record"}', '2026-04-25T08:00:00+07:00'),
(14, N'USER_STATUS_CHANGED', 'USER', 6, N'{"note":"audit seed record"}', '2026-04-26T08:00:00+07:00'),
(15, N'PAYMENT_CONFIRMED', 'PAYMENT', 7, N'{"note":"audit seed record"}', '2026-04-27T08:00:00+07:00'),
(16, N'REFUND_APPROVED', 'REFUND_REQUEST', 8, N'{"note":"audit seed record"}', '2026-04-28T08:00:00+07:00'),
(17, N'ASSIGNMENT_PUBLISHED', 'ASSIGNMENT', 9, N'{"note":"audit seed record"}', '2026-04-29T08:00:00+07:00'),
(18, N'ENROLLMENT_CREATED', 'ENROLLMENT', 10, N'{"note":"audit seed record"}', '2026-04-30T08:00:00+07:00'),
(7, N'COURSE_PUBLISHED', 'COURSE', 11, N'{"note":"audit seed record"}', '2026-05-01T08:00:00+07:00'),
(8, N'USER_STATUS_CHANGED', 'USER', 12, N'{"note":"audit seed record"}', '2026-05-02T08:00:00+07:00'),
(9, N'PAYMENT_CONFIRMED', 'PAYMENT', 13, N'{"note":"audit seed record"}', '2026-05-03T08:00:00+07:00'),
(10, N'REFUND_APPROVED', 'REFUND_REQUEST', 14, N'{"note":"audit seed record"}', '2026-05-04T08:00:00+07:00'),
(11, N'ASSIGNMENT_PUBLISHED', 'ASSIGNMENT', 15, N'{"note":"audit seed record"}', '2026-05-05T08:00:00+07:00'),
(12, N'ENROLLMENT_CREATED', 'ENROLLMENT', 16, N'{"note":"audit seed record"}', '2026-05-06T08:00:00+07:00');
GO

-- notification: 36 rows
INSERT INTO notification (user_id, type, title, message, is_read, created_at) VALUES
(25, 'PAYMENT_SUCCESS', N'Thong bao: PAYMENT_SUCCESS', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-16T08:00:00+07:00'),
(26, 'ASSIGNMENT_GRADED', N'Thong bao: ASSIGNMENT_GRADED', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-17T08:00:00+07:00'),
(27, 'AI_CONTENT_READY', N'Thong bao: AI_CONTENT_READY', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-18T08:00:00+07:00'),
(28, 'CLASS_STARTING_SOON', N'Thong bao: CLASS_STARTING_SOON', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-19T08:00:00+07:00'),
(29, 'PACKAGE_EXPIRING', N'Thong bao: PACKAGE_EXPIRING', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-20T08:00:00+07:00'),
(30, 'REFUND_UPDATE', N'Thong bao: REFUND_UPDATE', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-21T08:00:00+07:00'),
(31, 'PAYMENT_SUCCESS', N'Thong bao: PAYMENT_SUCCESS', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-22T08:00:00+07:00'),
(32, 'ASSIGNMENT_GRADED', N'Thong bao: ASSIGNMENT_GRADED', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-23T08:00:00+07:00'),
(33, 'AI_CONTENT_READY', N'Thong bao: AI_CONTENT_READY', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-24T08:00:00+07:00'),
(34, 'CLASS_STARTING_SOON', N'Thong bao: CLASS_STARTING_SOON', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-25T08:00:00+07:00'),
(35, 'PACKAGE_EXPIRING', N'Thong bao: PACKAGE_EXPIRING', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-26T08:00:00+07:00'),
(36, 'REFUND_UPDATE', N'Thong bao: REFUND_UPDATE', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-27T08:00:00+07:00'),
(37, 'PAYMENT_SUCCESS', N'Thong bao: PAYMENT_SUCCESS', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-28T08:00:00+07:00'),
(38, 'ASSIGNMENT_GRADED', N'Thong bao: ASSIGNMENT_GRADED', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-04-29T08:00:00+07:00'),
(39, 'AI_CONTENT_READY', N'Thong bao: AI_CONTENT_READY', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-04-30T08:00:00+07:00'),
(40, 'CLASS_STARTING_SOON', N'Thong bao: CLASS_STARTING_SOON', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-01T08:00:00+07:00'),
(41, 'PACKAGE_EXPIRING', N'Thong bao: PACKAGE_EXPIRING', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-02T08:00:00+07:00'),
(42, 'REFUND_UPDATE', N'Thong bao: REFUND_UPDATE', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-03T08:00:00+07:00'),
(43, 'PAYMENT_SUCCESS', N'Thong bao: PAYMENT_SUCCESS', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-04T08:00:00+07:00'),
(44, 'ASSIGNMENT_GRADED', N'Thong bao: ASSIGNMENT_GRADED', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-05T08:00:00+07:00'),
(45, 'AI_CONTENT_READY', N'Thong bao: AI_CONTENT_READY', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-06T08:00:00+07:00'),
(46, 'CLASS_STARTING_SOON', N'Thong bao: CLASS_STARTING_SOON', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-07T08:00:00+07:00'),
(47, 'PACKAGE_EXPIRING', N'Thong bao: PACKAGE_EXPIRING', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-08T08:00:00+07:00'),
(48, 'REFUND_UPDATE', N'Thong bao: REFUND_UPDATE', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-09T08:00:00+07:00'),
(49, 'PAYMENT_SUCCESS', N'Thong bao: PAYMENT_SUCCESS', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-10T08:00:00+07:00'),
(50, 'ASSIGNMENT_GRADED', N'Thong bao: ASSIGNMENT_GRADED', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-11T08:00:00+07:00'),
(51, 'AI_CONTENT_READY', N'Thong bao: AI_CONTENT_READY', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-12T08:00:00+07:00'),
(52, 'CLASS_STARTING_SOON', N'Thong bao: CLASS_STARTING_SOON', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-13T08:00:00+07:00'),
(53, 'PACKAGE_EXPIRING', N'Thong bao: PACKAGE_EXPIRING', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-14T08:00:00+07:00'),
(54, 'REFUND_UPDATE', N'Thong bao: REFUND_UPDATE', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-15T08:00:00+07:00'),
(19, 'PAYMENT_SUCCESS', N'Thong bao: PAYMENT_SUCCESS', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-16T08:00:00+07:00'),
(20, 'ASSIGNMENT_GRADED', N'Thong bao: ASSIGNMENT_GRADED', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-17T08:00:00+07:00'),
(21, 'AI_CONTENT_READY', N'Thong bao: AI_CONTENT_READY', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-18T08:00:00+07:00'),
(22, 'CLASS_STARTING_SOON', N'Thong bao: CLASS_STARTING_SOON', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-19T08:00:00+07:00'),
(23, 'PACKAGE_EXPIRING', N'Thong bao: PACKAGE_EXPIRING', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 1, '2026-05-20T08:00:00+07:00'),
(24, 'REFUND_UPDATE', N'Thong bao: REFUND_UPDATE', N'Noi dung chi tiet thong bao gui toi nguoi dung.', 0, '2026-05-21T08:00:00+07:00');
GO

-- background_job_log: 18 rows
INSERT INTO background_job_log (job_name, status, started_at, finished_at, error_message) VALUES
(N'JOB-01-HealthCheck', 'RUNNING', '2026-04-21T08:00:00+07:00', NULL, NULL),
(N'JOB-02-CleanupLogs', 'RUNNING', '2026-04-22T08:00:00+07:00', NULL, NULL),
(N'JOB-03-RevokeSessions', 'RUNNING', '2026-04-23T08:00:00+07:00', NULL, NULL),
(N'JOB-04-ExpireEnrollment', 'RUNNING', '2026-04-24T08:00:00+07:00', NULL, NULL),
(N'JOB-01-HealthCheck', 'RUNNING', '2026-04-25T08:00:00+07:00', NULL, NULL),
(N'JOB-02-CleanupLogs', 'RUNNING', '2026-04-26T08:00:00+07:00', NULL, NULL),
(N'JOB-03-RevokeSessions', 'SUCCESS', '2026-04-27T08:00:00+07:00', '2026-04-27T08:05:00+07:00', NULL),
(N'JOB-04-ExpireEnrollment', 'SUCCESS', '2026-04-28T08:00:00+07:00', '2026-04-28T08:05:00+07:00', NULL),
(N'JOB-01-HealthCheck', 'SUCCESS', '2026-04-29T08:00:00+07:00', '2026-04-29T08:05:00+07:00', NULL),
(N'JOB-02-CleanupLogs', 'SUCCESS', '2026-04-30T08:00:00+07:00', '2026-04-30T08:05:00+07:00', NULL),
(N'JOB-03-RevokeSessions', 'SUCCESS', '2026-05-01T08:00:00+07:00', '2026-05-01T08:05:00+07:00', NULL),
(N'JOB-04-ExpireEnrollment', 'SUCCESS', '2026-05-02T08:00:00+07:00', '2026-05-02T08:05:00+07:00', NULL),
(N'JOB-01-HealthCheck', 'FAILED', '2026-05-03T08:00:00+07:00', '2026-05-03T08:05:00+07:00', N'Timeout khi goi dich vu ben ngoai.'),
(N'JOB-02-CleanupLogs', 'FAILED', '2026-05-04T08:00:00+07:00', '2026-05-04T08:05:00+07:00', N'Timeout khi goi dich vu ben ngoai.'),
(N'JOB-03-RevokeSessions', 'FAILED', '2026-05-05T08:00:00+07:00', '2026-05-05T08:05:00+07:00', N'Timeout khi goi dich vu ben ngoai.'),
(N'JOB-04-ExpireEnrollment', 'FAILED', '2026-05-06T08:00:00+07:00', '2026-05-06T08:05:00+07:00', N'Timeout khi goi dich vu ben ngoai.'),
(N'JOB-01-HealthCheck', 'FAILED', '2026-05-07T08:00:00+07:00', '2026-05-07T08:05:00+07:00', N'Timeout khi goi dich vu ben ngoai.'),
(N'JOB-02-CleanupLogs', 'FAILED', '2026-05-08T08:00:00+07:00', '2026-05-08T08:05:00+07:00', N'Timeout khi goi dich vu ben ngoai.');
GO

-- =====================================================================
-- HET SEED DATA
-- =====================================================================