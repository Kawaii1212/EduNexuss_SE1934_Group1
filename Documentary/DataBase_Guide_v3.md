**EduNexus --- Hướng dẫn Database cho Backend Team**

**Database:** Microsoft SQL Server 2019+ / Azure SQL (T-SQL) **File
schema:** EduNexus_Database_Full.sql (bao gồm CREATE TABLE + seed data)
**Đối tượng đọc:** Backend
Developer triển khai API theo từng actor (Admin, SME, Course Manager,
Teacher, Student, Guest)

**0. Changelog (07/2026)**

  ------------------------------------------------------------------------------------------------
  **Thay đổi**                          **Chi tiết**
  -------------------------------------- --------------------------------------------------------
  `ALTER TABLE assignment ADD lesson_id  Đã được tích hợp trực tiếp vào `CREATE TABLE assignment`
  BIGINT NULL REFERENCES lesson(id);`    trong file schema mới (không cần chạy ALTER riêng khi
                                          tạo DB mới). Cho phép 1 assignment liên kết **tùy
                                          chọn** tới đúng 1 `lesson` cụ thể trong course gốc mà
                                          class đang học — ví dụ bài tập cuối bài của 1 lesson —
                                          thay vì chỉ gắn chung với `class` như trước.
                                          `lesson_id = NULL` nếu assignment áp dụng chung cho cả
                                          class, không gắn với lesson cụ thể nào. Index mới:
                                          `idx_assignment_lesson`.

  Seed data đầy đủ                       File schema giờ có thêm phần **INSERT** cho toàn bộ 38
                                          bảng ở cuối file, đảm bảo mỗi giá trị trạng thái/loại
                                          (status, role, enrollment_type, difficulty...) có
                                          **tối thiểu 6 bản ghi**, và mỗi `module` có tối thiểu
                                          **6 lesson**. Xem mục 7 bên dưới để biết chi tiết số
                                          lượng và thứ tự chạy.
  ------------------------------------------------------------------------------------------------

**Lưu ý khi dùng `assignment.lesson_id`:**
- Khi tạo/sửa assignment ở SCR-11 (Create Essay Assignments), FE có thể cho SME/Teacher chọn
  "Áp dụng cho cả lớp" (lesson_id = NULL) hoặc "Gắn với 1 lesson cụ thể" (chọn lesson thuộc đúng
  course của class đó — Service Layer nên validate `lesson.module.course_id == class.course_id`,
  DB không tự enforce ràng buộc chéo bảng này).
- Không có CHECK constraint nào ràng buộc lesson phải cùng course với class — đây là rule nghiệp
  vụ cần xử lý ở Service Layer, tương tự các rule GB-01, GB-04 khác đã liệt kê ở mục 6.

**1. Tổng quan kỹ thuật --- Đọc trước khi code**

  -------------------------------------------------------------------------
  **Mục**       **Quy ước**           **Lý do**
  ------------- --------------------- -------------------------------------
  Loại DB       **SQL Server** (không Quyết định cuối theo backend stack
                phải                  thực tế
                PostgreSQL/MySQL)     

  Khoá chính    BIGINT IDENTITY(1,1)  Trừ user_session dùng
                --- tăng tự động      UNIQUEIDENTIFIER (GUID) vì là token,
                                      không cần lộ số thứ tự

  Kiểu          Toàn bộ text dùng     Bắt buộc để lưu tiếng Việt đúng
  chữ/Unicode   NVARCHAR (không phải  (NFR-I02) --- **khi insert string
                VARCHAR)              luôn nhớ thêm tiền tố N\'\...\'**
                                      trong T-SQL thuần, hoặc dùng
                                      parameterized query (ORM tự xử lý)

  Enum          Không có kiểu ENUM    SQL Server không hỗ trợ ENUM. Giá trị
                thật --- dùng         hợp lệ xem mục 5
                NVARCHAR + CHECK      
                constraint            

  Thời gian     DATETIMEOFFSET(3),    Có time zone, tránh lệch giờ khi
                default               server/client khác zone
                SYSDATETIMEOFFSET()   

  Boolean       BIT (1/0), không phải Khi code C#/Java/Node phải map đúng
                true/false            kiểu bool ↔ bit

  JSON          Cột NVARCHAR(MAX) +   SQL Server không có JSONB thật; muốn
                CHECK (ISJSON(col)=1) query theo field trong JSON dùng hàm
                                      JSON_VALUE() / JSON_QUERY()

  Soft delete   Cột deleted_at        **API KHÔNG xoá cứng (DELETE)** các
                (users, course)       bảng có cột này --- chỉ UPDATE
                                      deleted_at = SYSDATETIMEOFFSET(). Mọi
                                      câu SELECT mặc định phải lọc WHERE
                                      deleted_at IS NULL

  Xoá dữ liệu   Tất cả FK đặt NO      SQL Server không cho phép nhiều
  liên quan     ACTION (không         \"cascade path\" hội tụ (schema này
  (FK)          cascade)              có nhiều nhánh hội tụ kiểu kim cương)
                                      → **Backend phải tự xử lý thứ tự
                                      xoá/dọn dữ liệu con ở Service
                                      Layer**, hoặc ưu tiên soft delete
                                      thay vì xoá cứng

  Trigger tự    3 trigger chặn nghiệp Khi API insert/update mà vi phạm rule
  động          vụ (mục 6)            sẽ nhận lỗi SQL (không phải lỗi do
                                      code backend) --- xem mục 6 để biết
                                      cách bắt lỗi đúng
  -------------------------------------------------------------------------

**2. Bản đồ Module → Bảng**

  --------------------------------------------------------------------------
  **Module**     **Bảng**
  -------------- -----------------------------------------------------------
  **User         users, user_oauth_identity, user_session, login_history
  Manager**      

  **Content      course_group, course_group_member, course,
  Manager**      course_content_version, module, lesson, lesson_view_event,
                 question, quiz, quiz_question, flashcard_deck, flashcard,
                 flashcard_review_log, assignment,
                 assignment_rubric_criterion, class_material

  **Learning**   quiz_attempt, quiz_attempt_answer, submission,
                 submission_criterion_score, learning_progress

  **ClassRoom &  class, enrollment, subscription_package, payment,
  Business**     refund_request

  **AI           ai_request, ai_response, ai_quota, knowledge_gap_analysis
  Subsystem**    

  **System       system_setting, audit_log, notification, background_job_log
  Admin**        
  --------------------------------------------------------------------------

**3. Tài liệu theo Actor**

Ký hiệu quyền: **C**reate · **R**ead · **U**pdate · **D**elete (D luôn
hiểu là *soft delete* nếu bảng có deleted_at, ngược lại nghĩa là xoá
cứng có kiểm soát).

**🔵 ADMIN**

**Vai trò:** Toàn quyền hệ thống --- tạo account nội bộ, tạo
Course/Course Group, duyệt nội dung, xử lý leo thang, cấu hình hệ thống,
xem mọi báo cáo.

  -------------------------------------------------------------------------------
  **Bảng**               **Quyền**   **API/Use case liên quan**
  ---------------------- ----------- --------------------------------------------
  users                  C, R, U,    Tạo account SME/Teacher/Course Manager (UC:
                         D(soft)     chỉ Admin tạo được --- KHÔNG cho phép các
                                     role nội bộ tự đăng ký, validate ở Service
                                     Layer chứ DB không tự chặn được).
                                     Lock/unlock account → update status,
                                     locked_until. SCR-38/39/40

  course_group,          C, R, U     Tạo nhóm khoá học, phân công Course
  course_group_member                Manager/SME (role_in_group). SCR-23

  course                 C, R, U     Khởi tạo khoá học, set
                                     status=\'PENDING_REVIEW\' → duyệt thành
                                     \'PUBLISHED\' (trigger
                                     trg_course_publishable sẽ tự chặn nếu chưa
                                     đủ module/lesson). SCR-05

  class,                 C, R, U     Khi lớp miễn phí: Admin tự thêm enrollment
  subscription_package               cho học viên (UC-18-02)

  refund_request         R, U        Duyệt/từ chối hoàn tiền (cùng quyền với
                                     Course Manager). SCR-29

  system_setting         C, R, U     Cấu hình hạn mức file, AI quota\...
                                     SCR-38→43 (màn hình bị gắn nhãn sai trong
                                     DMD gốc, xem design doc mục Mâu thuẫn #3)

  ai_quota               C, R, U     Thiết lập hạn mức AI hàng tháng theo từng
                                     user (GB-02)

  audit_log              R only      Xem log --- **API không cho phép
                                     UPDATE/DELETE bảng này dù là Admin**
                                     (NFR-S05, nên DENY quyền ở DB role luôn,
                                     không chỉ chặn ở code)

  login_history          R           SCR-43

  background_job_log     R           Giám sát JOB-01→04

  Tất cả view v\_\*      R           Xem báo cáo tổng hợp toàn hệ thống
  -------------------------------------------------------------------------------

**🟢 SME (Subject Matter Expert)**

**Vai trò:** Soạn nội dung gốc của khoá học được phân công (qua
course_group_member). Chỉ thao tác trong group được gán (**GB-01 ---
phải tự check ở Service Layer**, DB không tự enforce được).

  ---------------------------------------------------------------------------------
  **Bảng**                      **Quyền**   **API/Use case liên quan**
  ----------------------------- ----------- ---------------------------------------
  course                        R, U (chỉ   Soạn outline, gửi publish (status →
                                course      PENDING_REVIEW hoặc PUBLISHED tuỳ cấu
                                trong group hình ở system_setting)
                                được gán)   

  module, lesson                C, R, U     SCR-05, SCR-06, SCR-06-a (AI hỗ trợ mở
                                            rộng outline → ghi lesson.content,
                                            lesson.summary)

  course_content_version        C (tự động  Lưu snapshot mỗi lần \"mở khoá tạm
                                khi sửa     thời\" sửa nội dung đã xuất bản (SC-01
                                course đã   bước 9)
                                publish)    

  question                      C, R, U     Ngân hàng câu hỏi --- SCR-07, duyệt câu
                                            AI sinh (SCR-08: update status,
                                            approved_by)

  quiz, quiz_question           C, R, U     Gom câu hỏi thành quiz chính thức
                                            (không phải quiz tự sinh của Student)

  flashcard_deck, flashcard     C, R, U     SCR-09, duyệt flashcard AI (SCR-10)

  assignment,                   C, R, U     SCR-11 --- **Lưu ý:** khi set
  assignment_rubric_criterion               assignment.status=\'PUBLISHED\',
                                            trigger trg_rubric_weight_check sẽ chặn
                                            nếu tổng weight_percent ≠ 100.
                                            **(Mới 07/2026)** assignment.lesson_id
                                            (NULL được) --- gắn assignment với 1
                                            lesson cụ thể nếu cần, thay vì chỉ
                                            gắn chung class.

  ai_request, ai_response       C, R        Mọi lần gọi AI (gen
                                            quiz/flashcard/expand outline) phải
                                            insert 1 row ai_request trước, ghi
                                            ai_response sau khi nhận kết quả ---
                                            **đồng thời tăng ai_quota.used_count**
                                            (transaction, kiểm tra used_count \<
                                            quota_limit trước khi gọi AI thật)

  v_content_quality_report      R           SCR-36
  ---------------------------------------------------------------------------------

**🟠 COURSE MANAGER**

**Vai trò:** Vận hành kinh doanh --- giá, lớp học, gói đăng ký, doanh
thu, hoàn tiền --- **chỉ trong Course Group được phân công**.

  --------------------------------------------------------------------------------
  **Bảng**               **Quyền**   **API/Use case liên quan**
  ---------------------- ----------- ---------------------------------------------
  course                 R, U (chỉ   UC-19 Quản lý giá (H1)
                         field       
                         price,      
                         trong group 
                         được gán)   

  class                  C, R, U     SCR-21/22 --- tạo lớp, gán teacher_id, sửa
                                     capacity, status (UC-17-01→06)

  class_material         R           Chỉ xem, không tạo (Teacher mới tạo)

  subscription_package   C, R, U,    SCR-23/25 --- gói H3. UC-20 (tạo/sửa/kích
                         D(soft qua  hoạt/vô hiệu hoá)
                         status)     

  enrollment             R, U        Xem danh sách học viên (UC-18-01), xoá học
                                     viên = update status=\'CANCELLED\' (UC-18-03,
                                     không xoá cứng)

  payment                R           SCR-30 --- lịch sử thanh toán trong group

  refund_request         R, U        SCR-29 --- duyệt/từ chối hoàn tiền (UC-22).
                                     Khi APPROVED → phải tự trigger nghiệp vụ:
                                     update enrollment.status=\'CANCELLED\',
                                     payment.status=\'REFUNDED\',
                                     refund_request.status=\'COMPLETED\',
                                     refunded_at (3 update này nên gói trong 1
                                     transaction ở code, DB không tự link)

  v_revenue_report       R           SCR-24/37 (UC-21)
  --------------------------------------------------------------------------------

**🟣 TEACHER**

**Vai trò:** Giảng dạy lớp được gán (class.teacher_id), bổ sung tài
liệu, chấm bài luận (AI hỗ trợ, Teacher duyệt cuối).

  -------------------------------------------------------------------------------
  **Bảng**                      **Quyền**     **API/Use case liên quan**
  ----------------------------- ------------- -----------------------------------
  class                         R (chỉ lớp    
                                mình dạy,     
                                theo          
                                teacher_id)   

  class_material                C, R, U       SC-01 bước 8 --- tài liệu riêng cho
                                              lớp, không ảnh hưởng lesson gốc

  assignment,                   C, R, U       SCR-11 (Teacher cũng có thể tạo,
  assignment_rubric_criterion                 theo PRD FT-05). **(Mới 07/2026)**
                                              có thể set lesson_id để gắn bài tập
                                              với 1 lesson cụ thể của class.

  submission                    R, U          SCR-19/20 --- xem danh sách bài nộp
                                              (UC-29), chấm chi tiết
                                              (UC-23/24/27): update final_score,
                                              feedback, status=\'GRADED\',
                                              graded_by, graded_at

  submission_criterion_score    R, U          Ghi final_score, teacher_feedback
                                              theo từng tiêu chí (UC-26/27) ---
                                              ai_score/ai_feedback là cột chỉ-đọc
                                              do AI ghi (UC-25)

  learning_progress             R             Theo dõi tiến độ học viên trong lớp
                                              (UC-28/30)

  notification                  C             Gửi nhắc nhở học viên (SC-05 bước
                                              3)

  v_class_overview_report       R             SCR-35 --- học viên không hoạt
                                              động, lớp drop cao
  -------------------------------------------------------------------------------

**Quan trọng:** Khi Teacher \"Finalize and Sign Off Grades\" (UC-23),
code cần update **cả 2 bảng cùng lúc**: submission.final_score/status
**và** từng dòng submission_criterion_score.final_score --- nên đặt
logic trong 1 transaction để tránh lệch dữ liệu (UC postcondition yêu
cầu \"atomically\").

**🟡 STUDENT**

**Vai trò:** Học, luyện tập, làm bài kiểm tra, nộp bài luận, đăng ký &
thanh toán, xem tiến độ cá nhân.

  -----------------------------------------------------------------------------------
  **Bảng**                 **Quyền**                   **API/Use case liên quan**
  ------------------------ --------------------------- ------------------------------
  lesson                   R (chỉ nếu có enrollment    SCR-12
                           ACTIVE hợp lệ tới           
                           class/course tương ứng ---  
                           check ở Service Layer,      
                           GB-04)                      

  lesson_view_event        C                           Mỗi lần học viên xem lesson →
                                                       insert 1 row (phục vụ
                                                       analytics SME)

  flashcard_deck,          R                           SCR-13
  flashcard                                            

  flashcard_review_log     C                           Ghi mỗi lần đánh giá ghi nhớ
                                                       (Forget/Remembered/Mastered)

  quiz                     C (loại                     SCR-14 --- tự tạo quiz theo
                           is_practice_generated=1), R phạm vi/độ khó (chọn random
                                                       question theo module_id +
                                                       difficulty, sau đó insert
                                                       quiz + quiz_question)

  quiz_attempt,            C, R, U                     SCR-15/16 --- bắt đầu attempt,
  quiz_attempt_answer                                  nộp từng câu trả lời, tính
                                                       score khi submit_time được set

  assignment               R                           Xem đề bài đã publish của lớp
                                                       mình học

  submission               C, R                        SCR-17/18 --- nộp bài (1
                                                       student chỉ có **1 row** /
                                                       assignment, theo
                                                       UNIQUE(assignment_id,
                                                       student_id) --- resubmit =
                                                       UPDATE, không INSERT lần 2).
                                                       Chỉ xem final_score/feedback
                                                       sau khi status=\'GRADED\' (ẩn
                                                       AI draft)

  enrollment, payment      C, R                        SCR-26/27/30 --- đăng ký (chọn
                                                       enrollment_type H1/H2/H3), tạo
                                                       payment PENDING → webhook
                                                       VNPay/SePay cập nhật
                                                       status=\'PAID\', paid_at → mới
                                                       insert/update
                                                       enrollment.status=\'ACTIVE\'

  refund_request           C, R                        SCR-28 --- gửi yêu cầu hoàn
                                                       tiền (UC-22), reason

  learning_progress        R                           SCR-31→34

  knowledge_gap_analysis   R (hệ thống tự sinh)        UC \"Phân tích lỗ hổng kiến
                                                       thức\" --- **trước khi gọi AI
                                                       thật, check cache_expires_at
                                                       còn hạn (24h) thì trả cache,
                                                       hết hạn mới gọi AI và insert
                                                       row mới**

  notification             R, U (đánh dấu đã đọc)      
  -----------------------------------------------------------------------------------

**⚪ GUEST**

**Vai trò:** Khách vãng lai --- **không có bảng riêng, không lưu DB**
(NFR-S06). Toàn bộ trải nghiệm Guest xử lý **in-memory/session ở tầng
API** (giới hạn 10 câu hỏi, 5 flashcard).

  ------------------------------------------------------------------------
  **Hành động**    **Cách xử lý**
  ---------------- -------------------------------------------------------
  Xem danh mục     SELECT course WHERE status=\'PUBLISHED\' --- read-only,
  khoá học công    không cần session
  khai             

  Thử              API lấy random 10 question / 5 flashcard đã
  quiz/flashcard   APPROVED/ACTIVE từ 1 course mẫu được Admin chỉ định
  mẫu              (qua system_setting), **không insert**
                   quiz_attempt/flashcard_review_log

  Đăng ký thành    Khi Guest submit form → INSERT users (role=\'STUDENT\',
  Student          \...) --- từ lúc này mới có bản ghi DB
  ------------------------------------------------------------------------

**4. Enum / State Machine tổng hợp (CHECK constraint values)**

  --------------------------------------------------------------------------------
  **Cột**                             **Giá trị hợp lệ**
  ----------------------------------- --------------------------------------------
  users.role                          ADMIN · SME · COURSE_MANAGER · TEACHER ·
                                      STUDENT

  users.status                        ACTIVE · LOCKED · INACTIVE

  course.status                       DRAFT · PENDING_REVIEW · PUBLISHED ·
                                      ARCHIVED

  lesson.status                       DRAFT · PUBLISHED

  question.difficulty /               EASY · MEDIUM · HARD
  quiz.difficulty                     

  question.status                     DRAFT · APPROVED · REJECTED

  question.source                     MANUAL · AI_GENERATED

  quiz.status                         DRAFT · PUBLISHED

  quiz_attempt.status                 IN_PROGRESS · SUBMITTED

  flashcard_deck.status               DRAFT · PUBLISHED

  flashcard_review_log.memory_state   FORGOT · REMEMBERED · MASTERED

  assignment.status                   DRAFT · PUBLISHED · CLOSED

  submission.status                   SUBMITTED · AI_GRADED · GRADED

  class.status                        PLANNED · ACTIVE · COMPLETED · EXPIRED ·
                                      CLOSED

  enrollment.enrollment_type          H1 (mua lẻ course) · H2 (đăng ký class) · H3
                                      (gói membership)

  enrollment.status                   ACTIVE · COMPLETED · CANCELLED · EXPIRED

  subscription_package.status         ACTIVE · INACTIVE

  payment.gateway                     VNPAY · SEPAY

  payment.status                      PENDING · PAID · FAILED · REFUNDED

  refund_request.status               PENDING · APPROVED · REJECTED · COMPLETED

  ai_request.task_type                GEN_QUIZ · GEN_FLASHCARD · EXPAND_OUTLINE ·
                                      SUMMARIZE_VIDEO · GRADE_ESSAY

  ai_request.status                   PENDING · SUCCESS · FAILED · TIMEOUT

  learning_progress.activity_type     LESSON · QUIZ · FLASHCARD · ASSIGNMENT

  course_group.status                 ACTIVE · ARCHIVED

  background_job_log.status           RUNNING · SUCCESS · FAILED
  --------------------------------------------------------------------------------

⚠️ Khi thêm giá trị enum mới, phải ALTER TABLE \... DROP CONSTRAINT
ck_xxx rồi ADD CONSTRAINT lại --- không có lệnh \"thêm value vào enum\"
như Postgres.

**5. 3 Trigger nghiệp vụ tự động --- Backend PHẢI biết để xử lý lỗi
đúng**

  ------------------------------------------------------------------------------------------------
  **Trigger**               **Bảng**                      **Khi nào fire**       **Lỗi trả về nếu
                                                                                 vi phạm**
  ------------------------- ----------------------------- ---------------------- -----------------
  trg_rubric_weight_check   assignment_rubric_criterion   Insert/Update/Delete   SQL Error 16:
                                                          criterion của 1        \"Tổng trọng số
                                                          assignment đã          rubric\... phải =
                                                          PUBLISHED              100%\"

  trg_course_publishable    course                        Update status →        SQL Error 16:
                                                          PUBLISHED              \"Course X không
                                                                                 thể publish:
                                                                                 thiếu
                                                                                 module/lesson\"

  trg_quiz_publishable      quiz                          Update status →        SQL Error 16:
                                                          PUBLISHED              \"Quiz X không
                                                                                 thể publish: chưa
                                                                                 có câu hỏi\"
  ------------------------------------------------------------------------------------------------

**Khuyến nghị xử lý ở backend:** bọc lệnh UPDATE/INSERT liên quan trong
try/catch, bắt lỗi SQL (ví dụ qua exception driver: SqlException C#,
mssql error code trong Node), **map message trigger thành lỗi nghiệp vụ
4xx** trả về frontend (không phải lỗi 500), vì đây là validate nghiệp vụ
hợp lệ chứ không phải bug hệ thống.

Ngoài ra 4 trigger \*\_updated_at (trên users, course, lesson,
course_group) tự set updated_at --- **backend không cần tự set cột này
khi UPDATE**, cứ để trigger làm.

**6. Những điều cần nhớ khi viết Service Layer (vì DB không tự enforce
được)**

1.  **GB-01 (phạm vi Course Group):** mọi query của SME/Course Manager
    phải JOIN course_group_member để lọc đúng group được gán --- DB
    không tự chặn.

2.  **Soft delete:** mọi SELECT trên users, course phải có WHERE
    deleted_at IS NULL trừ khi là màn hình Admin xem lịch sử.

3.  **AI quota (GB-02):** trước khi gọi AI thật, check
    ai_quota.used_count \< quota_limit của user trong tháng hiện tại;
    sau khi gọi AI thành công, UPDATE ai_quota SET used_count =
    used_count + 1.

4.  **Cache 24h (knowledge_gap_analysis):** check cache_expires_at \>
    SYSDATETIMEOFFSET() trước khi gọi AI phân tích lỗ hổng kiến thức.

5.  **Thu hồi quyền truy cập khi hết hạn (GB-04):** Background Job
    (JOB-04, được log vào background_job_log) cần quét enrollment có
    expires_at \< now() và status=\'ACTIVE\' → update
    status=\'EXPIRED\'. Mọi API trả nội dung khoá học phải luôn re-check
    enrollment.status=\'ACTIVE\' tại thời điểm request, không chỉ tin
    theo session.

6.  **Xoá account (JOB-03):** khi Admin deactivate user, ngoài update
    users.status=\'INACTIVE\', phải UPDATE user_session SET revoked_at =
    SYSDATETIMEOFFSET() WHERE user_id = \@id AND revoked_at IS NULL để
    buộc đăng xuất mọi thiết bị.

7.  **Không cascade khi xoá:** vì toàn bộ FK là NO ACTION, nếu thật sự
    cần xoá cứng 1 course/class (rất hiếm, thường chỉ Admin), phải tự
    viết script xoá theo đúng thứ tự con → cha, hoặc đơn giản nhất:
    **không xoá cứng, dùng ARCHIVED/soft delete.**

8.  **assignment.lesson_id (Mới 07/2026):** cột NULL được, không có
    ràng buộc CHECK/FK phụ ép lesson phải cùng course với class của
    assignment đó --- Backend Service Layer khi cho phép chọn lesson_id
    ở SCR-11 phải tự validate `lesson → module → course_id` trùng với
    `class.course_id`, nếu không sẽ tạo ra dữ liệu vô nghĩa (assignment
    của lớp A trỏ tới lesson thuộc course của lớp B).

**7. Seed Data (dữ liệu mẫu) --- có sẵn trong EduNexus_Database_Full.sql**

File `EduNexus_Database_Full.sql` = toàn bộ DDL (mục 1-6 ở trên) **+**
phần **INSERT** cho đủ 38 bảng, chạy tuần tự **1 lần duy nhất** trên
DB rỗng (không dùng `SET IDENTITY_INSERT`, ID được sinh tự động theo
đúng thứ tự insert --- nếu chạy lại phải drop & tạo lại DB, không insert
đè lên dữ liệu cũ).

**Nguyên tắc sinh dữ liệu:** mọi cột dạng "trạng thái/loại" (role,
status, enrollment_type, difficulty, gateway, activity_type, task_type,
memory_state, resource_type...) đều có **tối thiểu 6 bản ghi** cho mỗi
giá trị hợp lệ; mỗi `module` có đúng **6 lesson**; mỗi `course` có 2
module. Số lượng cụ thể theo từng bảng chính:

  --------------------------------------------------------------------------------
  **Bảng**              **Số dòng**  **Phân bổ theo trạng thái/loại (mỗi loại ≥6)**
  ---------------------- ----------- --------------------------------------------
  users                  54          ADMIN 6 · SME 6 · COURSE_MANAGER 6 · TEACHER
                                     6 · STUDENT 30 \| ACTIVE 41 · LOCKED 7 ·
                                     INACTIVE 6

  course_group           12          ACTIVE 6 · ARCHIVED 6

  course                 24          DRAFT 6 · PENDING_REVIEW 6 · PUBLISHED 6 ·
                                     ARCHIVED 6

  module                 48          2 module / course

  lesson                 288         6 lesson / module (DRAFT 48 · PUBLISHED 240)

  question               144         EASY/MEDIUM/HARD 48 mỗi loại · DRAFT/
                                     APPROVED/REJECTED 48 mỗi loại · MANUAL 72 ·
                                     AI_GENERATED 72

  quiz                   36          DRAFT 12 · PUBLISHED 24 \| official 24 ·
                                     practice (is_practice_generated=1) 12

  flashcard_deck         16          DRAFT 8 · PUBLISHED 8

  flashcard              96          6 flashcard / deck

  class                  30          6 mỗi trạng thái (PLANNED/ACTIVE/COMPLETED/
                                     EXPIRED/CLOSED)

  subscription_package   12          ACTIVE 6 · INACTIVE 6

  enrollment              84          H1 12 · H2 60 · H3 12 \| mỗi status
                                     (ACTIVE/COMPLETED/CANCELLED/EXPIRED) 21

  payment                84          PENDING 6 · PAID 52 · FAILED 6 · REFUNDED 20

  refund_request         24          6 mỗi trạng thái (PENDING/APPROVED/
                                     REJECTED/COMPLETED)

  assignment              18          DRAFT 6 · PUBLISHED 6 · CLOSED 6 (9/18 có
                                     lesson_id được gán, 9/18 để NULL)

  submission              24          8 mỗi trạng thái (SUBMITTED/AI_GRADED/
                                     GRADED)

  quiz_attempt            20          IN_PROGRESS 7 · SUBMITTED 13

  learning_progress       48          12 mỗi activity_type

  ai_request              40          8 mỗi task_type · 10 mỗi status

  ai_quota                24          12 user (SME+Teacher) x 2 tháng

  background_job_log      18          6 mỗi trạng thái (RUNNING/SUCCESS/FAILED)
  --------------------------------------------------------------------------------

**Lưu ý kỹ thuật khi seed `assignment` + `assignment_rubric_criterion`:**
trigger `trg_rubric_weight_check` kiểm tra tổng `weight_percent` mỗi khi
có INSERT/UPDATE/DELETE trên `assignment_rubric_criterion` **nếu**
assignment liên quan đang ở status = 'PUBLISHED'. Vì vậy script seed
luôn **insert assignment ở status='DRAFT' trước, insert đủ 3 tiêu chí
rubric (tổng = 100%), rồi mới UPDATE assignment.status → PUBLISHED/
CLOSED** ở bước sau cùng --- tránh lỗi rollback do tổng trọng số chưa
đủ 100% giữa chừng. Backend khi build tính năng "tạo assignment mới"
nên áp dụng đúng thứ tự này (tạo nháp → thêm rubric → publish).

📎 Tham khảo thêm: file EduNexus_Database_Design.md (lý do thiết kế từng
bảng, mâu thuẫn tài liệu đã phát hiện) và EduNexus_Database_Full.sql
(DDL + seed data đầy đủ).
