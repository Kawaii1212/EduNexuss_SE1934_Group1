DESIGN_MODELING_DOCUMENT_DMD

**PROJECT ASSIGNMENT/LAB**

**User Requirement Document (URD)**

Subject: SWD392

– Hanoi, May 2025 –

# Table of Content

[**Table of Content 2**](#_wzqlmrx6a057)

[**I. Record of Changes 2**](#_ymuw93dr4mx6)

[**II. Software Requirement Specification 3**](#_bar2br7xzj6)

[1\. Requirement Modeling 3](#_2mckskiz5d8l)

[1.1 Feature Tree 4](#_vv3xiqmuxdaa)

[1.2 Context Diagram 5](#_5m7lr1wuisvm)

[1.3 Data Flow Diagram 8](#_gksyeryrif4p)

[1.3.1 Data flow descriptions 8](#_8vhyh8rtp3vl)

[1.3.2 Data stores descriptions 8](#_635xs7nips7n)

[1.4 Entity Relationship Diagram 8](#_ghu0ww5m877)

[1.5 System static Modeling 8](#_ylsnx1s3a1is)

[1.5.1 Context Modeling 8](#_q1rbc3jmxg3b)

[1.5.2 Entity Classes 9](#_fy5txi91ramy)

[2\. Use Case Modelling 9](#_7j7qy0i2a1gq)

[2.1 Actors 9](#_sbfjofs4schx)

[2.2 UC Diagrams 10](#_dsds8nuacp9q)

[2.2.1 UCs for Guest 10](#_mlic9xqextdw)

[2.2.2 UCs for System Admin 11](#_guv75t6iqpi)

[2.2.3 UCs for SME 11](#_w2q75s7nzwsd)

[2.2.4 UCs for Students 11](#_8f1mw5t0w7mp)

[2.2.5 UCs for Teacher 12](#_elakq4ja3kgr)

[2.2.6 UCs for Course Manager 13](#_cpmfv2rzyf1o)

[2.3 Activity Diagram 13](#_ybqg1y94oo70)

[2.3.1 Use Case Specification 01: 14](#_aw7cuq8ho4te)

[2.3.2 Use Case Specification 02: 14](https://docs.google.com/document/d/14nMfmFHM9NRqSPNBw2QJFGXItH_AeKieNfQsNgppT1k/edit?tab=t.0#heading=h.gxtpbd9nne21)

[2.3.3 Use Case Specification 03: Human-in-the-Loop Essay Grading 14](#_rejr9j4pv7rg)

[2.3.4 Use Case Specification 04 : Analyzing Knowledge Gaps and Recommending Roadmaps 18](#_dv03vv5166i9)

[2.3.5 Use Case Specification 05 : 19](#_k4q3bft722ap)

[2.3.6 Use Case Specification 06: Refund processing 20](#_uemab3hxg4g)

[3\. Non-Functional Requirements 22](#_zgk1maukcerz)

[3.1 Performance 22](#_ampi914e5ip8)

[3.2 Security 22](#_mo3fzcjxeoh2)

[3.3 Reliability 22](https://docs.google.com/document/d/14nMfmFHM9NRqSPNBw2QJFGXItH_AeKieNfQsNgppT1k/edit?tab=t.0#heading=h.5mwu0wzi7ql0)

[3.4 Internationalization (i18n) 22](https://docs.google.com/document/d/14nMfmFHM9NRqSPNBw2QJFGXItH_AeKieNfQsNgppT1k/edit?tab=t.0#heading=h.utnw4qb3emga)

[3.5 Scalability 23](https://docs.google.com/document/d/14nMfmFHM9NRqSPNBw2QJFGXItH_AeKieNfQsNgppT1k/edit?tab=t.0#heading=h.l8tw71xe6tei)

# **I. Record of Changes**

|     |     |     |     |
| --- | --- | --- | --- |
| **Date** | **A\*  <br>M, D** | **In charge** | **Change Description** |
| 03/06/2026 | A   | Son Nam | Add Context Diagram, Add Feature Tree |
|     | A   | Kien | Add Contact Modeling |
|     | A   | Tung | Add Data Flow |
|     | A   | Huy | Add Entity relationship diagram |
|     | A   | Tung | Add Entity Class Modeling |
| 03/06/2026 | A   | Son Nam | Add Use Case Modeling for Course Manager |
|     | A   | Kien | Add Use Case Modeling for Teacher |
|     | A   | Tung | Add Use Case Modeling for Students |
|     | A   | Huy | Add Use Case Modeling for SME |
|     | A   | Son Nam | Add Use Case Modeling for Guest, Admin |
|     | A   | Huy, Tung | Add Non Functional Requirements |

\*A - Added M - Modified D - Deleted

**EduNexus: An AI-Integrated Learning & Training Platform**

|     |     |
| --- | --- |
| **Group** | 1   |
| **Version** | 1.0.1 |
| **Updated At** | 20/06/2026 |

# **II. Software Requirement Specification**

## **1\. Requirement Modeling**

### **1.1 Feature Tree**

**FT-01 – Course Structure Management**

- Manage course structure, modules, and content publishing processes.

**FT-02 – Lesson & Material**

- Create lectures, videos, and learning materials with AI support.

**FT-03 – Question Bank**

- Create lectures, videos, and learning materials with AI support.

**FT-04 – Flashcard Builder**

- Create and manage flashcard sets.

**FT-05 – Essay Assignment**

- Create essay assignments and grading criteria.

**FT-06 – Study Lessons & Flashcards**

- Study the lecture notes and practice with flashcards.

**FT-07 – Practice Tests**

- Create a practice test and view the results.

**FT-08 – Assignment Submission & Grading**

- Submit your assignment, receive AI grading, and get final feedback from the instructor.

**FT-09 – Classroom Management**

- Manage the classroom, instructors, and students.

**FT-10 – Course Pricing**

- Manage courses, course groups, and tuition packages.

**FT-11 – Enrollment & Payment**

- Register for the course and process the payment.

**FT-12 – Personal Learning Progress**

- Track your individual learning progress.

**FT-13 – Class Analytics**

- Academic performance, content quality, and revenue reports.

**FT-14 – Authentication & User Profile**

- Register, log in, and manage user profiles.

**FT-15 – System Administration**

- Internal user management, system configuration, and operation.

### **1.2 Context Diagram**

The context diagram describes EduNexus as a completely independent, centralized learning and training platform, not dependent on any external learning management systems (LMS) such as Google Classroom. This platform acts as an intermediary bridge: receiving content, configuration, and class setup from internal actors (Admins, SMEs, Instructors, Course Managers) to facilitate registration, payment, and learning experiences for external actors (Students, Guests). To expand functionality and reduce infrastructure load, EduNexus integrates data only with specialized satellite service systems, including Google Identity (for authentication), OpenAI/Anthropic AI services (to support content generation), YouTube Data API (for video retrieval), and VNPay/SePay payment gateways (for processing cash flow).

**External Entities Description**

|     |     |     |
| --- | --- | --- |
| **Name** | **Type** | **Description** |
| **Guest** | User / Actor | An unauthenticated user who browses the public course catalog, views course details, and participates in limited trial lessons and flashcards. |
| **Student** | User / Actor | A registered user who enrolls in courses, submits payments, interacts with learning materials (quizzes, assignments), and receives personal progress reports. |
| **Course Manager** | User / Actor | An internal user who manages course pricing, creates subscription packages, sets up classes, assigns teachers, and monitors revenue within assigned course groups. |
| **Teacher** | User / Actor | An internal instructor who manages assigned classes, uploads supplemental materials, reviews AI-preliminary grades for essays, and monitors student progress. |
| **Admin** | User / Actor | The system administrator who handles core system configurations, manages internal accounts, creates course structures, processes refunds, and oversees system logs. |
| **Google Identity** | Third-party Service | An external service integration used for processing OAuth 2.0 authentication requests, returning auth tokens and basic user profile details back to the system. |
| **AI Language Model** | Third-party Service | An external AI provider that receives source texts, prompts, and rubrics from the system, returning generated educational content (quizzes, flashcards) and preliminary grades. |
| **YouTube Data API** | Third-party Service | An external video integration service that receives video URLs from the system and returns video metadata and subtitles for AI summarization purposes. |
| **Payment Gateways** | Third-party Service | External electronic payment platforms that receive payment generation requests from the system and return the final transaction status confirmations via webhooks. |

### **1.3 Data Flow Diagram**

#### **1.3.1 Data flow descriptions**

|     |     |     |
| --- | --- | --- |
| Data Flow Name | Description | Record (Data Structure) |
| Original Content | Initiated by SME to submit original course materials (lectures, questions, flashcards, essays) into the system for building a standard course. | SME_ID, Course_ID, Lesson_Title, Content_Type, Content_Body, Version, Status |
| Supplementary Materials | Sent by Teacher to add class-specific materials without affecting the original SME content. | Teacher_ID, Class_ID, Course_ID, Material_Title, Material_Body, Supplementary_Flag |
| Content Data | P1 saves all compiled course content into DS1 Course Content data store. | Course_ID, Module_ID, Content_Type, Content_Body, Version, Published_Status, Created_By |
| AI Request | P1 forwards source materials to P2 with the task type for AI-assisted content generation. | Request_ID, Requester_ID, Task_Type (gen_quiz / gen_flashcard / expand_outline / summarize_video / grade_essay), Source_Content |
| Approved Content | P2 transfers SME/Teacher-approved AI-generated content back to P1 for official storage in DS1. | Draft_ID, Approved_By, Approved_At, Final_Content, Course_ID, Module_ID |
| AI Request / Response | P2 sends a prompt to the external AI Service and receives generated content in return. | Request_ID, Model, Prompt, Max_Tokens, Task_Type, Generated_Content, Token_Consumed, Processing_Time |
| Learning Content | DS1 provides course content (lectures, videos, flashcards, quiz questions) to P3 for student access. | Course_ID, Module_ID, Lesson_Content, Flashcard_Set, Quiz_Pool, Access_Level |
| Sample Content Preview | P3 returns limited sample content to Guest users — maximum 10 questions and 5 flashcards per session, no AI calls permitted. | Session_ID, Content_ID, Sample_Type (question / flashcard), Sample_Count, Session_Expiry |
| Learning Progress | P3 records student learning activity into DS3 after each lesson, quiz attempt, or flashcard session. | Student_ID, Class_ID, Activity_Type, Score, Completion_Status, Time_Spent, Attempt_Count |
| Assignment / Scores | Teacher submits official grades and written feedback for student essay submissions via P3. | Teacher_ID, Essay_ID, Student_ID, Final_Score, Feedback, Graded_At |
| Learning Progress Data | DS3 supplies raw learning progress data to P4 for aggregation and analysis. | Student_ID, Course_ID, Module_Progress_Rate, Avg_Score, Weak_Topics, Last_Active |
| Content Quality Report | P4 sends a content quality report to SME showing questions that are too easy or too hard, low-readership lessons, and high drop-off modules. | Course_ID, Lesson_ID, View_Count, Avg_Score, Drop_Rate, Difficulty_Index |
| Class Overview Report | P4 delivers a class-level report to Teacher showing inactive students, modules with high abandonment, and frequently missed questions. | Teacher_ID, Class_ID, Inactive_Students, Module_Drop_Stats, High_Error_Questions |
| System Report | P4 sends a full system-wide report to Admin covering revenue, completion rates, and user activity. | Admin_ID, Period, Total_Revenue, Avg_Completion_Rate, Active_Users, Token_Consumption |
| Revenue Report | P4 sends an enrollment and revenue report to Course Manager within their assigned course group scope. | Course_Manager_ID, Scope_Group, Enrollment_Count, Revenue_Total, Period |
| Personal Learning Report | P4 returns a personal progress report to Student showing completed lessons, score timeline, and weak areas. | Student_ID, Progress_Rate, Score_Timeline, Weak_Modules, Recommended_Review |
| Registration Information | Guest submits account registration details to P5 for new account creation. | Email, Password_Hash, Full_Name, Phone |
| Enrollment Request | Student submits a class enrollment request to P5 selecting enrollment type H1, H2, or H3. | Student_ID, Class_ID, Enrollment_Type (H1 / H2 / H3), Amount, Payment_Method |
| Learning / Results | P5 returns confirmed access rights and enrollment status back to Student after successful payment. | Student_ID, Course_ID, Access_Status, Expiry_Date, Enrollment_Type |
| Course Configuration Data | Course Manager sends class creation and pricing configuration to P5 within their assigned scope. | Manager_ID, Course_ID, Class_Name, Start_Date, End_Date, Enrollment_Type, Price |
| Payment Information | P5 forwards transaction details to the external Payment Gateway (VNPay / SePay) for processing. | Transaction_ID, Student_ID, Amount, Payment_Method, Order_Info, Timestamp |
| Access Registration | Payment Gateway returns the transaction result to P5 to grant or deny student access. | Transaction_ID, Status (success / failed), Payment_Reference, Processed_At |
| Access Permission Data | DS4 provides enrollment and access status data to P3 to verify whether a student is authorized to access course content. | Student_ID, Course_ID, Class_ID, Access_Status, Expiry_Date |

#### **1.3.2 Data stores descriptions**

|     |     |     |
| --- | --- | --- |
| Data Store Name | Description | Attributes (Entering / Leaving) |
| DS1: Course Content | Central repository storing all compiled course content including lectures, videos, documents, quiz questions, flashcard sets, and essay prompts. Applies a layered model where SME's original content is protected and Teacher additions are class-scoped only. SME updates propagate automatically to all active classes. | Inputs: Content Data (from P1), Approved Content (from P2) Outputs: Learning Content (→ P3), Content Quality Report data (→ P4) |
| DS3: Learning Progress | Tracks each student's learning activity continuously — lessons read, flashcards reviewed, quiz scores over time, essay submissions, time spent, and attempt counts. Data is recorded per activity event. | Inputs: Learning Progress (from P3) Outputs: Learning Progress Data (→ P4), Personal Learning Report data (→ P4 → Student) |
| DS4: Enrollment & Class | Manages all class configurations and student enrollment records across three enrollment types (H1, H2, H3). Automatically grants and revokes content access based on enrollment status and expiry date. Retains learning history, progress, and submissions after expiry. | Inputs: Access Registration result (from P5) Outputs: Access Permission Data (→ P3), Revenue Report data (→ P4 → Course Manager) |

### **1.4 Entity Relationship Diagram**

### **1.5 System static Modeling**

#### **1.5.1 Context Modeling**

This is the context model of the problem domain for the EduNexus System. EduNexus provides a service for several users and integrates with multiple external systems. The system serves various actors, including Admin, SME, Teacher, Student, Course Manager, and Guest, who all interact directly with the EduNexus system.  
For external operations, EduNexus connects with Google Identity to sync rosters and grades. It processes payments through the Payment Gateway external system, which supports VNPay and SePay. To provide advanced capabilities, EduNexus requests AI generation from the LLM Gateway external system (utilizing OpenAI or Anthropic) and fetches transcripts via the YouTube Data API v3 external system.

#### **1.5.2 Entity Classes**

## **2\. Use Case Modelling**

### **2.1 Actors**

|     |     |     |
| --- | --- | --- |
| **STT** | **Actor** | **Description** |
| 1   | **Guest** | These are users who do not yet have an account or have not logged into the EduNexus system. The main goal of the system for Guests is to attract them to become official students. Guests are allowed to access the homepage, browse the public course catalog, search for course information, and preview (demo) a limited number of flashcards and questions to get a feel for the content quality. Finally, they can log in or register an account (via Google OAuth 2.0) to change their role to Student. |
| 2   | **System Admin** | As the highest-level administrator (Super User) in terms of technical and operational aspects of the EduNexus platform, the Admin focuses on the system's "core": managing the internal account lifecycle (creating accounts, assigning permissions to SME, Course Manager, and Teacher), configuring core parameters (AI genmini API call limits, file upload size limits, maximum class size), and monitoring the overall system status (viewing overall revenue reports, checking activity logs, managing background processes). |
| 3   | **WE** | An internal content specialist responsible for creating and maintaining educational materials. This actor uploads raw learning resources, reviews and validates AI-generated content, manages quizzes and flashcards, and ensures the quality and accuracy of learning materials before publication. The SME interacts closely with the integrated AI subsystem to moderate generated outputs, refine educational content, and analyze content quality metrics. All AI-generated results serve only as recommendations, while the final approval and publishing decisions remain under the manual control of the SME. |
| 4   | **Teacher** | An internal staff member responsible for execution of the end-to-end course delivery and classroom management process. This actor utilizes the learning platform to manage class instances, supplement course materials, define assignment rubrics, and communicate directly with students. The Teacher interacts extensively with the integrated AI subsystem to access automated essay pre-grading analysis, view contextual lesson progress data, evaluate rich-text summary study briefs, and leverage student engagement analytics to optimize classroom workflows and identify at-risk learners. All AI outputs serve as non-blocking recommendations, leaving the final grade finalized statuses and communication triggers strictly under the human teacher's manual verification. |
| 5   | **Course Manager** | In the EduNexus system, the Course Manager is an internal agent acting as a business operator, responsible for managing classes and revenue. Unlike the Admin, who has system-wide authority, the Course Manager operates strictly within the scope of specific assigned "course groups." Their main responsibilities include: setting retail prices, creating subscription packages with time limits, directly opening new classes, assigning instructors, and managing student lists. By closely monitoring registration data and reporting revenue, the Course Manager helps the organization optimize the distribution of educational products without interfering with academic expertise. |
| 6   | **Student** | An authenticated primary user responsible for managing their individual learning journey. This actor utilizes the integrated LMS workspace to consume Markdown materials, watch video lectures, and leverage **AI-powered video summarization**. The Student interacts with the assessment subsystem to take practice quizzes with instant feedback, track essay rubrics/deadlines, and submit assignments. Additionally, the agent uses the commercial gateway to process automated QR-code payments for course enrollments (H1, H2, or H3 packages). On the performance side, the Student accesses a personal analytics dashboard featuring an **AI-driven weakness analysis** that automatically scans learning logs, detects knowledge gaps, and renders a personalized 3-step recommendation roadmap to optimize study outcomes. |

### **2.2 UC Diagrams**

#### **_2.2.1 UCs for Guest_**

_Figure 1-1: Detailed Use Case Diagram for Guest_

#### **_2.2.2 UCs for_ System Admin**

_Figure 1-2: Detailed Use Case Diagram for System Admin_

#### **_2.2.3 UCs for_ WE**

_Figure 1-3: Detailed Use Case Diagram for SME_

#### **_2.2.4 UCs for Students_**

_Figure 1-4: Detailed Use Case Diagram for Students_

#### **_2.2.5 UCs for Teacher_**

_Figure 1-5: Detailed Use Case Diagram for Teacher_

#### **_2.2.6 UCs for_ Course Manager**

_Figure 1-6: Detailed Use Case Diagram for Course Manager_

### **2.3 Activity Diagram**

#### **_2.3.1_ Use Case Specification 01 (Guest ): Register/Login via Google OAuth**

**Summary:**Visitors can use their personal Google account to quickly register or log in to the EduNexus platform without needing to create a separate password.

**Dependency:** As shown in the use case diagram.

**Actors:**

- **Primary Actor: Guest**
- **Secondary Actor: Google Identity Services (API-04)**

**Preconditions:** This visitor is accessing the EduNexus homepage or course catalog page and is not logged in.

**Main sequence:** As shown in the swimlane diagram.

**Alternative sequences:** As shown in the swimlane diagram.

**Postcondition:**The user's account is successfully created in the database (if it's a new user), the login session is initiated, and the user is granted Student privileges.

**Activity Diagram**

**Class Diagram**

#### **_2.3.2_ Use Case Specification 02 (SME): AI-assisted Content Review and Approval**

**Summary:** This use case enables the internal Subject Matter Expert (SME) to review, refine, and approve educational content generated by the integrated AI subsystem. The workflow combines automated AI content generation with manual validation to ensure the quality, consistency, and pedagogical accuracy of quizzes and flashcards before publication. AI-generated outputs act only as recommendations, while final approval remains under the control of the SME.

**Dependency:** As presented in the Use Case Diagram.  
UC-S01: Upload Raw Materials.

UC-S02: Generate Content by AI.

FE-04: AI Core Services.

FE-05: Content Creation & Teaching.

**Actors:**

- **Primary Actor:** WE
- **Secondary Actors:** AI Engine

**Preconditions:**

The SME account is valid and authenticated.

The SME has permission to access the Content Moderation Workspace.

Raw learning materials have been uploaded successfully.

The AI subsystem is available and able to process requests.

**Main Sequence:** As presented in the swimlane**.**

1.  \-The SME enters the Content Management Workspace.
2.  \-The SME uploads raw educational materials, including PDF files, Word documents, text files, or video transcripts.
3.  \-The system validates the uploaded resources.
4.  \-The system sends the source materials to the external AI Engine.
5.  \-The AI subsystem generates quizzes and flashcards from the source materials.
6.  \-The system displays the generated content inside the Moderation Station.
7.  \-The SME reviews the generated questions and flashcards.
8.  \-The SME edits, removes, or supplements content if necessary.
9.  \-The SME verifies the educational quality and consistency of the generated outputs.
10. \-The SME selects the "Approve Content" action.
11. \-The system stores the approved content in the database.
12. \-The system records the operation in the activity logs.
13. \-The content becomes available for learners and instructors.

**Alternative Sequences:** As presented in the swimlane**.**

AI Service Failure

Condition:

The external AI Engine fails to respond within the predefined timeout period or returns invalid data.

Alternative Flow:

1.  The system displays an error notification.
2.  No content is published automatically.
3.  The uploaded source materials remain stored in the repository.
4.  The SME may retry the generation process later.

Content Rejection

Condition:

The generated content contains inaccurate or low-quality information.

Alternative Flow:

1.  The SME rejects the generated outputs.
2.  The system marks the content status as "Rejected".
3.  The SME edits the source materials or regenerates content.
4.  The review cycle continues until satisfactory quality is achieved.

**Postconditions:**

Success

- Quiz and flashcard contents are approved.
- Content status changes to APPROVED.
- Approved materials are stored permanently.
- Activity logs are updated.

Failure

- Content remains in DRAFT or REJECTED status.
- No content is published to learners.
- All transactions are recorded in the audit logs.

**Activity Diagram**

**  
Class Diagram**

#### **_2.3.3_ Use Case Specification 03 (Teacher): Human-in-the-Loop Essay Grading**

**Summary:**

- This use case allows the internal teacher actor to review, evaluate, and finalize student essay submissions within the dedicated grading workspace. The workflow integrates an advanced automated AI pre-grading model that evaluates submissions based on preset rubric criteria. The AI output acts as a hidden, non-blocking reference draft, leaving the absolute final grade validation and publication under the manual verification of the human teacher.

**Dependency:**

- - UC-T08: Configure Essay Task & Rubric (System requires structural validation of rubric criteria weights to process grading).
    - UC-T02: Author Markdown Lesson / UC-T03: Embed YouTube Video.

**Actors:**

- - Primary Actor: Teacher.
    - Supporting Actor: AI Engine(The AI ​​subsystem processes data in the background).

**Preconditions:**

- - The Teacher account is valid, authenticated via system protocols, and explicitly assigned by the Admin to manage the target class instance .
    - An essay assignment has been successfully published with an active, locked evaluation matrix whose cumulative rubric criteria weight equals exactly 100% .
    - A student has submitted an essay (maximum 20,000 characters), changing the submission status to SUBMITTED , which automatically triggers an in-app alert notification to the teacher.

**Main Sequence:**

- - The Teacher navigates to the class management dashboard, enters the internal "Commercial Gradebook", and opens the essay assignment's grading queue.
    - The Teacher selects a specific student portfolio currently marked as "Pending Evaluation".
    - The system automatically triggers the mandatory included action (**UC-T08**) to pull the associated assignment's rubric parameters (criteria names, maximum scores, and percentage weights).
    - The system securely packages the student's raw text alongside the rubric data and initiates an asynchronous payload token request to the external LLM Gateway (OpenAI / Anthropic).
    - Within 5 seconds , the system renders a side-by-side split screen interface displaying: the student's submission text, the AI-generated preliminary evaluation scores mapped to each criterion, and structural justification feedback.
    - The Teacher reviews the submission text, reads the contextual AI draft recommendations (which remain fully hidden from student views per , and manually inserts the actual scores onto the input form field.
    - The Teacher appends comprehensive qualitative feedback notes and clicks the **"Finalize and Sign Off Grades"** action button.
    - The system writes the transaction state changes to the PostgreSQL 16 database, appends transactional records to the immutable system activity logs , updates the progress data cache, and dynamically triggers an outbound message broadcast to release the official scores and teacher commentary to the student.

**Alternative Sequence (AI Fallback Mode):**

- - _Condition:_ The integrated external LLM Gateway fails to respond within the hard-coded 30-second window, triggers a rate quota throttle warning , or returns a corrupted payload mismatching the required JSON schema schema boundary.
    - The core transaction is immediately rolled back inside the database layer, preventing token calculations or staging pool corruption.
    - The system completely bypasses the automated pre-evaluation workflow, maintaining a minimum 99.5% core runtime availability uptime constraint for non-AI tasks .
    - The interface automatically activates an overlay maintenance system banner notifying the teacher: _"AI evaluation timeout/invalid - Reverting to manual grading"_.
    - The system opens a clean grading workspace template populated only with the raw student submission text and empty, adjustable rubric entry inputs.
    - The Teacher proceeds with manual entry evaluation, scores the fields from scratch, types feedback, and commits the changes using the standard manual validation workflow.

**Postconditions:**

- - The student's entry status updates atomically to FINALIZED inside the gradebook repository.
    - The submission is permanently locked against further adjustments, data overwrites, or secondary re-submissions from the student interface .
    - The evaluation details (individual criterion breakdown scores and formal teacher feedback notes) are unlocked for student visibility, while the original template remains strictly shielded inside the admin data layer.

**Activity Diagram:**

**Class Diagram**

#### **_2.3.4_ Use Case Specification 04 (Student): Analyzing Knowledge Gaps and Recommending Roadmaps**

**Summary:**

- While reviewing their learning progress on the analytics platform, a registered H3-tier student decides to evaluate their overall competency. The student triggers the analysis request. The system aggregates the student's historical learning logs (including quiz performance, flashcard mastery, and essay scores) and collaborates with the AI Subsystem to diagnose specific knowledge deficiencies, instantly returning a highly accurate breakdown of their primary knowledge gap along with an actionable 3-step study roadmap.

**Dependency:** As shown in the use case diagram**.**

**Actors:**

- **Primary Actor:** Student**.**

**Preconditions:**

- The student has successfully logged into an active H3-tier account and accessed the Learning Analytics Dashboard (SCR-08).

**Main Sequence:** As shown in the swimlane diagram**.**

**Alternative Sequences:** As shown in the swimlane diagram**.**

**Postconditions:**

- The student is currently executing Use Case _"View Learning Analytics"_ and the AI-generated insight boxes, competency charts, and tailored roadmaps are fully rendered on the screen. The system has successfully cached the AI response metrics in the database for the next 24 hours.

**Activity Diagram:**

**Class Diagram:**

  
**_2.3.5_ Use Case Specification 05 (System Admin): Configure System Parameters (AI Quota)**

**Summary:** Admins configure critical system parameters, particularly setting and allocating monthly AI usage limits (AI Quota) to internal staff to control API costs.

**Dependency:**

**Actors:**

- **Primary Actor:** System Admin

**Preconditions:** The admin has logged in using a Super User account.

**Main Sequence:** As shown in the swimlane diagram**.**

**Alternative Sequences:** As shown in the swimlane diagram**.**

**Postconditions:**The system rules have been updated. From now on, all AI calls from SMEs/teachers will be blocked if they exceed the newly established limits.

**Activity Diagram:**

**Class Diagram:**

#### **_2.3.6_ Use Case Specification 06 (Course Manager): Refund processing**

**Summary:**

- Course Manager reviews a student's refund request and decides whether to approve or reject the request. If approved, the system revokes the student's course access and processes the refund transaction.

**Dependency:** As shown in the use case diagram.

**Actors:**

- **Primary Actor:** Course Manager
- **Secondary Actor:** Student, Payment Gateway (VNPay / SePay)

**Preconditions:**

1.  Student has purchased a course or subscription package.
2.  Student has submitted a refund request.
3.  Course Manager is authenticated.
4.  Refund request exists in the system.

**Main sequence:** As shown in the swimlane diagram.

**Alternative sequences:** As shown in the swimlane diagram.

**Postcondition:**

- Success
    - Refund status = Completed
    - Student access revoked
    - Payment refunded
    - Refund history recorded
- Failure
    - Refund request status updated appropriately
    - Audit log recorded

**Activity Diagram**

**Class Diagram**

## **3\. Non-Functional Requirements**

### **3.1 Performance**

**NFR-P01 — Page Load Time** All primary pages (course catalog, lesson viewer, quiz interface) must fully render within 3 seconds under normal load conditions (up to 500 concurrent users per class instance as defined in LI-07).

**NFR-P02 — AI Response Time** AI-assisted content generation requests (quiz generation, flashcard creation, essay pre-grading) must return a response within 30 seconds. If the external AI service (OpenAI / Anthropic) fails to respond within this hard-coded timeout window, the system must immediately roll back the transaction and activate fallback mode without affecting non-AI features.

**NFR-P03 — Payment Processing** Payment transactions initiated through VNPay or SePay must complete the full request-response cycle within 10 seconds. The system must handle webhook callbacks asynchronously to avoid blocking the main application thread.

**NFR-P04 — Dashboard Rendering** The Student personal analytics dashboard and Teacher class overview report must load aggregated data within 5 seconds. AI-generated knowledge gap analysis results may be cached for up to 24 hours to reduce repeated LLM Gateway calls and token consumption.

**NFR-P05 — Database Query** All standard CRUD operations against PostgreSQL 16 must execute within 500 milliseconds under normal operating conditions on the target infrastructure (single VPS: 4 vCPU, 8GB RAM).

### **3.2 Security**

**NFR-S01 — Authentication** The system must support two authentication mechanisms: Email/Password (self-managed with bcrypt hashing) and Google OAuth 2.0 SSO via Google Identity. All sessions must be managed using short-lived JWT access tokens combined with refresh token rotation.

**NFR-S02 — Authorization & Role Isolation** Access control must be enforced at the API layer using role-based access control (RBAC). Each role (Guest, Student, Teacher, SME, Course Manager, Admin) must be strictly isolated — a Course Manager must only access data within their assigned course group scope, and a Teacher must only access their assigned class instances. Unauthorized cross-role access attempts must be logged and rejected with HTTP 403.

**NFR-S03 — Data Privacy** No personally identifiable information (PII) — including student names, emails, or phone numbers — may be written to system logs or transmitted to external AI services (OpenAI / Anthropic). Source materials sent to the LLM Gateway must be sanitized to remove personal identifiers before dispatch.

**NFR-S04 — Payment Security** All payment flows must be processed exclusively through certified third-party gateways (VNPay, SePay). EduNexus must not store raw card numbers or banking credentials at any layer. Transaction records must be immutable once committed to the database.

**NFR-S05 — Activity Audit Logging** All critical operations — including AI content generation, essay grade finalization, enrollment changes, refund processing, and admin account modifications — must be recorded in an immutable audit log containing the actor ID, action type, timestamp, and affected resource ID.

**NFR-S06 — Guest Session Isolation** Guest session data must not be persisted to the database. Sample content interactions (maximum 10 questions and 5 flashcards per session) must be tracked only in-memory for the duration of the session.

### **3.3 Reliability**

**NFR-R01 — System Availability  
**The EduNexus platform must maintain at least 99.5% availability for core learning and enrollment functions. Temporary failures of external AI services must not interrupt non-AI features.

**NFR-R02 — Fault Tolerance  
**In case of AI service timeout or invalid responses, the system must automatically activate fallback mode and allow users to continue manual operations without data loss.

**NFR-R03 — Data Integrity  
**Critical transactions, including payments, enrollments, essay grading, and refunds, must be executed atomically to prevent inconsistent or corrupted records.

### **3.4 Internationalization (i18n)**

**NFR-I01 — Multi-language Support  
**The system architecture must support internationalization (i18n), allowing user interface texts and messages to be displayed in multiple languages.

**NFR-I02 — Unicode Compatibility  
**All textual content stored in PostgreSQL 16 must support UTF-8 encoding to ensure compatibility with Vietnamese and other international languages.

### **3.5 Scalability**

**NFR-SC01 — Concurrent Users  
**The system must support at least 500 concurrent users per class instance under normal operating conditions.

**NFR-SC02 — Horizontal Growth  
**The architecture must allow future expansion of application services and databases without requiring major redesign.

**NFR-SC03 — AI Response Caching  
**Frequently accessed AI-generated analytics and recommendation results may be cached for up to 24 hours to reduce token consumption and improve system throughput.