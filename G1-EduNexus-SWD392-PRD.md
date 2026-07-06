**Product Requirements Document**

**_Edu Nexus – Report 3_**

|     |     |
| --- | --- |
| Version | _1.0.0_ |
| Date | _20/06/2026_ |

# **Change Log**

|     |     |     |     |
| --- | --- | --- | --- |
| **Version** | **Date** | **Author** | **Summary** |
| 1.0 | 24/06/2026 | Son Nam | Do the following part:<br><br>+) Business Flows<br><br>+) User Requirement: 3.1, 3.2, 3.4, Usecase diagram for Course Manager<br><br>+) Functional Requirements: 4.1, 4.3, 4.4<br><br>+) Global Business Rules<br><br>+) Non-Functional Requirement: 6.3, 6.4 |
| 1.0 | 24/06/2026 | It was | +) Functional Requirements: 4.2<br><br>+) User Requirement: Usecase diagram for Teacher |
| 1.0 | 24/06/2026 | Tung | +) User Requirement: Usecase diagram for Student |
| 1.0 | 24/06/2026 | Huy | +) User Requirement: Usecase diagram for SME<br><br>+) Conceptual Data Model |
| 1.0 | 04/07/2026 | Son Nam | +) User Requirement: Usecase diagram for Admin, Guest<br><br>+) Non-Functional Requirement: 6.1, 6.2 |

Table of Content

[**Change Log 1**](#_uoh3cqjz7fil)

[**1\. Business Flows (Son Nam) 3**](#_vao8c745kx4k)

[1.1 Overview 3](#_w3dzvkaxa7rb)

[a. Context Diagram 3](#_v1qngk243g0k)

[b. Business Flow Index 3](#_92jb41twe3q)

[1.2 SC-01: Course Content Development & Publishing 4](#_h5d8addjivin)

[1.3 SC-02: Opening a Class & Setting Participation Requirements 6](#_j7vk1hchbdo5)

[1.4 SC-03: Registration & Enrollment for the Course 8](#_adgfq1cypuep)

[1.5 SC-04: Learning, Practicing & Assessment 10](#_yre6hufwji8j)

[1.6 SC-05: Classroom Operation & Monitoring 13](#_27n5wol2wovz)

[**2\. Conceptual Data Model (Sy Huy) 14**](#_4ls7pn41ru2e)

[2.1 Entity Relationship Diagram 14](#_atqpfbi1o6kd)

[2.2 Entity List 15](#_j7g7zfh7qhsq)

[a. Entity: User 15](#_swb9b1zfmgzt)

[b. Entity: Course 15](#_x2n5kjmogjdy)

[c. Entity: Module 16](#_lf9noaovnjk)

[d. Entities:Lesson 16](#_8rpqzrzddmxr)

[e. Entities:Enrollment 17](#_7xl4y1lgvo8r)

[f. Entities:Flashcard Deck 18](#_r1b4ojski229)

[g. Entities:Flashcard 18](#_7069zopfplo6)

[h. Entities:Quiz 18](#_eo2errzkwiz)

[i. Entities:Question 19](#_l2pysmg0xk28)

[k. Entities:Quiz Attempt 19](#_tu2rl3gkm7bw)

[m. Entities:Assignment 20](#_ag9xa6asd44q)

[n. Entities:Submission 20](#_uvyedoyb3j8v)

[l. Entities:Payment 21](#_u6hs3a1t3zlf)

[o. Entities:Course Group 21](#_tyvgvn97tgzu)

[2.3 Data Business Rules 21](#_remj3xmoa3b5)

[**3\. User Requirements (Son Nam) 23**](#_rn8r1yaytweu)

[3.1 Actor Definitions 23](#_5o1jt2k497yd)

[3.2 Permission Matrix 24](#_uq7hit82ncle)

[3.3 Use Case Diagrams 26](#_2ixtl1xyayi9)

[a. UCs for Guest 27](#_c13o0ohb478i)

[b. UCs for Student 27](#_lgj5truxjdc8)

[c. UCs for Teacher 27](#_ky3t5uq9qvc6)

[d. UCs for SME 28](#_1zyepjax311w)

[e. UCs for Course Manager 29](#_4oqf0orznj2r)

[f. UCs for Admin 30](#_7ca2ssunszjk)

[3.4 Use Case Index 31](#_kbxgm6v8pngy)

[**4\. Functional Requirements 39**](#_j186k8azncj5)

[4.1 Modules & Features (Son Nam) 39](#_7cvtfno3irkb)

[a. Module List 39](#_u6j8foasytnz)

[b. Module: Content Manager 40](#_6dsr599xpoz9)

[c. Module: Learning 41](#_85hat1wu763a)

[d. Modules: ClassRoom and Business 42](#_ti33d2dgg0w4)

[e. Modules: Analytics 43](#_n5efd242hfy2)

[f. Modules: User Manager 43](#_2wtekfboscp2)

[g. Modules: System Admin 44](#_wt6mkng5rdh1)

[x. Won't-Have (This Version) 44](#_j5uyduattfcn)

[4.2 Screen Inventory (Former) 45](#_4gmvv5vf79me)

[a. Screen Flow 45](#_2v7aeeinhtf2)

[b. Screen List 45](#_5fsbdshx90hj)

[4.3 External API Inventory (Son Nam) 51](#_8yieoj9lgnt4)

[4.4 Background Job Inventory (Son Nam) 52](#_75mluj6efqgp)

[**5\. Global Business Rules(Son Nam) 53**](#_z5sre1g0gye5)

[5.1 Global Business Rule Table 53](#_xdjsmfig2qw5)

[**6\. Non-Functional Requirements & Constraints (Sơn Nam) 55**](#_bpk44r3qapcm)

[6.1 Performance Requirements 55](#_8qksjgb2g9fy)

[6.2 Security Requirements 56](#_95hg54ddnl0i)

[6.3 Out of Scope 57](#_unjdmwwn5c0s)

[6.4 Technical Assumptions 57](#_nfgmncz1y7fv)

# **1\. Business Flows (Son Nam)**

## **1.1 Overview**

### **a. Context Diagram**

### **b. Business Flow Index**

|     |     |     |     |     |
| --- | --- | --- | --- | --- |
| **BF-ID** | **Flow Name** | **Primary Actors** | **Trigger** | **End Condition** |
| SC-01 | Course Content Development & Publishing | Admin, SME, Teacher | There are no courses in the system yet, or the content of existing courses needs updating. | The course content is complete, published, and ready for use. |
| SC-02 | Open Class & Set Participation Requirements | Admin, Course Manager | At least one course has been published. | The class is ready for registration; the entry requirements have been fully established. |
| SC-03 | Register & Enroll in the Course | Students | There are classes or courses open for registration. | Students have an account and access to their chosen course. |
| SC-04 | Learn, Practice & Evaluate | Student, Teacher | The student has been granted access to the course. | Students complete the course content, tests, and assignments; the results are recorded. |
| SC-05 | Classroom Operation & Monitoring | Teacher, Course Manager, Admin | The class has started and is currently running. | The class ran smoothly; any problems that arose were handled promptly. |

## **1.2 SC-01: Course Content Development & Publishing**

**_Swimlane:_**

**_Trigger_**There are no courses in the system yet, or the content of existing courses needs updating.

**_End condition_**The course content is complete, published, and ready for use.

|     |     |     |     |     |
| --- | --- | --- | --- | --- |
| **Step** | **Actor** | **Action** | **FT-ID** | **UC-ID** |
| 1   | Admin | Create a course in the system and assign a content expert to be responsible for its creation. | FT-01, FT-15 | UC-57 |
| 2   | WE  | Content experts begin building the curriculum in a modular, lesson-based manner. | FT-01 | UC-08, UC-09 |
| 3   | Gemini | AI Gemini supports expanding syllabi into complete lectures. | FT-02 | UC-08 |
| 4   | WE  | Experts review and refine the results before use. | FT-02 | UC-09 |
| 5   | WE,<br><br>Teacher | Experts develop training resources and evaluation criteria. | FT-03, FT-04, FT-05 | UC-11, UC-65 |
| 6   | WE  | Thanks to AI suggestions and approval for each sentence. | FT-03, FT-04 | UC-13, UC-14 |
| 7   | WE  | Publish the course when the content is complete. | FT-01 | UC-10 |
| 8   | Teacher | You can add more materials to the class you teach. | FT-02 | UC-08, UC-10 |
| 9   | WE  | When updated content needs to be updated, the expert temporarily unlocks it, edits it, and republishes it. | FT-01 | UC-10 |
| 10  | EduNexus System | Record session changes | FT-01 | UC-51 |

## **1.3 SC-02: Opening a Class & Setting Participation Requirements**

**_Swimlane:_**

**_Trigger_**At least one course has been published.

**_End condition_**The class is ready for registration; the participation requirements have been fully established.

|     |     |     |     |     |
| --- | --- | --- | --- | --- |
| **Step** | **Actor** | **Action** | **FT-ID** | **UC-ID** |
| 1   | Admin,<br><br>Course Manager | Create a new class on EduNexus. | FT-09 | UC-16 |
| 2   | Admin,<br><br>Course Manager | Assign an instructor to teach the class. | FT-09 | UC-17 |
| 3   | Teacher | Add relevant documentation (without affecting the original content). | FT-02 | UC-08, UC-10 |
| 4   | Course Manager | Set price conditions for participating in the course content. | FT-10 | UC-27 |
| 5   | Admin | Establish the course group structure and assign a Course Manager to each group. | FT-10, FT-15 | UC-58, UC-56 |
| 6   | Admin | If the class is free, the admin will add students directly. | FT-09 | UC-24 |
| 7   | Student | If the class is paid, students register and pay for it themselves. | FT-11 | UC-03 |

## **1.4 SC-03: Registration & Enrollment for the Course**

**_Swimlane:_**

**_Trigger_**There are classes or courses open for registration.

**_End condition_**Students have an account and access to their chosen course.

|     |     |     |     |     |
| --- | --- | --- | --- | --- |
| **Step** | **Actor** | **Action** | **FT-ID** | **UC-ID** |
| 1   | Students | Visit EduNexus, create an account, or log in. | FT-14 | UC-01 |
| 2   | Students | View the list of publicly available courses; you can preview content that is restricted. | FT-01, FT-02 | UC-61, UC-62, UC-63 |
| 3   | Students | If you receive an invitation from the Admin, simply check your email and wait for the system to verify. | FT-09, FT-14 | UC-24, UC-01 |
| 4   | Students | If you are not invited, choose a suitable course and select a suitable participation method. | FT-11 | UC-03 |
| 5   | Students | Start the payment process | FT-11 | UC-03 |
| 6   | VNPay / SePay | Record the payment and send it to the system. | FT-11 | UC-03 |
| 7   | EduNexus System | The system verifies and grants access. | FT-11 | UC-03 |

## **1.5 SC-04: Learning, Practicing & Assessment**

**_Swimlane:_**

**_Trigger:_**The student has been granted access to the course.

**_End condition:_**Students complete the course content, tests, and assignments, and their results are recorded.

|     |     |     |     |     |
| --- | --- | --- | --- | --- |
| **Step** | **Actor** | **Action** | **FT-ID** | **UC-ID** |
| 1   | Student | Students access the theory learning page and begin their studies. | FT-06 | UC-04 |
| 2   | EduNexus System | Update your learning progress on the Module progress bar. | FT-06 | UC-04 |
| 3   | Student | If students practice after learning the theory: They can use flashcards, create their own tests, etc. | FT-06, FT-07 | UC-04, UC-05 |
| 4   | EduNexus System | Assist in grading students' self-study exercises. | FT-07 | UC-05 |
| 5   | Student | Students receive their self-study results from the system. | FT-07 | UC-05 |
| 6   | Student | Without practice: Students complete essay-type assignments (reading the prompt and evaluation criteria, etc.). | FT-08 | UC-06 |
| 7   | EduNexus System | The system automatically assigns preliminary scores based on criteria. | FT-08 | UC-42, UC-43 |
| 8   | Teacher | Review your submission and the system's results. Make adjustments if necessary and confirm your score. | FT-08 | UC-41, UC-44, UC-40 |
| 9   | Student | Students receive notifications and can view their scores along with teacher comments. | FT-08 | UC-06 |

## **1.6 SC-05: Classroom Operation & Monitoring**

**_Swimlane:_**

**_Trigger:_** The class has started and is currently running.

**_End condition:_** The class ran smoothly; any problems that arose were handled promptly.

|     |     |     |     |     |
| --- | --- | --- | --- | --- |
| **Step** | **Actor** | **Action** | **FT-ID** | **UC-ID** |
| 1   | Teacher | Track the progress of the classes daily. | FT-13 | UC-45 |
| 2   | Teacher | View the list of essays awaiting grading and processing in order. | FT-08 | UC-46 |
| 3   | Teacher | Send notifications to students as reminders. | FT-09 | UC-46 |
| 4   | Course Manager | Track registrations and revenue in real time. | FT-13 | UC-34, UC-36 |
| 5   | Course Manager | Adjust the maximum class size or extend the class duration. | FT-09 | UC-19, UC-21 |
| 6   | Course Manager | Receive and process refund requests from students. | FT-11 | UC-38 |
| 7   | Admin | View the overall system report. | FT-10 | UC-59 |
| 8   | Admin | Handle escalating issues from the Course Manager or Teacher. | FT-15 | UC-52 |
| 9   | Admin | Adjust system configurations as needed. | FT-15 | UC-49, UC-50 |

# **2\. Conceptual Data Model (Sy Huy)**

## **2.1 Entity Relationship Diagram**

## **2.2 Entity List**

### **a. Entity: User**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Stores all platform users including Admin, SME, Course Manager, Teacher, and Student. |
| Key business attributes | Full Name, Email, Password, Role, Status |
| Business identity | User_ID |
| Status / lifecycle | Active → Locked → Inactive |
| FT-ID ref | FT-01, FT-15 |

### **b. Entity: Course**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Represents an educational course created and managed within EduNexus. |
| Key business attributes | Title, Description, Price, Status |
| Business identity | Course_ID |
| Status / lifecycle | Draft, Published, Archived |
| FT-ID ref | FT-02, FT-09 |

### **c. Entity: Module**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Groups lessons into logical learning units within a course. |
| Key business attributes | Module Name, Order Number |
| Business identity | Module_ID |
| Status / lifecycle | Active |
| FT-ID ref | FT-02 |

### **d. Entities:Lesson**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Stores learning materials, videos, summaries, and lesson content. |
| Key business attributes | Lesson Name, Video URL, Summary, Content |
| Business identity | Lesson_ID |
| Status / lifecycle | Draft, Published |
| FT-ID ref | FT-02, FT-06 |

**d. Entities:Class**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Represents a specific course offering with a teacher, schedule, and enrolled students. |
| Key business attributes | Class Name, Start Date, End Date, Status |
| Business identity | Class_ID |
| Status / lifecycle | Planned, Active, Completed, Expired |
| FT-ID ref | FT-09 |

### **e. Entities:Enrollment**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Records student enrollment and learning progress within a class. |
| Key business attributes | Enrollment Date, Progress |
| Business identity | Enrollment_ID |
| Status / lifecycle | Active, Completed, Cancelled |
| FT-ID ref | FT-11 |

### **f. Entities:Flashcard Deck**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Groups flashcards into learning collections. |
| Key business attributes | Deck Name, Category |
| Business identity | Deck_ID |
| Status / lifecycle | Draft, Published |
| FT-ID ref | FT-04 |

### **g. Entities:Flashcard**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Stores individual flashcard content. |
| Key business attributes | Front Text, Back Text |
| Business identity | Card_ID |
| Status / lifecycle | Active |
| FT-ID ref | FT-04 |

### **h. Entities:Quiz**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Represents a quiz used for assessment and practice. |
| Key business attributes | Quiz Name, Difficulty |
| Business identity | Quiz_ID |
| Status / lifecycle | Draft, Published |
| FT-ID ref | FT-07 |

### **i. Entities:Question**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Stores quiz questions and answer options. |
| Key business attributes | Content, Options A-D, Correct Answer, AI Explanation |
| Business identity | Question_ID |
| Status / lifecycle | Active |
| FT-ID ref | FT-07 |

### **k. Entities:Quiz Attempt**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Stores quiz results submitted by students. |
| Key business attributes | Score, Start Time, Submit Time |
| Business identity | Attempt_ID |
| Status / lifecycle | In Progress, Submitted |
| FT-ID ref | FT-07 |

### **m. Entities:Assignment**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Represents essay assignments issued to a class. |
| Key business attributes | Title, Description, Max Score, Due Date |
| Business identity | Assignment_ID |
| Status / lifecycle | Draft, Published, Closed |
| FT-ID ref | FT-08 |

### **n. Entities:Submission**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Stores student essay submissions and grading results. |
| Key business attributes | Essay Content, File URL, Score, Feedback |
| Business identity | Submission_ID |
| Status / lifecycle | Submitted, Graded |
| FT-ID ref | FT-08 |

### **l. Entities:Payment**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Records course registration payments. |
| Key business attributes | Amount, Method, Status, Payment Date |
| Business identity | Payment_ID |
| Status / lifecycle | Pending, Paid, Refunded, Failed |
| FT-ID ref | FT-11 |

### **o. Entities:Course Group**

|     |     |
| --- | --- |
| **Field** | **Value** |
| Purpose | Groups courses under a specific Course Manager. |
| Key business attributes | Group Name, Description |
| Business identity | Group_ID |
| Status / lifecycle | Active, Archived |
| FT-ID ref | FT-10 |

## **2.3 Data Business Rules**

|     |     |     |
| --- | --- | --- |
| **Rule** | **Description** | **Enforced On** |
| Unique email | No two users may share the same email address. | User registration |
| Unique course title within group | Course titles must be unique within the same Course Group. | Course creation |
| One enrollment per class | A student may not enroll in the same class more than once. | Enrollment |
| Enrollment requires active class | Students may only enroll in classes with status Active. | Enrollment |
| One payment per enrollment transaction | Each enrollment must be linked to exactly one successful payment record unless the class is free. | Payment |
| Course requires at least one module | A course cannot be published without at least one module. | Course publishing |
| Module requires at least one lesson | A module must contain at least one lesson before publication. | Module publishing |
| Quiz requires at least one question | A quiz cannot be published without questions. | Quiz publishing |
| One correct answer per question | Each question must have exactly one correct answer. | Question management |
| Assignment due date validation | Assignment due date must be later than the creation date. | Assignment creation |
| Submission before deadline | Students may only submit assignments before the due date. | Submission |
| Quiz attempt ownership | Students may only view their own quiz attempts. | Quiz review |
| Flashcard belongs to one deck | Each flashcard must belong to exactly one flashcard deck. | Flashcard management |
| Immediate access revocation | When a class expires, student access to course content is automatically revoked. | Access control |
| Course deletion restriction | A course with active classes or active enrollments cannot be deleted. | Course management |
| Course Group authorization | Course Managers and SMEs may only manage courses assigned to their Course Group. | Authorization |
| AI quota enforcement | AI-generated content actions must not exceed the monthly quota assigned by Admin. | AI features |
| Internal roles cannot self-register | SME, Teacher, and Course Manager accounts may only be created by Admin. | User management |

# **3\. User Requirements** **(Son Nam)**

## **3.1 Actor Definitions**

|     |     |     |     |
| --- | --- | --- | --- |
| **Actor** | **Description** | **Sign-in Required** | **Notes** |
| Admin | Manage accounts and system-wide permissions; create and configure courses; set up course groups and assign Course Managers; view system-wide reports; process refunds; configure the system. | Yes | You have to create it yourself through the system; you can't register online. |
| WE  | Full authority to create content for assigned courses: lectures, videos, materials, questions, flashcards, and essay assignments. Publish and update course content. | Yes | Accounts are only granted by the Admin. |
| Course Manager | Set prices, create classes, and create subscription packages within the assigned course group; monitor revenue and registration status. | Yes | Only perform actions within the assigned course group. Account updates are only possible from the Admin. |
| Teacher | Supplementing class materials; grading and verifying essay results; monitoring student progress; teaching the class. | Yes | Accounts are only granted by the Admin. |
| Student | Study lectures, review flashcards, take tests, submit essays; register for and pay for courses; view your personal learning progress. | Yes |     |
| Guest | View the publicly available course catalog; try up to 10 sample questions and 5 flashcards; do not access full content or AI features. | No  | No AI features are allowed; you can try a maximum of 10 sample questions and 5 sample flashcards; exceeding this limit will take you to the registration page. |

## **3.2 Permission Matrix**

_Full = unrestricted ·_

_Restricted = conditions apply (see footnotes) ·_

_No = denied_

|     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Entity** | **Action** | **Admin** | **WE** | **Course Manager** | **Teacher** | **Student** | **Guest** |
| User account | Create | Full<sup>(1)</sup> | No  | No  | No  | No  | Full<sup>(2)</sup> |
| User account | Edit / Deactivate | Full | Restricted_<sup>(3)</sup>_ | Restricted_<sup>(3)</sup>_ | Restricted_<sup>(3)</sup>_ | Restricted_<sup>(3)</sup>_ | No  |
| Course | Create / Edit | Full | Restricted<sup>(4)</sup> | No  | No  | No  | No  |
| Course | Publish / Change status | Full | Restricted <sup>(5)</sup> | No  | No  | No  | No  |
| Course | View | Full | Full | Full | Full | Restricted<sup>(6)</sup> | Restricted<sup>(6)</sup> |
| Class | Create / Edit | Full | No  | Restricted<sup>(7)</sup> | No  | No  | No  |
| Class | View | Full | Full | Restricted<sup>(7)</sup> | Restricted<sup>(8)</sup> | Full | Full |
| Enrollment | Submit / Pay | No  | No  | No  | No  | Full | No<sup>(9)</sup> |
| Enrollment | Update status / Refund | Full | No  | Restricted<sup>(10)</sup> | No  | No  | No  |
| Assignment / Quiz / Question Bank | Create / Edit | No  | Full<sup>(11)</sup> | No  | Restricted<sup>(12)</sup> | No  | No  |
| Submission | Submit | No  | No  | No  | No  | Full | No  |
| Submission | Grade / Evaluate | No  | No  | No  | Restricted<sup>(13)</sup> | No  | No  |
| Dashboard / Report | View | Full | Restricted <sup>(14)</sup> | Restricted <sup>(14)</sup> | Restricted <sup>(14)</sup> | Restricted <sup>(14)</sup> | No  |
| AI token | Using | No  | Restricted<sup>(15)</sup> | No  | Restricted<sup>(15)</sup> | No  | No  |
| AI token | Edit | Full | No  | No  | No  | No  | No  |

**Footnotes:**

- **(1)**Admin creates internal accounts for SME, Course Manager, and Teacher.
- **(2)**Guests register their own accounts to convert into Students.
- **(3)**You are only allowed to view and edit your own profile.
- **(4)** _(new)_SME can only create/edit courses within the Course Group assigned by the Admin (GB-01).
- **(5)**SMEs draft the content (Draft), submit a Publish request, but may need Admin approval.
- **(6)** _(Change label from Full to Restricted)_Students/Guests can only view general introductory information (Syllabus, price) of published courses; they cannot view lecture content unless they have purchased the course.
- **(7)** _(new)_Course Managers can only create/edit/view courses within their assigned Course Group (GB-01, AC-09a).
- **(8)** _(new)_The teacher only views the class they are in charge of (according toteacher_id), theo NFR-S02.
- **(9)**Guests are required to register an account (as a Student) in order to purchase packages/register for classes.
- **(10)** _(Change label from Full to Restricted)_The Course Manager only approves/rejects refunds for enrollments belonging to the Course Group they manage (GB-01).
- **(11)** _(new)_SME is the main actor in building the question bank, flashcards, and original essay assignments for the course (FT-03, FT-04, FT-05 — RT: UC-11, UC-65), within the scope of the assigned Course Group.
- **(12)** _(Change label from Full to Restricted)_Teachers cannot modify the original SME curriculum framework; they can only create additional exercises/quizzes/materials specifically for their class.
- **(13)** _(Change label from Full to Restricted)_The teacher only reviews and grades the assignments submitted by students in their own class.
- **(14)**Dashboards/Reports categorized by role: SME (quality of course content created), Course Manager (revenue from the course groups managed), Teacher (progress/grades of the classes managed), Student (personal dashboard).
- **(15)** _(new)_Limit according toat the quotaMonthly settings are established by the Admin for each SME/Teacher (GB-02).**Special note:**AI feature for analyzing knowledge gaps for students.knowledge gap analysisFT-12 is not included in this quota — it uses a separate 24-hour caching mechanism, not an "AI token" in the sense of this table.

## **3.3 Use Case Diagrams**

### **a. UCs for Guest**

### **b. UCs for Student**

**_Figure: Detailed Use Case Diagram for Students_**

### **c. UCs for Teacher**

**_Figure: Detailed Use Case Diagram for Teacher_**

### **d. UCs for SME**

**_Figure: Detailed Use Case Diagram for SME_**

### **e. UCs for Course Manager**

**_Figure: Detailed Use Case Diagram for Course Manager_**

### **f. UCs for Admin**

## **3.4 Use Case Index**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **UC-ID** | **Use Case Name** | **Type** | **Primary Actor** | **Description** | **Note** |
| **_Main Actor: Student_** |     |     |     |     |     |
| UC-01 | Register & Verify your account | UI  | Student | Students create an account (email or Google OAuth), log in, and can change their password if they forget it. | SCR-01, SCR-02 |
| UC-02 | Personal Profile Management | UI  | Student | View/update personal information, profile picture, and manage active login sessions. | SCR-03, SCR-04 |
| UC-03 | Course Registration & Payment | UI  | Student | Choose your participation method (H1/H2/H3), pay via VNPay/SePay, submit a refund request, and view your transaction history. | SCR-26, SCR-27, SCR-28, SCR-30 |
| UC-04 | Study the lecture and practice flashcards. | UI  | Student | Watch lectures, videos with AI summaries, and accompanying materials; flip through flashcards organized by topic. | SCR-12, SCR-13 |
| UC-05 | Take practice tests. | UI  | Student | Create your own practice tests based on modules/difficulty levels, take them, and view detailed results. | SCR-14, SCR-15, SCR-16 |
| UC-06 | Submit your essay assignment. | UI  | Student | Read the assignment prompt and grading criteria, prepare and submit your essay; view your score and feedback after the instructor confirms it. | SCR-17, SCR-18 |
| UC-07 | View your Personal Learning Progress Analysis | UI  | Student | View course progress overview, test results, flashcard progress, and essay status. | SCR-31, SCR-32, SCR-33, SCR-34 |
| **_Main Actor: SME_** |     |     |     |     |     |
| UC-08 | Upload and request AI to process raw documents. | UI  | WE  | Upload raw documents (PDF/Word/transcript), and ask the AI ​​to expand the outline into a lecture or extract a video summary. | SCR-06, SCR-06-a |
| UC-09 | AI Content Editing & Evaluation (Staging) | UI  | WE  | Review and edit the AI-generated content before incorporating it into the official lecture. | SCR-06-a |
| UC-10 | Lecture Approval & Publication | UI  | WE  | Review the complete lecture content and publish (or unlock, edit, and republish). | SCR-06 |
| UC-11 | Manage Question Bank & Flashcards (Manual) | UI  | WE  | Create/edit/delete multiple-choice questions and flashcards manually in modules. | SCR-07, SCR-09 |
| UC-12 | View the Content Quality Report | UI  | WE  | Check the statistics for questions that are too easy/too difficult, lectures that few people read, and flashcards that are often marked "not memorized". | SCR-36 |
| UC-13 | Automatically generate questions using AI. | System | WE  | The AI ​​analyzes the source text and generates multiple-choice questions in the approval queue. | SCR-08 |
| UC-14 | Automatically generate flashcards using AI. | System | WE  | The AI ​​analyzes the source text and generates term-definition pairs for inclusion in the review queue. | SCR-10 |
| UC-65 | Create Essay Assignments & Grading Criteria | UI  | WE  | Prepare the assignment (Markdown), deadline, and grading rubric (total weight = 100%). | SCR-11 |
| **_Main Actor: Course Manager_** |     |     |     |     |     |
| UC-15 | Classroom management | UI  | Course Manager | The integrated screen manages the entire class within the assigned group. | SCR-22 |
| UC-16 | Create a class | UI  | Course Manager | Select the original course, name the class, set the start/end dates, class size, and tuition fee. | SCR-21 |
| UC-17 | Assigning lecturers | UI  | Course Manager | Assign an instructor to be in charge of the class. | SCR-22 |
| UC-18 | Update class information | UI  | Course Manager | Edit the information of the created class (name, date, description...). | SCR-22 |
| UC-19 | Adjust capacity | UI  | Course Manager | Increase/decrease the maximum class size. | SCR-22 |
| UC-20 | Registration closed. | UI  | Course Manager | New registrations will stop once the class is full or as decided by the operating department. | SCR-22 |
| UC-21 | Extend the class time. | UI  | Course Manager | Extend the class end date. | SCR-22 |
| UC-22 | Student management | UI  | Course Manager | This screen displays a summary for adding/removing students in a class. | SCR-22 |
| UC-23 | View the list of students | UI  | Course Manager | View the list of students along with their payment status and learning progress. | SCR-22 |
| UC-24 | Add more students | UI  | Course Manager | Add students directly to the free class (via email or invitation). | SCR-22 |
| UC-25 | Remove student | UI  | Course Manager | Remove a student from the class (log the reason). | SCR-22 |
| UC-26 | Price management | UI  | Course Manager | This screen displays the setup/update of retail course prices. | SCR-25 |
| UC-27 | Set course prices | UI  | Course Manager | Set the retail price (H1) for each course in the assigned group. | SCR-25 |
| UC-28 | Update course prices. | UI  | Course Manager | Modify the established price. | SCR-25 |
| UC-29 | Subscription package management | UI  | Course Manager | The CRUD summary screen shows the subscription package (H3) by course group. | SCR-25 |
| UC-30 | Create a subscription package | UI  | Course Manager | Create packages with specific durations (1/3/6 months, 1 year) for all courses within the group. | SCR-25 |
| UC-31 | Update your subscription plan. | UI  | Course Manager | Edit your subscription plan information. | SCR-25 |
| UC-32 | Activate your subscription | UI  | Course Manager | Enable package visibility in the public catalog. | SCR-25 |
| UC-33 | Disable subscription | UI  | Course Manager | Turn off/stop selling subscription packages. | SCR-25 |
| UC-34 | Track revenue | UI  | Course Manager | Track revenue in real time within your management team. | SCR-37 |
| UC-35 | View sales report | UI  | Course Manager | View detailed revenue reports by class/subscription package. | SCR-37 |
| UC-36 | View the course registration report. | UI  | Course Manager | View new registration figures over time. | SCR-37 |
| UC-37 | View subscription package report | UI  | Course Manager | View subscription purchase/renewal rates. | SCR-37 |
| UC-38 | Refund processing | UI  | Course Manager | Review/reject refund requests, revoke access before issuing a refund (BR-17). | SCR-25, SCR-29 |
| UC-39 | Revoke access | System | Course Manager | The background job scans for expired enrollments (H2/H3) and automatically revokes access. | JOB-04 |
| **_Main Actor: Teacher_** |     |     |     |     |     |
| UC-40 | Finalize and approve the scores. | UI  | Teacher | View students' work alongside draft grading and feedback suggested by AI. Teachers have the right to edit and approve the final grade. | SCR-20 |
| UC-41 | Review the scores and feedback from the AI ​​draft. | UI  | Teacher | Monitor the learning performance of the entire class and receive alerts from AI about students showing signs of at-risk behavior so that intervention can be taken. | SCR-20 |
| UC-42 | Preliminary essay grading via LLM | System | AI Engine / Teacher | The system sends submissions and rubrics to LLM Gateway for preliminary grading based on each criterion. | SCR-20 |
| UC-43 | Using the evaluation criteria matrix | System | AI Engine / Teacher | The system automatically retrieves the rubric (criterion name, maximum score, weight) of the assignment. | SCR-20 |
| UC-44 | human-participatory scoring | UI  | Teacher | Split-screen interface: student submissions on the left, AI suggestions on the right. | SCR-20 |
| UC-45 | Access Class Analytics v2 | UI  | Teacher | See class progress overview: students haven't started the course yet, and this module has the highest dropout rate. | SCR-35 |
| UC-46 | Evaluation process management | UI  | Teacher | View the list of essays awaiting grading, processed in batches. | SCR-19 |
| UC-47 | Screening students at risk of academic underperformance. | System | AI Engine | AI analyzes and flags students showing signs of neglect/inactivity. | SCR-35 |
| **_Main Actor: Admin_** |     |     |     |     |     |
| UC-48 | View system configuration | UI  | System Admin | View the current configuration parameters (file limits, class size, etc.). | SCR-38 |
| UC-49 | Adjust AI limit settings. | UI  | System Admin | Set monthly AI limits for each SME/Teacher (GB-02). | SCR-38 |
| UC-50 | Storage limit configuration | UI  | System Admin | Adjust the file upload size limit. | SCR-38 |
| UC-51 | View activity log | UI  | System Admin | View audit logs: unusual logins, permission changes, payment transactions. | SCR-43 |
| UC-52 | Manage background tasks | UI  | System Admin | Monitor/operate JOB-01 (incident monitoring), JOB-02 (log cleanup), JOB-03 (session cancellation). | JOB-01, JOB-02, JOB-03 |
| UC-53 | View the list of user accounts. | UI  | System Admin | View/filter/search all accounts by role and status. | SCR-38 |
| UC-54 | Account details management | UI  | System Admin | View, edit, lock/delete (soft-delete) a specific account. | SCR-39 |
| UC-55 | Create an internal account | UI  | System Admin | Create accounts for SME/Teacher/Course Manager, send invitation emails (GB-03, BR-27). | SCR-40 |
| UC-56 | Appoint a course manager | UI  | System Admin | Assign the Course Manager to the Course Group. | SCR-41 |
| UC-57 | Appoint a specialist | UI  | System Admin | Assign SMEs to specific courses/course groups. | SCR-42 |
| UC-58 | Create a course group | UI  | System Admin | Create Course Groups to group related courses by topic. | SCR-23 |
| UC-59 | View consolidated revenue report | UI  | System Admin | View system-wide revenue reports (for all course groups). | SCR-24 |
| UC-60 | Review the refund report. | UI  | System Admin | Review/approve refund requests that escalate to Admin. | SCR-29 |
| **_Main Actor: Guest_** |     |     |     |     |     |
| UC-61 | View public directory | UI  | Guest | View the list of published courses (general information, price). | SCR-05 |
| UC-62 | Search & Filter courses | UI  | Guest | Search/filter courses within the public catalog. | SCR-05 |
| UC-63 | Use questions and practice cards. | UI  | Guest | Try up to 10 sample questions and 5 sample flashcards (BR-12), without using the AI ​​feature (BR-11). | SCR-44 |
| UC-64 | Register/Log in to your account | UI  | Guest | Create an account (email or Google OAuth) to convert to Student status. | SCR-01, SCR-02 |

# **4\. Functional Requirements**

## **4.1 Modules & Features (Son Nam)**

### **a. Module List**

|     |     |     |
| --- | --- | --- |
| **Module** | **Purpose** | **Primary Actor(s)** |
| Content Manager | Manage the entire lifecycle of the original course: Drafting syllabi, uploading materials/videos, creating question banks, and moderating content publication. | SME, Admin, Teacher |
| Learning | Serving the practical teaching and learning process: Students view lectures, submit assignments, take quizzes, and interact with the AI; instructors monitor, grade assignments, and provide feedback. | Teacher, Student |
| ClassRoom and Business | Business operations and class organization: Create commercial classes, set prices, create membership packages, manage students (Rosters), process payments and refunds. | Course Manager, Admin, Student |
| Analytics | Provides statistical dashboards: Revenue reports (by course/package), student learning progress, course quality reviews, and AI usage reports. | Admin,Course Manager, SME, Teacher |
| User Manager | Account lifecycle management: Visitors register/log in (OAuth 2.0), users update their personal profiles, and internal account allocation/permissions are granted. | Admin, Guest, Student |
| System Administration | Configure and monitor system cores: Adjust system limits (file size, AI limits), view system logs (Activity Logs), and manage background processes (Background Jobs). | Admin |

### **b. Module: Content Manager**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **FT-ID** | **Feature** | **Priority** | **Description** | **UC-ID Ref** | **SC-ID Ref** |
| FT-01 | Course Structure Management | Must | Admin creates the course and assigns a content expert to be in charge. | UC-61, UC-62 | SC-01, SC-02 |
| FT-02 | Prepare Lectures & Learning Materials | Must | Content experts and instructors create lesson content. | UC-08, UC-09, UC-10, UC-63 | SC-01, SC-02 |
| FT-03 | Build a question bank and test. | Must | Expert in building multiple-choice question banks. | UC-11, UC-13 | SC-01 |
| FT-04 | Create a set of flashcards. | Must | Experts and instructors create flashcards grouped by topic within the module. | UC-11, UC-14 | SC-01, SC-02 |
| FT-05 | Create essay assignments and grading criteria. | Must | Lecturers and experts prepare essay assignments including the prompt (Markdown), deadline, and grading rubric. | UC-65 | SC-01, SC-04 |

### **c. Module: Learning**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **FT-ID** | **Feature** | **Priority** | **Description** | **UC-ID Ref** | **BF-ID Ref** |
| FT-06 | Study Lectures & Review Flashcards | Must | Students access the lessons within the module. | UC-04 | SC-04 |
| FT-07 | Take the Test & View Your Results | Must | Students create their own practice tests by selecting the scope (which module), the number of questions, and the difficulty level. | UC-05 | SC-04 |
| FT-08 | Submitting, Grading, and Returning Results | Must | This feature covers the entire essay assignment lifecycle — from when students submit their work to when they receive their results. | UC-06, UC-40, UC-41, UC-42, UC-43, UC-44, UC-46 | SC-04, SC-05 |
| FT-12 | Track Your Personal Learning Progress | Must | Students can view an overview of their learning progress through their personal dashboard. | UC-07 | SC-04 |

### **d. Modules: ClassRoom and Business**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **FT-ID** | **Feature** | **Priority** | **Description** | **UC-ID Ref** | **BF-ID Ref** |
| FT-09 | Classroom Management | Must | Admins or Course Managers create and manage unified classes on EduNexus. | UC-15, UC-16, UC-17, UC-18, UC-19, UC-20, UC-21, UC-22, UC-23, UC-24, UC-25 | SC-02, SC-05 |
| FT-10 | Manage Tuition Categories & Packages | Must | Create course groups (group related courses by topic), and assign a Course Manager to manage them. View consolidated revenue reports for the entire system. | UC-26, UC-27, UC-28, UC-58, UC-59 | SC-02, SC-05 |
| FT-11 | Course Registration & Payment | Must | Students choose their preferred participation method and make payment via VNPay or SePay. Immediately after successful payment confirmation, the system automatically grants access. | UC-03, UC-29, UC-30, UC-31, UC-32, UC-33, UC-38, UC-39, UC-60 | SC-03, SC-05 |

### **e. Modules: Analytics**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **FT-ID** | **Feature** | **Priority** | **Description** | **UC-ID Ref** | **BF-ID Ref** |
| FT-13 | Class Results & Content Analysis | Must | Providing analytical data for instructors, content specialists, and Course Managers. | UC-12, UC-34, UC-35, UC-36, UC-37, UC-45, UC-47 | SC-05 |

### **f. Modules: User Manager**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **FT-ID** | **Feature** | **Priority** | **Description** | **UC-ID Ref** | **BF-ID Ref** |
| FT-14 | User Authentication & Profile | Must | This feature caters to the entire account lifecycle from a user's perspective — from account creation and daily logins to managing personal information. It supports both registration and login methods simultaneously. | UC-01, UC-02, UC-64 | SC-03, SC-04, SC-05 |

### **g. Modules: System Admin**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **FT-ID** | **Feature** | **Priority** | **Description** | **UC-ID Ref** | **BF-ID Ref** |
| FT-15 | System Administration | Must | The administrator manages all system operations through a centralized administration dashboard. | UC-48, UC-49, UC-50, UC-51, UC-52, UC-53, UC-54, UC-55, UC-56, UC-57 | SC-05 |

### **x. Won't-Have (This Version)**

- The platform does not host live video classroom sessions.
- It does not integrate with Google Classroom, Moodle, Canvas, or any other external LMS.
- Visitor session data is not saved to the system.
- International payments (Stripe, PayPal) and B2B business invoices are outside the scope of this version.
- EduNexus does not automatically handle refund disputes.
- The actual class size is limited by infrastructure capacity.

## **4.2 Screen Inventory (Former)**

### **a. Screen Flow**

### **b. Screen List**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **SCR-ID** | **Screen Name** | **Module** | **Description** | **FT-ID** | **UC-ID** |
| **SCR-01** | Sign In | User Manager | Allows users (Students, Instructors, SMEs, Course Managers, Admins) to authenticate their accounts to access the system. | FT-14 | UC-01, UC-64 |
| **SCR-02** | Register | User Manager | Allow guests to create new accounts on the system. | FT-14 | UC-01, UC-64 |
| **SCR-03** | Change password | User Manager | This screen allows users to update or change their password to secure their account. | FT-14 | UC-02 |
| **SCR-04** | Personal information | User Manager | Allows users to view and update their personal profile information. | FT-14 | UC-02 |
| **SCR-05** | Course structure management | Content Manager | The interface for managing the course list and setting up the course structure (courses, modules). | FT-01 | UC-61, UC-62 |
| **SCR-06** | Prepare lectures and materials (manually) | Content Manager | The editor interface allows teachers and SMEs to design their own materials and lessons. | FT-02 | UC-08, UC-10 |
| **SCR-06-a** | Extracting Text & Generating Lectures using AI | Content Manager | The SME support screen extracts text from raw documents and requests AI to create staging for lesson content. | FT-02 | UC-08, UC-09 |
| **SCR-07** | Building a Question Bank & Tests | Content Manager | A screen for managing and manually creating multiple-choice questions/tests for the data bank. | FT-03 | UC-11 |
| **SCR-08** | Preview and review AI-generated questions. | Content Manager | The staging interface allows SMEs to test, refine, and approve the AI-generated question bank. | FT-03 | UC-13 |
| **SCR-09** | Create a memory card. | Content Manager | The Flashcard Editor interface helps SMEs and teachers edit the content of flashcard sets by topic. | FT-04 | UC-11 |
| **SCR-10** | Preview and browse AI-generated flashcards. | Content Manager | The staging screen allows SMEs and teachers to preview, edit, and publish flashcard sets using the AI ​​system. | FT-04 | UC-14 |
| **SCR-11** | Create Essay Assignments & Grading Criteria | Content Manager | This screen allows you to create essay assignments (with Markdown support), set deadlines, and configure the grading rubric. | FT-05 | UC-65 |
| **SCR-12** | Study the lecture | Learning | The integrated video/lecture viewing interface (Lesson View) displays content for learners. | FT-06 | UC-04 |
| **SCR-13** | Learn using flashcards. | Learning | The flashcard library and flip-card practice interface help students review the material. | FT-06 | UC-04 |
| **SCR-14** | Create a test | Learning | Allows students to customize their practice tests (select module scope, difficulty level, and number of questions). | FT-07 | UC-05 |
| **SCR-15** | Take the test | Learning | This is the interface for students to take a timed online quiz. | FT-07 | UC-05 |
| **SCR-16** | Test results | Learning | The screen displays the score, statistics on correct/incorrect answers, and test history. | FT-07 | UC-05 |
| **SCR-17** | Write an essay (Submit it to an AI-powered grading platform). | Learning | The interface allows students to submit files/essays to the system to activate the automated AI-based draft grading process. | FT-08 | UC-06 |
| **SCR-18** | Essay results (Feedback from AI and Teacher) | Learning | The screen displays the official scores along with detailed feedback, combining AI and instructor-approved comments. | FT-08 | UC-06 |
| **SCR-19** | View the list of essays | Learning | This is a compiled list of all essay submissions from the class, intended for the instructor to manage the grading schedule. | FT-08 | UC-46 |
| **SCR-20** | Detailed essay grading (Split-Screen AI) | Learning | The workspace is split-screen: the left side displays the assignment, while the right side shows AI-generated feedback for the instructor to review/override. | FT-08 | UC-40, UC-41, UC-42, UC-43, UC-44 |
| **SCR-21** | Create a class | ClassRoom & Business | This interface is for creating new class information for both Admin and Course Manager. | FT-09 | UC-16 |
| **SCR-22** | Classroom management | ClassRoom & Business | An integrated dashboard allows you to update class information, assign instructors, adjust class capacity, or close/renew classes. | FT-09 | UC-15, UC-17, UC-18, UC-19, UC-20, UC-21, UC-22, UC-23, UC-24, UC-25 |
| **SCR-23** | Create a course group | ClassRoom & Business | This screen allows administrators to group courses by learning topic. | FT-10 | UC-58 |
| **SCR-24** | View consolidated revenue report | ClassRoom & Business | The dashboard displays system-wide statistics and financial reports for the administrator. | FT-10 | UC-59 |
| **SCR-25** | Manage assigned course groups | ClassRoom & Business | This interface allows Course Managers to update configurations, information, and manage the operation of their assigned course groups. | FT-10 | UC-26, UC-27, UC-28, UC-29, UC-30, UC-31, UC-32, UC-33, UC-38 |
| **SCR-26** | Register for the course | ClassRoom & Business | The screen allows students to select the learning format (H1, H2, H3) and submit their registration request. | FT-11 | UC-03 |
| **SCR-27** | Course payment | ClassRoom & Business | The integrated payment page displays a QR code or payment gateway via VNPay/SePay. | FT-11 | UC-03 |
| **SCR-28** | Submit a refund request. | ClassRoom & Business | The interface allows students to submit requests/reports for course fee refunds. | FT-11 | UC-03 |
| **SCR-29** | Review the refund report. | ClassRoom & Business | This is where the Admin and Course Manager receive and evaluate the approval/rejection status of refund requests. | FT-11 | UC-60 |
| **SCR-30** | Payment transaction history | ClassRoom & Business | This screen displays the payment history and payment receipts for both students and administrators to review. | FT-11 | UC-03 |
| **SCR-31** | Learning progress - Course | Learning | The dashboard displays an overview of the percentage (%) of coursework completed by students. | FT-12 | UC-07 |
| **SCR-32** | Learning progress - Flashcards | Learning | Keep track of the number of flashcards you've memorized, those you need to review, and your personal practice frequency. | FT-12 | UC-07 |
| **SCR-33** | Learning progress - Test results | Learning | The chart tracks the change in scores across practice tests. | FT-12 | UC-07 |
| **SCR-34** | Learning progress - Essay assignments | Learning | This is where you can track the grading status, submission history, and scores of your essay assignments. | FT-12 | UC-07 |
| **SCR-35** | Analysis - Instructor - Class Overview | Analytics | The dashboard screen analyzes class data and student progress, allowing instructors to monitor their progress. | FT-13 | UC-45, UC-47 |
| **SCR-36** | Analysis - Content Expert - Content Quality | Analytics | Detailed reports on learning material quality and correct/incorrect answer rates help SMEs optimize their original content. | FT-13 | UC-12 |
| **SCR-37** | Analysis - Course Manager - Business Performance | Analytics | Detailed analytics on course registration effectiveness and package sales for Course Managers to manage. | FT-13 | UC-34, UC-35, UC-36, UC-37 |
| **SCR-38** | Account list | System Admin | This screen displays a summary of all accounts for every role in the administration system. | FT-15 | UC-48, UC-49, UC-50, UC-53 |
| **SCR-39** | Account information | System Admin | View detailed information, edit permissions, or delete system accounts. | FT-15 | UC-54 |
| **SCR-40** | Add account | System Admin | Allows Admin to manually create new accounts (for SME, Course Manager, etc.). | FT-15 | UC-55 |
| **SCR-41** | Assignment - Course Manager | System Admin | The Course Manager interface coordinates and assigns personnel, with the Course Manager responsible for managing the course group. | FT-15 | UC-56 |
| **SCR-42** | Assignment - SME | System Admin | The interface coordinates and separates content specialists (SMEs) responsible for building course materials. | FT-15 | UC-57 |
| **SCR-43** | Login history for each account | System Admin | Audit logs record detailed information about the time and history of system access by accounts. | FT-15 | UC-51 |
| **SCR-44** | Guest - try answering the questions and using flashcards. | Learning (Data is blank) | This demo page limits features such as quizzes and flashcard viewing to users who do not yet have an account. | _(Do not have)_ | UC-63 |

## **4.3 External API Inventory (Son Nam)**

|     |     |     |     |
| --- | --- | --- | --- |
| **API-ID** | **API Name** | **Calling Path** | **Description** |
| API-01 | Youtube API | EduNexus Backend => YouTube API | Receive video URLs from the system to check status, retrieve metadata, and extract subtitles for AI summarization functionality. |
| API-02 | Gemini AI | EduNexus Backend => AI Services | Receive source text, prompts, and rubrics to automatically generate educational content (questions, flashcards) and support preliminary essay grading. |
| API-03 | Email Service | EduNexus Backend => Email Service API | Send emails inviting students to create internal accounts, send score confirmation notifications, and send progress reminders to students in the class. |
| API-04 | Google Identity | EduNexus System => Google Identity | Processes one-touch login authentication requests according to the OAuth 2.0 standard, returning the authentication token and basic user profile information. |

## **4.4 Background Job Inventory (Son Nam)**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **JOB-ID** | **Job Name** | **Group** | **Description** | **FT-ID** | **UC-ID** |
| JOB-01 | Incident Monitoring and Alerting | System Admin | The background task periodically (every 1-3 minutes) calls the Ping API to check the operational status of external services. It automatically pushes alert notifications to the administrator if it detects timeouts or system crashes. | FT-15 | UC-52 |
| JOB-02 | Clean up system logs. | System Admin | This task runs periodically at 00:00 AM each day to scan the system logs. It automatically deletes logs that have exceeded the configured time limit to free up database memory space. | FT-15 | UC-52 |
| JOB-03 | Cancel login session | System Admin | The asynchronous event, triggered immediately upon account deactivation, scans and deletes all of that user's Access Tokens in the Redis Cache, forcing the user to log out and disconnect from all devices. | FT-15 | UC-52 |
| JOB-04 | Scan for expired packages | ClassRoom & Business | The background scan process runs at a high frequency (every 5-10 minutes) reviewing the subscription package (H3) and class (H2) data tables. It automatically changes the status to EXPIRED and revokes student access as soon as the current time exceeds the deadline. | FT-11 | UC-39 |

# **5\. Global Business Rules**(Son Nam)

## **5.1 Global Business Rule Table**

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **GBR-ID** | **Rule Statement** | **Applies To** | **Rationale** | **Enforced By** | **UC-IDs** |
| GB-01 | Access restrictions are based on assignments: Course Managers and SMEs are only permitted to view, edit, or interact with Courses/Classes belonging to the Course Group they have been assigned by the Admin. | View and manage Courses, Classes, and Subscription Packages. | Ensure data security between departments; prevent accidental modification of content belonging to other departments. | The system automatically checks the assignment ID on every data query (Authorization check). |     |
| GB-02 | AI Usage Control: All Generative AI usage (creating quizzes, flashcards, AI scoring) must not exceed the monthly quota set by the Admin for each account. | Features that call the GenAI (Gemini/OpenAI) API | Prevent the misuse of AI from overloading the system and control the cost of external API calls. | The system counts and automatically blocks calls to the AI ​​API. |     |
| GB-03 | Internal registration prohibited: Internal roles (SME, Teacher, Course Manager) are not allowed to register accounts through the external interface. Only Admins have the authority to create and send invitation emails. | Registration / Account Management screen | Ensure system security and prevent outsiders from creating accounts with unauthorized access to the administration system. | The system automatically blocks registrations via form with these roles. |     |
| GB-04 | Immediate Revocation: As soon as the Class (H2) or Membership Package (H3) term ends, the Learner immediately loses access to lesson content, videos, and quizzes. | Access lectures, videos, and attached documents. | Ensure the commercial viability and copyright of the course. | The background process (JOB-04) automatically scans and blocks each data request. |     |
| GB-05 | Deactivating login sessions: When an account is deactivated or deleted by an administrator, all current login sessions (Access Tokens) across all devices must be immediately terminated. | User authentication | Prevent former employees or trainees who have violated the rules from continuing to use the system. | The background process (JOB-03) automatically deletes the Token in Redis. |     |
| GB-06 | Course Integrity: A Course cannot be deleted if it has active Commercial Classes (Class H2) or Subscription Packages (H3). | Delete Course / Course Group | Prevent data loss errors and ensure the rights of students who are paying tuition fees are protected. | The system automatically checks for foreign keys and blocks deletion requests. |     |

# **6\. Non-Functional Requirements & Constraints (Sơn Nam)**

## **6.1 Performance Requirements**

|     |     |     |
| --- | --- | --- |
| **Requirement** | **Target** | **Condition** |
| **Web Response Time**(UI response time) | Under 2 seconds (< 2s) | This applies to normal web browsing operations (viewing categories, loading lecture pages, taking quizzes). |
| **AI Turnaround Time**(AI processing time) | Maximum 30 seconds (< 30s) | This applies to background processes (Background Jobs) that call third-party APIs: AI for grading essays, extracting video subtitles. |
| **System Concurrency**(Load capacity) | Supports 500 simultaneous users / 1 class | Applicable during peak periods (new course launches, final exams) without compromising response times. |
| **High Availability**(High availability) | Uptime reached 99.5% | This applies to the entire system. If the AI ​​API (Gemini/OpenAI) crashes, core functions (learning, payment) must continue to operate normally (fall-back). |
| **Resource Optimization**(Resource optimization) | Cache response < 50ms | When managing guest login sessions and trial data, using Redis Cache is mandatory to reduce the load on the database. |

## **6.2 Security Requirements**

|     |     |
| --- | --- |
| **Requirement** | **Description** |
| **Authentication**(User authentication) | \- **Student/Guest:**Logging in via Google Identity (OAuth 2.0) is mandatory; the system absolutely does not store internal passwords for this group.<br><br>\- **Internal Roles (SME, Teacher, Manager):**Accounts are directly assigned by the Admin, requiring a password change upon the first login. Any locked account will have its Token immediately removed from Redis (forced out of all devices). |
| **Authorization**(Access permissions) | Apply the model**RBAC (Role-Based Access Control)**Strictly enforced. The system must have barriers at the API layer to ensure separation: SMEs are only allowed to create original content, Course Managers are only allowed to open classes/set prices, and Teachers are only allowed to teach/grade without arbitrarily modifying course content. |
| **Data Integrity**(Data integrity) | Sensitive transactions such as tuition payments, enrollment, and finalize grades must be enclosed in a package.**Atomic Transaction**Any issues that arise midway through the process must be rolled back completely to avoid data loss or discrepancies. |
| **Payment Security**(Payment security) | The system is not permitted to store users' credit card information or account numbers. All transactions must be conducted via standard SSL/TLS encrypted transmission to the partner payment gateway (VNPay/SePay). |
| **Audit Logging**(System traceability) | Any actions that change Admin configuration data, Course Manager course settings, permission management, or Teacher grade adjustments based on AI suggestions must be automatically recorded in the table.**Activity Logs**To facilitate traceability. |

## **6.3 Out of Scope**

- The platform does not host live video classroom sessions.
- It does not integrate with Google Classroom, Moodle, Canvas, or any other external LMS.
- Visitor session data is not saved to the system.
- International payments (Stripe, PayPal) and B2B business invoices are outside the scope of this version.
- EduNexus does not automatically handle refund disputes.
- The actual class size is limited by infrastructure capacity.

## **6.4 Technical Assumptions**

1.  **Cloud Infrastructure and Architecture:**The system operates on a cloud computing platform (e.g., AWS, GCP, or Azure). It requires the separation of components: the main web application server (App Server), the database server, the caching system (Redis) for managing login sessions, and dedicated background workers to handle heavy tasks (such as calling AI or scanning course deadlines).

1.  **Third-Party Services Availability:**The system relies heavily on external APIs (YouTube Data API, Gemini/OpenAI Generative AI, Google Identity Services, VNPay payment gateway, and Email Sending Service). It is assumed that these providers will consistently maintain high availability, low latency, and avoid sudden changes in pricing or quota policies.

1.  **External File Storage:**Due to the nature of online learning systems, which involve a massive volume of materials (videos, PDF lecture files), all user-uploaded files will be stored on a dedicated cloud service (e.g., Amazon S3) instead of directly on the local application server. This ensures that the server does not experience hard drive overload and performance degradation.

1.  **Client Network Connectivity:**Assume the user's device (Student/SME) has a stable broadband internet connection and is not blocked by the organization/internet provider's firewall from Google, YouTube, or payment gateway domains.