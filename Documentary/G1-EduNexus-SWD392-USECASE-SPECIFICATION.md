**USE CASE SPECIFICATION**

**_Group Project – Group1_**

– Hanoi, July 2026 –

[**Record of Changes 3**](#_2wmn00nr77er)

[**Conventions & Notation 4**](#_zdhbdfmr9guq)

[1\. Entity State Machines 5](#_8wqt0sokd5w6)

[1.1 User Status Workflow (Son Nam) 5](#_u9fovmcuklzn)

[1.2 Course Status Workflow (Son Nam) 6](#_1n4vfbtixyrn)

[1.3 Lesson Status Workflow (Son Nam) 6](#_ss05gwnbpbzf)

[1.4 Question Status Workflow (Son Nam) 7](#_qyyjihuwkq3l)

[1.5 Quiz Status Workflow (Son Nam) 7](#_x4nrndp8jr5t)

[1.6 Quiz Attempt Status Workflow (Former) 7](#_s8oz5hvjpxra)

[1.7 Flashcard Deck Status Workflow (Kien) 8](#_iq5tkzr2fjj0)

[1.8 Flashcard Review Workflow (per student/card) (Kien) 8](#_jo6nf5txtiws)

[1.9 Assignment Status Workflow (Former) 8](#_dmkc3w62sqv6)

[1.10 Submission Status Workflow (Tung) 9](#_4itfph1d6a3)

[1.11 Class Status Workflow (Tung) 9](#_lvbn2e2w3kmg)

[1.12 Enrollment Status Workflow (Tung) 10](#_yvesu3q2pygy)

[1.13 Payment Status Workflow (Tung) 10](#_cagldsmr5z2f)

[1.14 Refund Request Status Workflow (Huy) 10](#_ms8jm2myfoaw)

[1.15 Subscription Package & Course Group — Status Workflow (Huy) 11](#_lmuslnr7d8pi)

[1.16 AI Request Status Workflow (Huy) 11](#_57gszxwdnswq)

[1.17 Background Job Status Workflow (Huy) 11](#_scs5btf1jhpf)

[2\. Step Notation 11](#_ny0uatl6c68a)

[3\. Glossary (Son Nam) 12](#_743zssp0a3iy)

[**1\. Feature Name: Common 13**](#_razc3bg6c3m)

[UC-01: User Login 13](#_gdf8v22xsg6t)

[Activity Diagram 14](#_6vwg54c67gar)

[Main Flow 14](#_9mk51cpln5yb)

[Alternative Flows 15](#_zhk9295a7kva)

[Business Rules 15](#_p0hxolsnso9m)

[Request Fields 15](#_hqhpuusk2roo)

[UC-02: Student Library 16](#_2nikbwoqtlz5)

[Activity Diagram 16](#_r3jb1lttiaxr)

[Main Flow 17](#_xtnkcovht0g6)

[Alternative Flows 17](#_zdno0adswgub)

[Business Rules 17](#_jpa14hvo5t6)

[Request Fields 17](#_vv1nvusi7op2)

[UC-03: Personal Progress 17](#_9j5bzzhq94yl)

[Activity Diagram 17](#_ap3qm9ii9rjt)

[Main Flow 18](#_1ivdwssmy5uz)

[Alternative Flows 18](#_f20iw5z5icr8)

[Business Rules 19](#_legh21cdrlgu)

[Request Fields 19](#_50b5ncgsbt0q)

[2\. Feature Name: Lesson 19](#_45r0ma9lj3cn)

[UC-06: Lesson Editor 19](#_tgbdoyntjdsr)

[Activity Diagram 19](#_fcaxxi8c92xq)

[Main Flow 20](#_x7lkp7rvy1d2)

[Alternative Flows 21](#_ytl7xwd3guhx)

[Business Rules 21](#_njwny9s1alym)

[Request Fields 21](#_us2l3ufrshp0)

[UC-07: AI Lesson Staging 22](#_jl41j1puxp2y)

[**Activity Diagram 22**](#_anz7vbi6axaa)

[Main Flow 23](#_uizq7yk5gmj1)

[Alternative Flows 23](#_n83glua3vte8)

[Business Rules 23](#_5ed1ut4d0v4a)

[Request Fields 23](#_vy4uz342pyev)

[UC-08: Lesson Text Extract (AI-powered Video Extraction & Summarization) 23](#_aa1g1nxrp4zq)

[Activity Diagram 24](#_huo5k2yr9zhy)

[Main Flow 24](#_roffiyei0qpp)

[Alternative Flows 25](#_acqsd8o6sncp)

[Business Rules 25](#_5jn5a6c0q9bq)

[Request Fields 25](#_vdc267afm5k)

[UC-09: Lesson View 25](#_i6nk6sdd391x)

[**Activity Diagram 25**](#_anz7vbi6axaa)

[Main Flow 26](#_l1saapood3x1)

[Alternative Flows 27](#_8smkfv9a3mbw)

[Business Rules 27](#_t23bv1x7s7zx)

[Request Fields 27](#_7niy4p67bv4y)

[**3\. Feature Name: Assignment 27**](#_nl9q77r9u34p)

[**4\. Feature Name: Flashcard 27**](#_93rqzielnako)

[UC-13: Flashcard Editor 28](#_3ilrx3truu27)

[UC-14: AI Flashcard Staging 29](#_g7ak6ctvjvl0)

[UC-15: Flashcard Library 30](#_rkgunlxi8em9)

[UC-16: Flashcard Practice 32](#_jhuym156or9b)

[**5\. Feature Name: Question 28**](#_auooor9pik8r)

[UC-17Question Bank Index & Filter 28](#_3ilrx3truu27)

[UC-18Question Editor (Add/Edit/Delete Questions Manually) 29](#_g7ak6ctvjvl0)

[UC-19Import Questions from CSV 30](#_rkgunlxi8em9)

[UC-20: AI Question Staging (AI-powered Question Generation & Fast Browsing) 32](#_jhuym156or9b)

[UC-21Module Question Viewer (Read Only) 33](#_2sk3yrnggbid)

# **Record of Changes**

|     |     |     |     |
| --- | --- | --- | --- |
| **Date** | **A\*  <br>M, D** | **In charge** | **Change Description** |
| 04/07/2026 | A   | Son Nam | Adding Glossary |
| 04/07/2026 | A   | Son Nam | Feature Name: Common (UC-01,UC-02,UC-03), Lesson (UC-06,UC-07,UC-08,UC-09) |
| 05/07/2026 | A   | Son Nam | Entity State Machines (1.1 => 1.5) |
| 05/07/2026 | A   | And you? | Feature Name : Flashcard ( UC-13,UC-14,UC-15,UC-16) |
| 05/07/2026 | A   | And you? | Entity State Machines (1.4 => 1.7) |
| 05/07/2026 | A   | Thanh Tung | Question (UC-17,UC-18,UC-19,UC-20,UC-21) |
| 05/07/2026 | A   | Thanh Tung | Entity State Machines (1.10 => 1.13) |
| 05/07/2026 | A   | Minh Kien | Entity State Machines (1.6 => 1.9) |
|     |     |     |     |
|     |     |     |     |
|     |     |     |     |
|     |     |     |     |
|     |     |     |     |

\*A - Added M - Modified D - Deleted

# **Conventions & Notation**

## **1\. Entity State Machines**

### 1.1 User Status Workflow (Son Nam)

This applies to all internal and Student accounts (Guest accounts do not have User records — see Glossary).

### 1.2 Course Status Workflow (Son Nam)

### 1.3 Lesson Status Workflow (Son Nam)

### 1.4 Question Status Workflow (Son Nam)

### 1.5 Quiz Status Workflow (Son Nam)

Quizzes are automatically generated by students, and when practicing, this lifecycle will be skipped.

### 1.6 Quiz Attempt Status Workflow (Former)

### 1.7 Flashcard Deck Status Workflow (Kien)

### 1.8 Flashcard Review Workflow (per student/card) (Kien)

### 1.9 Assignment Status Workflow (Forme 1.10 Submission Status Workflow (Tung)

### 1.11 Class Status Workflow (Tung)

### 1.12 Enrollment Status Workflow (Tung)

### 1.13 Payment Status Workflow (Tung)

### 1.14 Refund Request Status Workflow (Huy)

### 1.15 Subscription Package & Course Group — Status Workflow (Huy)

The two entities have similar on/off structures; they are grouped together in a single scheme, distinguished by the label "transition".

### 1.16 AI Request Status Workflow (Huy)

### 1.17 Background Job Status Workflow (Huy)

This applies to JOB-01 (incident monitoring), JOB-02 (log cleanup), JOB-03 (session cancellation), and JOB-04 (expiration scan).

## **2\. Step Notation**

|     |     |
| --- | --- |
| **Symbol** | **Meaning** |
| \[IN\] | The person takes an action (clicks, fills in, submits) |
| \[S\] | The system takes an action (checks, saves, sends, calculates) |
| \[AND\] | The external system takes an action (sends data, requests information) |
| \[J\] | The scheduled process runs (triggered by time or event) |
| AF-xx | Alternative Flow — what happens when the main flow deviates |
| BR-xx | Business Rule — a condition or constraint the system must enforce |

## **3\. Glossary (Son Nam)**

|     |     |
| --- | --- |
| **Term** | **Definition** |
| H1 / H2 / H3 | Three enrollment options (enrollment_type): H1 = purchase a single course (permanent access); H2 = register for a class with an instructor (access during the class period); H3 = purchase a subscription package for a limited time, access to all courses in a Course Group. |
| SME (Subject Matter Expert) | Internal Content Specialist, responsible for drafting and publishing original content (lectures, questions, flashcards, essay assignments) for assigned courses. Note: The original PRD contains translation errors, mistakenly referring to this role as "WE" in some tables — this document uses SME as the standard role. |
| Course vs Class | A Course is the original, shared content (modules, lessons, questions, etc.) compiled by SME. A Class is a single teaching session of that Course with a specific instructor, schedule, and class size — multiple Classes can share the same Course (BR-03: Classes always read content directly from the original Course, not copied separately). |
| Course Group | A group of related courses organized by topic, created by the Admin and assigned to one or more Course Managers/SMEs. This is the main access control boundary of GB-01 (Course Managers/SMEs only operate within the assigned Course Group). |
| Rubric (Scoring criteria) | The essay grading criteria include a name, maximum score (max_score), and weight percentage for each criterion. The total weight of all criteria in an assignment must equal 100% before publication. |
| Staging / Review Buffer Queue | This area temporarily stores AI-generated content (questions, flashcards) before it is officially reviewed, edited, and approved by the SME. Content in this area is in a DRAFT state and is not yet displayed to students (BR-07). |
| AI Quota | The maximum number of AI calls (question generation, flashcards, scoring, etc.) that an SME/Teacher account is allowed to use per month is configured by the Admin (GB-02). FT-12 (knowledge gap analysis) is not included in this limit because it uses a separate 24-hour cache mechanism. |
| Knowledge Gap Analysis | The AI ​​feature analyzes students' learning history to identify weak areas and suggests a 3-step improvement plan. Results are cached for 24 hours (cache_expires_at) to avoid costly repeated AI calls. |
| RBAC (Role-Based Access Control) | Role-based access control model: each actor (Admin, SME, Course Manager, Teacher, Student, Guest) is only allowed to perform actions and access data corresponding to their role, verified at the API layer (NFR-S02). |
| Soft Delete | This mechanism "deletes" by setting the deleted_at column instead of permanently deleting the record from the database. It applies to the users and course tables. By default, all SELECT queries must filter WHERE deleted_at IS NULL. |
| Atomic Transaction | A group of data logging operations (e.g., point confirmation, payment, refund) must be entirely successful or fully rolled back; partial completion is not permitted to avoid data discrepancies between related tables. |
| Webhook | The payment gateway mechanism (VNPay/SePay) or external service proactively sends (pushs) transaction results to EduNexus, instead of EduNexus having to proactively poll for the status. |
| Practice Quiz (Automatically generated quiz) | The quiz is created by the students themselves for practice (quiz.is_practice_generated = 1), and the scores are not recorded in the official gradebook (BR-06) — unlike the officially compiled quiz by SME. |
| Guest Session | The user session is not logged in. It is not saved to the database (NFR-S06) — it only exists temporarily in the API layer cache, limited to a maximum of 10 questions and 5 sample flashcards (BR-12). |
| FT-ID / UC-ID / SC-ID | FT-ID: Technical Feature ID; UC-ID: Specific Use Case ID; SC-ID: Business Flow/Scenario ID, for example, SC-01 includes multiple related UC-IDs. |
| GBR-ID / BR-ID / GB-ID | Business rule codes: GBR-ID/GB-ID are used for Global Business Rules (affecting ≥2 use cases, defined in PRD §5); BR-ID is used for Local Business Rules within SRS/URD, affecting only one group of features. |
| AND / NO | AC (Acceptance Criteria): An acceptance condition that describes the expected behavior. NAC (Non-Acceptance Criteria): An unacceptable condition that describes the incorrect/rejected behavior that the system must handle correctly. |
| NFR | Non-Functional Requirement — A non-functional requirement (performance, security, availability, maintainability, etc.) that does not describe specific features but rather the operational quality of the system. |
| Enrollment | This record shows a student's access rights to a specific Course/Class/Subscription Package, associated with exactly one of three H1/H2/H3 forms (constraint chk_enrollment_exactly_one). |
| JWT / Refresh Token Rotation | JWT (JSON Web Token): A token used to authenticate login sessions, with a short lifespan. Refresh Token Rotation: Each time the access token is refreshed, the old token is deactivated and a new token is issued, reducing the risk of stolen tokens being reused. |

# **1\. Feature Name: Common**

## **UC-01: User Login**

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | User Manager |
| Primary Actor | Student (Guest → Student) | Secondary Actor | Google Identity (API-04) |
| Triggers | Users access the homepage/course catalog and click "Log in" or "Register". |     |     |
| Preconditions | The user does not have a valid login session (JWT) on the current device. |     |     |
| Postconditions | The user has a valid access token and refresh token; if it's a Guest and the migration is successful, a new user record will be created with role=STUDENT, status=ACTIVE; and login_history will be recorded. |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\] The user goes to the login screen and selects the method: "Sign in with Google" or Email/Password.

2\. \[U\] (Google branch) The user clicks "Sign in with Google" and selects their Google account.

3\. \[E\] Google Identity authenticates OAuth 2.0, returning an auth token along with basic profile information (email, name, profile picture).

4\. \[S\] System finds user by email: if it already exists → link user_oauth_identity (if it doesn't exist) and log in; if it doesn't exist → create a new user record with role=STUDENT, status=ACTIVE — see BR-26.

5\. \[S\] The system issues JWT access tokens (short lifespan) and refresh tokens, recording login_history with status=SUCCESS.

6\. \[S\] The user is transferred to the Student Library screen (UC-02) within 3 seconds (AC-14b).

### **Alternative Flows**

• AF-01 — Register/Login with Email + Password: In step 1, the user selects and enters an Email and Password (minimum 8 characters, including letters, numbers, and special characters) along with a Display Name if it's a new registration. The system checks if the email does not exist (NAC-14-a), hashes the password using bcrypt (NFR-SEC06), and sends a verification email within 60 seconds (AC-14a, NTF-12). The account is only activated after successful email verification.

• AF-02 — Forgot Password: The user clicks "Forgot Password," enters their registered email address. The system sends a password reset link valid for 1 hour and usable only once (BR-22, NTF-13). After a successful reset, the entire current login session is logged out for 5 seconds (AC-14d).

• AF-03 — Account Locked/Disabled: In step 4, the system detects users.status = LOCKED or INACTIVE → login is denied, displaying a message requesting contact with the Admin.

• AF-04 — Multiple failed login attempts: In the Email/Password branch, each incorrect attempt increases the failed_login_count; when the configured threshold is exceeded, the account automatically switches to LOCKED and all user_session is revoked (GB-05).

• AF-05 — Google Email already exists as an Email/Password account: In step 4, the system automatically links the existing account instead of creating a duplicate record (BR-26, AC-14f).

### **Business Rules**

• BR-21: Google login account without internal password on EduNexus — no password reset option displayed (NAC-14-c).

• BR-22: One-time password reset link, expires after 1 hour (NAC-14-d).

• BR-26: Registering with Google using an existing email address must automatically link the account; do not create duplicate accounts.

• GB-03 (Global — PRD §5): Internal roles (SME, Teacher, Course Manager) cannot be registered automatically via this screen — only Admins can create them via FT-15/UC-55.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| Email | Text | Required. Valid email format, not already in the system if it's a new registration. |
| Password | Text (hide characters) | Required if logging in/registering using email. Minimum 8 characters, including letters, numbers, and special characters. |
| Full Name | Text | Email is required when registering for the first time. Maximum 150 characters. |
| Google Account | Choose OAuth | Required if you select "Sign in with Google". |

## **UC-02: Student Library**

|     |     |     |     |
| --- | --- | --- | --- |
| **_Type_** | UI  | **_Module_** | User Manager / ClassRoom & Business |
| **_Primary Actor_** | Student | **_Secondary Actor_** | Do not have |
| **_Triggers_** | Students who successfully log in (UC-01) will be redirected to, or can proactively select, the "My Library" menu. |     |     |
| **_Preconditions_** | The student has logged in validly (JWT is still valid). |     |     |
| **_Postconditions_** | Students can view the complete list of Courses/Classes/Subscription Packages they own, along with their current access status. |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\] Students access the "Student Library" screen.

2\. \[S\] The system queries the entire Enrollment (H1/H2/H3) of the student and joins the corresponding Course/Class/Subscription Package.

3\. \[S\] The system calculates the current access_status of each enrollment (ACTIVE/EXPIRED/COMPLETED/CANCELLED) according to BR-16 (always check at the time of request).

4\. \[S\] The system displays the following list: course/class name, participation type (H1/H2/H3), status, expiration date (if any), and overall progress percentage.

5\. \[U\] Students can filter by status (In progress/Expired/Completed) or search by name.

6\. \[U\] Students click on an item to go to Lesson View (UC-07) or Personal Progress (UC-03) respectively.

### **Alternative Flows**

• AF-01 — No courses found: If the list is empty, the system displays a friendly message with a "Explore Courses" button leading to the public catalog (SCR-05).

• AF-02 — Accessing expired items: If a student clicks on an item with access_status = EXPIRED, the system blocks access to Lesson View and only allows viewing of existing history/results, remaining unchanged according to BR-18.

• AF-03 — Subscription Package (H3) is about to expire: The system displays a warning banner when enrollment.expires_at is within 7 days (related to NTF-05).

### **Business Rules**

• BR-16 (Global): Each time paid content is accessed, the system must verify that access permissions are valid at the time of the request, not just rely on the session.

• BR-18 (Global): Revoking access does not delete academic history — progress, test results, and essays remain intact.

• Local: The screen only displays data for the currently logged-in student; it does not show data for other students.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| **Field** | **Type** | **Rule** |
| Status Filter | Dropdown | Options. Values: All / In progress / Expired / Completed. |
| Search Keyword | Text | Optional. Search by course/class name, partial match. |

## **UC-03: Personal Progress**

|     |     |     |     |
| --- | --- | --- | --- |
| **_Type_** | UI  | **_Module_** | Learning |
| **_Primary Actor_** | Student | **_Secondary Actor_** | Do not have |
| **_Triggers_** | Students select a course/class from the Student Library (UC-02) or go to the "My Progress" menu. |     |     |
| **_Preconditions_** | Students have (or have previously had) an enrollment in the selected course/class. |     |     |
| **_Postconditions_** | The screen displays all four data groups: course progress, test results, flashcard progress, and essay status (FT-12). |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\] Students select a specific course/class to view their progress (if there is more than one).

2\. \[S\] The learning_progress query system uses student_id + class/course to calculate the completion percentage for each module — data is updated immediately after each activity (AC-12b).

3\. \[S\] The quiz_attempt query system plots trend scores (at least the 5 most recent — AC-12c) and correctness rate by topic/module.

4\. \[S\] The system queries flashcard_review_log to calculate the number of cards that have been included/total cards by topic group.

5\. \[S\] The system queries submission to display the status (SUBMITTED/AI_GRADED/GRADED), score, and teacher feedback.

6\. \[S\] The entire dashboard loads in 1.5 seconds (AC-12a).

### **Alternative Flows**

• AF-01 — No learning data: If the student has no activities yet, the system displays a friendly empty status with a suggestion to start learning.

• AF-02 — Fewer than 5 test attempts: The system continues to plot the current number of attempts without reporting errors (loosen AC-12c when data is insufficient).

### **Business Rules**

• AC-12d: Students can only view their own progress data, not that of other students.

• NAC-12-a: Practice data (Practice Quiz, BR-06) must not distort official progress metrics — they must be displayed separately.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| **Field** | **Type** | **Rule** |
| Course/Class Selector | Dropdown | This is mandatory if a student is enrolled in more than one course/class. |

## **2\. Feature Name: Lesson** **UC-06: Lesson Editor**

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | No (Teacher has limited authority — see AF-05) |
| Triggers | SME users can select "Add New Lesson" or open an existing Lesson from the Course Structure screen to edit it. |     |     |
| Preconditions | The SME has been assigned (course_group_member) to the Course Group containing this course (GB-01); the parent module already exists. |     |     |
| Postconditions | Lessons are saved with status=DRAFT or PUBLISHED; if you edit a lesson belonging to a PUBLISHED course, course_content_version records the snapshot of the change. |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\]SME selects Module, clicks "Add Lesson" (or opens an existing Lesson to edit).

2\. \[U\]SME enters the Lesson Name and composes the Markdown Content in the main editing area — preview updated within 200ms (AC-02a).

3\. \[U\]SME paste the YouTube video link (optional).

4\. \[S\] The system verifies valid YouTube URLs within 3 seconds and embeds videos in 16:9 aspect ratio on all screen sizes (AC-02b, AC-02c).

5\. \[U\]SME uploads the attached document file (PDF/Word/ZIP, optional).

6\. \[S\] File size check system according to configuration limit CFG-B01 (BR-04).

7\. \[U\]SME arranges content/lessons in a drag-and-drop order.

8\. \[S\] The system saves the order immediately after drag-and-drop (AC-02e).

9\. \[U\]SME clicks "Save" (save draft, status=DRAFT) or "Save & Publish" (status=PUBLISHED).

10\. \[S\] If the Lesson belongs to a PUBLISHED Course, the system writes a snapshot to course_content_version before updating (AC-01d).

### **Alternative Flows**

• AF-01 — Empty text content: In step 9, if the Markdown content is empty, the system refuses to save and displays an error message (NAC-02-a).

• AF-02 — Invalid Video: In step 4, if the URL is invalid or the video does not exist, the system displays a clear error and does not embed the video (NAC-02-d).

• AF-03 — Video not from YouTube: The system immediately rejects the request and requires only using a YouTube link (NAC-02-e).

• AF-04 — File exceeds size limit: At step 6, the system rejects the file, does not save it to the system, and clearly displays the allowed limit (NAC-02-c).

• AF-05 — Teacher attempts to modify original content: If the person performing the modification is a Teacher (not a responsible SME), the system refuses to overwrite the original content, only allowing the addition of supplementary materials specific to that class (NAC-02-b, NAC-01-a, class_material).

### **Business Rules**

• BR-01 (Global): Only assigned SMEs are allowed to create and edit original course content.

• BR-02 (Global): Teachers are not permitted to modify or delete content from the original SME course.

• BR-04 (Global): Attachment exceeds size limit (CFG-B01) rejected before saving.

• GB-01 (Global — PRD §5): SMEs are only allowed to operate within the Course Group assigned by the Admin.

• AC-02d: Lectures support a minimum of 50,000 characters.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| Lesson Name | Text | Required. Maximum 255 characters. |
| Module | Dropdown | Required. Select an existing parent module. |
| Content (Markdown) | Rich text | Required, cannot be empty. Minimum support of 50,000 characters. |
| Video URL | Text | Optional. Only links from youtube.com/youtu.be will be accepted. |
| Attachment File | File | Optional. Storage capacity is limited by CFG-B01 configuration. |
| Order No | Number | Automatic drag-and-drop updates, with the option to manually adjust settings. |

## UC-07: AI Lesson Staging

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | AI Engine (Google Gemini, API-02) |
| Triggers | SME clicks "Generate Content by AI" from Lesson Editor (UC-04) after obtaining the rough outline or source transcript. |     |     |
| Preconditions | SME has provided input data (outline, transcript, or uploaded document); AI subsystem is available; ai_quota.used_count < SME's quota_limit for the current month (GB-02). |     |     |
| Postconditions | The AI-generated draft content is displayed in the staging area; it is only officially written to lesson.content after SME approval and inserted into the lesson. |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\]SME import the rough outline or select the extracted transcript source (UC-06), then click "Generate by AI".

2\. \[S\] System checks ai_quota limit (GB-02); if sufficient, record ai_request (task_type=EXPAND_OUTLINE, status=PENDING).

3\. \[S\] The system sends the payload (text source + outline expansion prompt) to the AI ​​Engine.

4\. \[E\] The AI ​​Engine processes and returns the expanded lecture content in Markdown format in up to 25 seconds.

5\. \[S\] The system records ai_response (status=SUCCESS), increments ai_quota.used_count, and displays the draft content in the staging area for SME to preview.

6\. \[U\]SME will read and edit the draft content directly if necessary.

7\. \[U\]SME clicks "Insert Lesson" to import the approved content into the official Lesson Editor (continue in UC-04 save step).

### **Alternative Flows**

• AF-01 — AI Quota Exceeded: In step 2, if used_count ≥ quota_limit, the system blocks AI calls, displays "AI quota for this month has been reached" (GB-02), and suggests contacting the Admin to increase the quota.

• AF-02 — AI Service Timeout/Error: In step 4, if the AI ​​does not respond within 30 seconds or returns an error, the system records ai_request.status=TIMEOUT/FAILED, displays "AI system is currently busy, please try again," and allows the SME to manually enter the information (NFR-P02, NFR-R02).

• AF-03 — SME rejects draft content: SME can delete the entire draft without inserting it into the lesson — this does not affect the official Lesson data.

### **Business Rules**

• BR-07 (Global): AI-generated content must go through a review process and can only be officially used after SME approval.

• GB-02 (Global): AI usage must not exceed the monthly limit configured by the Admin for each SME/Teacher.

• NAC-02-a (succeeds UC-04): Empty content is not saved, even when retrieved from AI.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| Source Outline | Text area | Required. Sufficient context is needed (minimum of ~50 characters recommended) for the AI ​​to process correctly. |
| Target Length/Style | Dropdown | Optional. Suggest desired lecture length/writing style. |

## UC-08: Lesson Text Extract

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | YouTube Data API (API-01), AI Engine (API-02) |
| Triggers | SME pastes the YouTube link and clicks "Summarize with AI" in Lesson Editor (UC-04). |     |     |
| Preconditions | YouTube videos must be in Public or Unlisted mode and have available subtitles (transcripts); ai_quota must still have available limits. |     |     |
| Postconditions | The summary is saved to lesson.summary and displayed directly below the video for students when the lesson is published. |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\]SME pastes the YouTube video URL into Lesson Editor, then clicks "Summarize with AI".

2\. \[S\] The system verifies the URL format and calls the YouTube Data API to retrieve the transcript with the timestamp.

3\. \[S\] System checks ai_quota limit (GB-02), record ai_request (task_type=SUMMARIZE_VIDEO).

4\. \[S\] The system sends a raw transcript to the AI ​​Engine along with a summary prompt, with personal identification information filtered out if any (NFR-S03).

5\. \[E\] The AI ​​Engine returns a structured summary (main idea + timeline), preferably in Vietnamese if the original subtitles are in Vietnamese, in a maximum of 4 seconds (AC-02f).

6\. \[S\] The system saves the summary to lesson.summary and displays it immediately for SME to preview before publishing.

### **Alternative Flows**

• AF-01 — Video without subtitles: In step 2, if the YouTube API returns an empty transcript, the system displays "summary feature unavailable" instead of a system error (NAC-02-f).

• AF-02 — Invalid URL or video does not exist: The system displays a clear error, failing to call the AI ​​Engine (NAC-02-d).

• AF-03 — Non-YouTube Source: If SME pastes a link from another platform, the system will reject it immediately (NAC-02-e).

• AF-04 — AI Limit Exceeded: Similar to AF-01 of UC-05 — blocks AI calls when AI_quota is exceeded (GB-02).

### **Business Rules**

• GB-02 (Global): Check AI limits before calling AI Engine.

• NFR-S03 (Global): Does not send personally identifiable information (PII) to external AI services — only sends video transcript content.

• Local: A read-only summary is displayed below the video for learners; SMEs can manually edit it after the AI ​​generates it.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| Video URL | Text | Required. Only youtube.com or youtu.be domains will be accepted. |
| Summary Language | Dropdown | The default language is "Vietnamese"; you can change the summary language. |

## UC-09: Lesson View

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Learning |
| Primary Actor | Student | Secondary Actor | Do not have |
| Triggers | Students choose a lesson from the Course Structure or the Student Library (UC-02) to begin their studies. |     |     |
| Preconditions | The student has a valid Enrollment with access_status=ACTIVE to the Course/Class containing this Lesson (GB-04); the Lesson is in PUBLISHED status. |     |     |
| Postconditions | learning_progress is recorded/updated for the LESSON activity; lesson_view_event is inserted to serve Analytics (FT-13, v_content_quality_report). |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\] The student opens a Lesson from the module list.

2\. \[S\] The system checks that access rights are valid at the time of the request (BR-16, GB-04) before delivering the content.

3\. \[S\] The system displays content in the following order: Markdown lecture, YouTube video with AI summary below (if available, UC-06), attached document for download — fully downloaded in 1 second (AC-06a).

4\. \[U\] Students can view/listen to the content and download attached materials.

5\. \[U\] Students click "Mark as completed".

6\. \[S\] Hệ thống ghi nhận learning_progress (activity_type=LESSON, completion_status=COMPLETED) trong vòng 500ms (AC-06b) và insert lesson_view_event (watch_seconds, completed).

7\. \[S\] The module's progress bar is updated instantly on the interface.

### **Alternative Flows**

• AF-01 — No Access: In step 2, if the Enrollment is not ACTIVE or EXPIRED, the system refuses to display the content and redirects to the registration/renewal page (NAC-06-a).

• AF-02 — Module with no content: If the Module does not have any Lessons in the PUBLISHED state, the system displays a user-friendly message instead of a blank page (NAC-06-b).

• AF-03 — Access expires during study: If JOB-04 revokes access while the student is viewing, the next page load is blocked according to AF-01; previously recorded progress data is retained (BR-18).

### **Business Rules**

• BR-16 (Global): Always verify access at the time of the request, not just trust the session.

• GB-04 (Global — PRD §5): Class/Subscription Package expires → access revoked immediately.

• Local (inherits features from AC-02c): Video displays correctly in 16:9 aspect ratio on all screen sizes.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| Lesson ID | System identification | Required. Used to identify the content to download and check the corresponding access permissions. |
| Watch Progress (giây) | Number | Automatically send periodic updates from the video player to update watch_seconds. |

# **3\. Feature Name: Assignment** **4\. Feature Name: Flashcard**

## **UC-13: Flashcard Editor (Manual Add/Edit/Delete & CSV Import)**

|     |     |     |     |
| --- | --- | --- | --- |
| **_Type_** | UI  | **_Module_** | Content Manager |
| **_Primary Actor_** | WE  | **_Secondary Actor_** | None (Teacher has restricted rights only — see AF-04) |
| **_Triggers_** | SME clicks "Add New Flashcard Set" or opens an existing Flashcard Set from a Module to edit it. |     |     |
| **_Preconditions_** | The SME is assigned (course_group_member) to the Course Group that owns this course (GB-01); the parent Module already exists. |     |     |
| **_Postconditions_** | The Flashcard Set is saved with status=DRAFT or PUBLISHED (per the lifecycle in 1.7); each individual card (front_text/back_text) is saved with the set; if the set belongs to a PUBLISHED Course, the system records a snapshot in course_content_version. |     |     |

### **Activity Diagram  
****Main Flow**

1\. \[U\] SME selects a Module, clicks "Add Flashcard Set" (or opens an existing set to edit).

2\. \[U\] SME enters the Deck Name and a Description/topic for the set.

3\. \[U\] SME adds cards one by one: Front Text (term/question) and Back Text (definition/answer); multiple cards can be added in sequence via the "+ Add Card" button.

4\. \[U\] (Optional) SME clicks "Import CSV" to bulk-upload a list of cards using the FrontText, BackText structure — the system parses it the same way as UC-19 (Import Questions from CSV).

5\. \[S\] The system validates each card (front/back must not be empty) before adding it to the set.

6\. \[U\] SME reorders cards by drag-and-drop; the system saves the new order immediately after each drag operation.

7\. \[U\] SME clicks "Save" (saves as draft, status=DRAFT) or "Save to Library" (status=PUBLISHED — per section 1.7).

8\. \[S\] If SME chooses "Save to Library", the system checks that the set has at least 5 valid cards (BR-19) before switching it to PUBLISHED; if not enough, the system keeps it as DRAFT and shows a warning.

9\. \[S\] The system saves the Flashcard Set together with all its cards to the database and records the action in the activity log.

### **Alternative Flows**

- **AF-01 — Empty card:** At step 5, if the Front Text or Back Text is empty, the system refuses to add that card and displays an inline error (similar to NAC-02-a).
- **AF-02 — Not enough cards to publish:** At step 8, if the set has fewer than 5 valid cards, the system refuses to switch it to PUBLISHED, shows "This deck needs at least 5 cards to be published", and keeps it as DRAFT.
- **AF-03 — CSV format error:**Similar to AF-02 of UC-10 — if any invalid row is detected (missing column, empty field), the system rolls back the entire import transaction, saves no cards, and shows the list of failed rows.
- **AF-04 — Teacher attempts to edit the original deck:** If the actor is a Teacher (not the assigned SME), the system refuses to overwrite the original content and only allows the Teacher to create a supplementary Flashcard Set scoped to their own class (similar to AF-05 of UC-06, class-scoped).
- **AF-05 — Duplicate term within the same set:** At step 3, if the Front Text duplicates another card already in the same Flashcard Set, the system shows a warning (does not block saving) so the SME can review it.

### **Business Rules**

- BR-01/BR-02 (Global, inherited from Lesson): Only the assigned SME may create/edit the original Flashcard content of a course; Teachers may not edit or delete the original content.
- GB-01 (Global — PRD §5): SME may only operate on Flashcards within the Course Group assigned by the Admin.
- BR-19: A Flashcard Set can only be switched to PUBLISHED once it has at least 5 valid cards (both front_text and back_text non-empty).
- BR-20: A Flashcard Set belonging to an already-PUBLISHED Course must have a snapshot recorded in course_content_version before being updated (similar to AC-01d of Lesson).

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| **Field** | **Type** | **Rule** |
| Deck Name | Text | Required. Maximum 255 characters. |
| Module | Dropdown | Required. Select an existing parent module. |
| Description/Topic | Text area | Optional. Describes the topic of the deck. |
| Front Text | Text | Required for each card, must not be empty. |
| Back Text | Text | Required for each card, must not be empty. |
| CSV File | File (.csv) | Optional. Column structure: FrontText, BackText. |
| Order No | Number | Automatically updated via drag-and-drop, can be adjusted manually. |

## **UC-14: AI Flashcard Staging (Generate Flashcards with AI & Quick Review)**

|     |     |     |     |
| --- | --- | --- | --- |
| **_Type_** | UI  | **_Module_** | Content Manager |
| **_Primary Actor_** | WE  | **_Secondary Actor_** | AI Engine (Google Gemini, API-02) |
| **_Triggers_** | SME selects "Generate by AI" from the Flashcard Set / Module page. |     |     |
| **_Preconditions_** | SME still has monthly AI quota remaining (ai_quota.used_count < quota_limit, GB-02); the target Module already exists; (optional) source material/transcript is available as context. |     |     |
| **_Postconditions_** | The AI-generated cards are temporarily saved as DRAFT in the Staging Area (per 1.7: "AI generates term pairs into the review queue — UC-14, BR-07"); they only switch to PUBLISHED after the SME approves them. |     |     |

### **Activity Diagram**

### **Main Flow**

1\. \[U\] SME selects the Module/source material, clicks "Generate by AI", enters the Topic and the desired Card Count.

2\. \[S\] The system checks that ai_quota still has room (GB-02); if so, it logs an ai_request record (task_type=GENERATE_FLASHCARD, status=PENDING).

3\. \[S\] The system sends the prompt along with the source material (if any) to the AI Engine.

4\. \[E\] The AI Engine analyzes the input and returns a list of Term - Definition pairs as JSON within a maximum of 15 seconds.

5\. \[S\] The system records ai_response (status=SUCCESS), increments ai_quota.used_count, temporarily saves the cards into a draft Flashcard Set (status=DRAFT), and displays them in the Staging Area.

6\. \[U\] SME reviews each draft card. For every card, the SME has exactly two options: Approve or Reject.

7\. \[S\] Approved cards switch to PUBLISHED and officially appear in the Flashcard Library (UC-15); rejected cards are deleted from the system.

8\. \[U\] SME can click "Approve All" to convert the entire current list of draft cards into official ones at once.

### **Alternative Flows**

- **AF-01 — AI Quota Exceeded:** At step 2, if used_count ≥ quota_limit, the system blocks the AI call, displays "You have reached this month's AI quota" (GB-02), and suggests contacting the Admin to raise the limit.
- **AF-02 — AI Service Timeout / Invalid JSON:** At step 4, if the AI does not respond within 30 seconds or returns a payload that does not match the required schema, the system logs ai_request.status=TIMEOUT/FAILED, displays "AI system is currently busy, please try again", and lets the SME switch to manual card creation (UC-11).
- **AF-03 — SME rejects all draft content:** SME can click "Reject All"; the system deletes all DRAFT cards from this AI generation session without affecting other Flashcard Sets.
- **AF-04 — Duplicate detected against a PUBLISHED card:** At step 5, if the Front Text of an AI-generated card duplicates an existing card in the same Module, the system marks it with a "Possible duplicate" warning next to the draft card for the SME to consider while reviewing.

### **Business Rules**

- BR-07 (Global): Flashcard content generated by AI must always pass through the Staging review area and may never be inserted directly into the Flashcard Library without SME review.
- GB-02 (Global): AI usage for flashcard generation must not exceed the monthly quota configured by the Admin for each SME/Teacher.
- BR-11 (inherited from AI Question Staging): The Staging interface only allows Approve or Reject actions; detailed content editing is performed afterward in the official Flashcard Editor (UC-11).
- NFR-S03 (Global): Source material sent to the AI Engine must be sanitized to remove personally identifiable information before dispatch.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| **Field** | **Type** | **Rule** |
| Module ID | System identifier | Required. Identifies the Module that will contain the generated Flashcard Set. |
| Source Material | Text area / File | Optional. Reference document/transcript to help the AI generate more accurate cards. |
| Topic | Text area | Required. The topic the AI uses to generate Term-Definition pairs (minimum 10 characters). |
| Card Count | Number | Required. The number of cards the AI should generate in one run (e.g., 5, 10, 15). |

## **UC-15: Flashcard Library (Deck List & Mastery Progress)**

|     |     |     |     |
| --- | --- | --- | --- |
| **_Type_** | UI  | **_Module_** | Learning |
| **_Primary Actor_** | Student | **_Secondary Actor_** | None |
| **_Triggers_** | Student selects "Practice with Flashcards" from a Course/Class, or from the Student Library (UC-02). |     |     |
| **_Preconditions_** | Student has a valid Enrollment with access_status=ACTIVE for the Course/Class that owns the Module (GB-04); at least one Flashcard Set exists with status=PUBLISHED. |     |     |
| **_Postconditions_** | Student sees the list of decks belonging to the Module/Course, along with the percentage of cards already MASTERED (computed from flashcard_review_log, section 1.8). |     |     |

### **Activity Diagram  
****Main Flow**

1\. \[U\] Student opens the "Flashcard Library" screen for the course/class they are enrolled in.

2\. \[S\] The system checks that access rights are still valid at the time of the request (BR-16, GB-04).

3\. \[S\] The system queries all flashcard_set records with status=PUBLISHED for the given Module/Course.

4\. \[S\] The system joins the Student's flashcard_review_log data to compute the number of MASTERED cards versus the total number of cards for each deck.

5\. \[S\] The system displays the list of decks together with a mastery progress bar and the card count.

6\. \[U\] Student can filter/search by deck name or topic.

7\. \[U\] Student selects a deck to enter practice mode (UC-16 Flashcard Practice).

### **Alternative Flows**

- **AF-01 — Guest preview (Sample Content Preview):** If the user is a Guest who has not logged in, the system shows a maximum of 5 sample flashcards only, does not persist the session to the database, and does not allow any AI calls (BR-12, NFR-S06).
- **AF-02 — No decks available:** If the Module/Course has no PUBLISHED Flashcard Set, the system shows a friendly empty-state message instead of a blank page (similar to NAC-06-b of Lesson View).
- **AF-03 — No access rights:** If the Enrollment is not ACTIVE or has EXPIRED, the system blocks the display and redirects to the enrollment/renewal page (similar to NAC-06-a).
- **AF-04 — Deck updated by the SME while the Student is viewing the list:** The list only reflects the latest state on the next page load; it does not affect the flashcard_review_log already recorded earlier (BR-18).

### **Business Rules**

- BR-16 (Global): Access rights must always be checked at request time, not simply trusted from the session.
- GB-04 (Global — PRD §5): When a Class/Subscription Package expires, access to the Flashcard Library is revoked immediately.
- BR-12 (Global): Guests can view at most 5 sample flashcards per session, with no database persistence and no AI calls.
- BR-13 (inherited from Question Bank): Only Flashcard Sets with status=PUBLISHED are shown; DRAFT decks still in the Staging Area are never shown to Students.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| **Field** | **Type** | **Rule** |
| Course/Module Selector | Dropdown | Optional. Filters decks by a specific Module/Course. |
| Search Keyword | Text | Optional. Searches by deck name or topic, partial match. |

## **UC-16: Flashcard Practice**

|     |     |     |     |
| --- | --- | --- | --- |
| **_Type_** | UI  | **_Module_** | Learning |
| **_Primary Actor_** | Student | **_Secondary Actor_** | None |
| **_Triggers_** | Student selects a Flashcard deck from the Flashcard Library (UC-15) and clicks "Start Practice". |     |     |
| **_Preconditions_** | Enrollment is still ACTIVE; the Flashcard Set has status=PUBLISHED and contains at least 1 card. |     |     |
| **_Postconditions_** | flashcard_review_log is recorded per card, following the lifecycle defined in section 1.8 (FORGOT/REMEMBERED/MASTERED); learning_progress is updated with activity_type=FLASHCARD. |     |     |

### **Activity Diagram  
****Main Flow**

1\. \[U\] Student opens the deck; the system shows the first card (front side — Term).

2\. \[S\] The system checks access rights and loads the list of PUBLISHED cards in the deck.

3\. \[U\] Student answer and clicks "Show Answer" to flip the card; the system reveals the back side (Definition).

4\. \[U\] Student self-rates their recall as "Forgot" or "Remembered".

5\. \[S\] The system logs flashcard_review_log according to the state machine in  
1.8: FORGOT on the first "Forgot" rating; moves to REMEMBERED once answered correctly; moves to MASTERED after several consecutive REMEMBERED reviews; returns to FORGOT if rated "Forgot" again, or after a long period without review.

6\. \[S\] The system repeats steps 2-5 for each remaining card in the deck, prioritizing cards still in the FORGOT state over cards already MASTERED.

7\. \[S\] Once the deck is finished, the system shows a session summary (number of cards mastered / total cards) and updates learning_progress (activity_type=FLASHCARD, completion_status, time_spent).

### **Alternative Flows**

- **AF-01 — Student exits mid-session:** All flashcard_review_log entries recorded before exiting are preserved; the Student can resume the remaining cards in a later session without losing progress (BR-18).
- **AF-02 — Deck updated by the SME while the Student is practicing:** Changes (adding/removing/editing cards) only take effect starting from the next practice session and do not interrupt the current one.
- **AF-03 — Access revoked mid-session:**If JOB-04 revokes access while the Student is practicing, the system blocks the next session and redirects to the renewal page; the review_log data already recorded is preserved (BR-18, similar to AF-03 of UC-09).
- **AF-04 — Deck only contains DRAFT cards:** If every card in the set is still in Staging (DRAFT), the system does not allow entering practice mode and shows "This deck has no published content yet" (BR-13).

### **Business Rules**

- BR-13 (inherited from Question Bank): Only cards with status=PUBLISHED appear in a practice session.
- BR-16 / GB-04 (Global): Access rights must be verified at the start of every practice session.
- BR-21: Flashcard practice results (flashcard_review_log) are purely personal memorization data and are never counted toward the course's official grade — they are shown only in Personal Progress (UC-03).
- 1.8 (Entity State Machine): Each card's memorization state, per student, follows the exact lifecycle FORGOT → REMEMBERED → MASTERED → (may return to) FORGOT.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| **Field** | **Type** | **Rule** |
| Flashcard Set ID | System identifier | Required. Identifies the deck to practice. |
| Rating | Enum | Required for each card. Accepted values: FORGOT / REMEMBERED. |

# **5\. Feature Name: Question**

## **UC-17: Question Bank Index & Filter**

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | Do not have |
| Triggers | SMEs access the "Question Bank" feature of a course or press the back button from the question creation/editing pages. |     |     |
| Preconditions | SME has been assigned to the course group; the course and related modules already exist. |     |     |
| Postconditions | The system displays a list of questions belonging to the selected module, supporting filtering by difficulty, moderation status, and search keywords. |     |     |

### **Main Flow**

1\. **\[IN\]**SME launched a Question Bank page for a course.

2\. **\[S\]**The system automatically identifies the current course and uploads a list of modules belonging to that course to the filter.

3\. **\[S\]**The system defaults to selecting the first module in the list (or the module being viewed previously) and displaying a list of approved questions.status=APPROVED) of that module.

4\. **\[IN\]**SMEs filter questions by:

- Select a different module from the dropdown.
- Select Difficulty (Easy, Medium, Hard) or Status (All, Reviewed, Draft).
- Enter your search term (SearchTerm) in the search box.
- Press the "Filter" button.

5\. **\[S\]**The system checks parameters, performs database queries, and reloads the corresponding question list within 500ms.

6\. **\[IN\]**SME can press the "Reset" button to clear all selected filters and return the current module to its default state.

### **Alternative Flows**

·

- **AF-01 — Module with no questions yet:**In step 5, if the selected module does not have any questions that meet the filtering criteria, the system will display the message "No matching questions found".
- **AF-02 — Incorrect path filtering (Error 404):**If an SME directly accesses the filtered URL, the Action name is missing./Index (For example: /Question?courseId=...), the system automatically redirects or reports an invalid path error. (Fixed by specifying the route.)/Question/Index).

### **Business Rules**

·

- **BR-14:**It is mandatory to apply the filter to the subordinate module first; do not display all questions from all modules at once to avoid confusion in the question bank content.

·

- **BR-15:**SMEs only have the right to view the question bank for courses belonging to the Course Group for which they are responsible for content management.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| **courseId** | Number | Required. The course ID code is used to identify the category context. |
| **moduleId** | Number | Optional. If not selected, the system will automatically choose the first module of the course. |
| **difficulty** | Dropdown | Options. Filter by difficulty: EASY, MEDIUM, HARD. |
| **status** | Dropdown | Optional. Filter by status: APPROVED, DRAFT. |
| **searchTerm** | Text | Optional. Search for keywords based on the question content. |

### **Activity Diagram**

## **UC-18: Question Editor (Manually Add/Edit/Delete Questions)**

·

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | Do not have |
| Triggers | SMEs can click "Add manually" or select "Edit/Delete" an existing question from the Question Bank management page.Question/Index). |     |     |
| Preconditions | SME is authorized; the target module already exists. |     |     |
| Postconditions | Questions are added, updated, or deleted from the database. |     |     |

### **Main Flow**

1\. **\[IN\]**SME selects the Module, then clicks the "Add manually" button (or selects "Edit" on an existing question card).

2\. **\[S\]**The system displays the question input form. The "Course" field is displayed in read-only mode depending on the current context.

3\. **\[IN\]**SME enters the Question Content, Difficulty Level (EASY, MEDIUM, HARD), and 4 Answer Options (Option A, B, C, D).

4\. **\[IN\]**SME chooses the correct answer (A, B, C, or D) from the dropdown/radio.

5\. **\[IN\]**SME selects the module to store the question and enters the explanation (if any).

6\. **\[IN\]**SME clicks "Save".

7\. **\[S\]**Input data validation system.

8\. **\[S\]**The system saves the question to the database in the following state:APPROVEDand sourceMANUAL.

### **Alternative Flows**

- **AF-01 — Missing required information:**In step 7, if any required fields (Content, Options, Correct Answer) are left blank, the system will refuse to save and display a red error message in the corresponding field.
- **AF-02 — Delete question:**The SME selects "Delete" from the list. The system displays a confirmation popup. If the SME agrees, the system deletes the question record and redirects back to the list page with a success message.

### **Business Rules**

·

- **BR-08 (Global):**Only the SME assigned to manage the course has the right to add, edit, or delete questions in the question bank.
- **BR-09 (Global):**A required question must be linked to a specific module.
- **BR-10:**The Course information field in the question creation form is fixed (Read-only); SMEs are not allowed to change it to avoid accidentally saving the wrong course.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| **Module** | Dropdown | Required. Select the module to receive questions (within the same course). |
| **Content** | Text area | Required. Question content. |
| **Option A / B / C / D** | Text | Required. Content of the 4 answer options. |
| **Correct Option** | Dropdown | Required. Get the value: A, B, C, D. |
| **Difficulty** | Dropdown | Required. Get the value: EASY, MEDIUM, HARD. |
| **AiExplanation** | Text area | Optional. Provide a detailed explanation of the correct answer. |

### **Activity Diagram**

## **UC-19: Import Questions from CSV**

·

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | Do not have |
| Triggers | SMEs click "Import from CSV" on the Question Bank page.Question/Index) |     |     |
| Preconditions | The SME has accessed the correct course; the target module already exists. |     |     |
| Postconditions | Valid questions in the CSV file/content are saved to the database in the following state:APPROVED. |     |     |

### **Main Flow**

1\. **\[IN\]**SME clicks the "Import from CSV" button.

2\. **\[S\]**The Import interface display system includes a module selection dropdown.

Receive questions, file upload area.csvand direct CSV text input fields (CsvText).

3\. **\[IN\]**SMEs select the module to receive questions.

4\. **\[IN\]**SMEs can do it in one of two ways:

- **Method 1:**Upload file in the specified format.csv.
- **Method 2:**Copy and paste the CSV string directly into the text input area (CsvText).

5\. **\[IN\]**SMEs press the "Import" button.

6\. **\[S\]**The system checks the validity of the module. If valid, the system reads the contents of the CSV file/text.

7\. **\[S\]**The system analyzes each CSV line (ignoring header lines if they contain the keywords "Content" or "Content"):

- Verify that the row has at least 6 columns:Content, OptionA, OptionB, OptionC, OptionD,CorrectOption.
- Verify that the required columns are not empty.
- VerificationCorrectOptionMust belong to the order: A, B, C, D (regardless of flower type).
- If there is a 7th column (Difficulty), check if it belongs to EASY, MEDIUM, or HARD (default is MEDIUM if empty/incorrect).
- If there is an 8th column, save it there.Explanation.

8\. **\[S\]**If all lines are valid, the system saves the entire question to the database with the source.IMPORTand display a success message.

### **Alternative Flows**

·

- **AF-01 — Module not selected:**In step 6, if the SME has not selected the module to receive questions, the system will block processing and display the message: "Please select the module to receive questions".
- ·
- **AF-02 — CSV stream formatting error:**In step 7, if any invalid rows are detected (e.g., missing columns, incorrect answer), the system will interrupt the import process (Transaction Rollback), not save any questions, and display a detailed list of the erroneous rows (e.g.,_Line 3: The correct answer 'E' is invalid._).
- **AF-03 — Data source not provided:**If both the file upload and the text input area are blank, the system will display an error: "Please upload a .csv file or paste CSV content."

### **Business Rules**

·

- **BR-16:**The CSV import process must be performed as a single transaction. If any data row is corrupted, the entire import process must be aborted (rollback) to avoid incomplete or partially corrupted data imports.
- **BR-17:**The required file format for uploading is.csv.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| **ModuleId** | Dropdown | Required. The target module receives the imported questions. |
| **File** | File (.csv) | Optional (Required if not entered)CsvText). The CSV file contains the list of questions. |
| **CsvText** | Text area | Optional (Required if not uploading)File). The CSV format string can be pasted directly. |

### **Activity Diagram**

## **UC-20: AI Question Staging (AI-powered Question Generation & Fast Browsing)**

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager |
| Primary Actor | WE  | Secondary Actor | AI Engine (Google Gemini, API-02) |
| Triggers | SMEs select "Generate using AI" from the Question Bank/Index page. |     |     |
| Preconditions | SMEs still have remaining AI usage limits for the month; the target module already exists. |     |     |
| Postconditions | AI-generated questions are stored in a temporary (draft) state in the Staging Area. Only after approval do questions move to the official (approved) state. |     |     |

### **Main Flow**

1.  **\[IN\]**SME selects the module from which to generate questions, then clicks the "Generate using AI" button.
2.  **\[IN\]**SME enters the Topic, desired difficulty level, and number of questions to create.
3.  **\[S\]**The system checks the AI ​​usage limit for each account.
4.  **\[S\]**The system sends prompts and context to the AI ​​Engine for processing.
5.  **\[AND\]**The AI ​​Engine analyzes and returns a list of standard multiple-choice questions (Content, 4 options, correct answer) in JSON format within a maximum of 15 seconds.
6.  **\[S\]**The system saves a temporary list of questions to the draft table (status=DRAFT), and displays this list on the Staging Area interface for SME visual review.
7.  **\[IN\]**The SME reviews each draft question. For each question, the SME has only two action options:

- **Approve:**The system updates the question status to APPROVED, officially adding it to the Question Bank.
- **Reject:**The system removes this draft question from the database.

1.  **\[IN\]**SMEs can click the "Browse All" button to convert the entire current draft list of questions into the official list.

### **Alternative Flows**

- **AF-01 — AI Quota Exceeded:**In step 3, if the account has exceeded the monthly AI call limit, the system will block requests, display an error message "This month's AI limit has been reached," and instruct users to contact the Admin.
- **AF-02 — JSON formatting error from AI:**In step 5, if the data returned from the AI ​​Engine contains syntax errors or missing fields, the system automatically discards the erroneous questions, logs them, and displays the message: "An error occurred during the question formatting process from the AI, please try again."
- **AF-03 — Staging Cancelled:**SMEs can leave the Staging page or reload the page without clicking Approve/Reject; questions in the DRAFT state will remain in the Staging Area for later processing.

### **Business Rules**

- **BR-07 (Global):**All questions generated by AI must go through the Staging area for approval; they cannot be directly added to the Question Bank for immediate use without prior approval from the SME.
- **BR-11:**The Staging interface only allows Approve or Reject actions. Direct editing of draft content is not supported here to ensure the simplicity of the quick review process. Detailed editing will be done later in the official Question Bank.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| **Module ID** | System identification | Required. Specify the module that will contain the generated question. |
| **Topic / Context** | Text area | Required. Raw input material or topic for the AI ​​to use to generate questions (Minimum 10 characters, details recommended). |
| **Difficulty** | Dropdown | Required. Desired difficulty level for the generated question series (EASY, MEDIUM, HARD). |
| **Question Count** | Number | Required. The number of questions you want the AI ​​to generate in one round (e.g., 5, 10, 15). |

### **Activity Diagram**

## **UC-21: Module Question Viewer (Read Only)**

|     |     |     |     |
| --- | --- | --- | --- |
| Type | UI  | Module | Content Manager / Learning |
| Primary Actor | SME, Teacher | Secondary Actor | Do not have |
| Triggers | SME or Teacher clicks on the "View questions" link on the Module tab in the Course/Structure interface. |     |     |
| Preconditions | Users have access to the corresponding Course (either the SME in charge of the course or the teacher assigned to teach the class of this course). |     |     |
| Postconditions | The system displays a list of questions belonging to that module in read-only mode. |     |     |

### **Main Flow**

1.  **\[IN\]**Users view the Module tab in the course structure and click the "View Questions" button.
2.  **\[S\]**The system sends a request to the server along with the moduleId identifier.
3.  **\[S\]**The query system retrieves all queries with the APPROVED status associated with this moduleId.
4.  **\[S\]**The system displays a list of questions on the screen, including: the question content, four answer choices, the correct answer, and the difficulty level.
5.  **\[IN\]**Users scroll through the page to view the list of questions but cannot perform Add, Edit, or Delete actions.

### **Alternative Flows**

- **AF-01 — Module with no questions yet:**In step 3, if the system queries and finds that the module has no approved questions, it will display a blank interface with a friendly message: "This module has no questions yet."
- **AF-02 — User does not have access to the course:**In step 2, if the system detects that a user (Teacher or other SME) is attempting to manually access a module within a course they are not assigned to teach/responsible for via its URL, the system will deny access and redirect to a permissions error page (403 Forbidden).

### **Business Rules**

- **BR-12:**The "View Questions" flow from the Module tab is entirely read-only for both SME and Teacher to support quick content checking and avoid accidental edits while working on the course structure diagram.
- **BR-13:**Only questions that are in the APPROVED state will be displayed. Draft questions currently in the Staging Area (status=DRAFT) will not appear in this list.

### **Request Fields**

|     |     |     |
| --- | --- | --- |
| Field | Type | Rule |
| **Module ID** | System identification | Required. Used to route and query the exact list of questions to be displayed. |

###   
**Activity Diagram**