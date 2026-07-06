**PROJECT ASSIGNMENT/LAB**

**Design Modeling Document**

– Hanoi, Sep 2024 –

[**I. Record of Changes 3**](#_lij21t5yzdzv)

[**II. User Interface Design (Kien) 4**](#_4b468rw5tjd6)

[1\. User Authentication 4](#_cg00whh1z9az)

[1.1 User Login 4](#_u6dwijudjqsx)

[1.2 User Register 4](#_4yiwtv6hsl8p)

[2\. System Student 5](#_pnywrch59hho)

[2.1 Student Screen 5](#_7ji8qe70mlw)

[2.1.1 Personal Progress 5](#_ahv94ycpq543)

[2.1.2 Student Library 6](#_gz6jzcvegm1s)

[2.1.3 Lesson View 7](#_8k1ugp6mp4gx)

[2.1.4 Flashcard Library 8](#_j9lazggvovt)

[2.1.5 Flashcard Practice 10](#_h2n03psg2m8w)

[2.1.6 Quiz History 11](#_1vlppxbnd7m3)

[2.1.7 Quiz Builder 12](#_w7ino1o6zs44)

[2.1.8 Quiz Taking 13](#_mroeluhc8myi)

[2.1.9 Quiz Results 15](#_w0gunyezfum5)

[2.1.10 Quiz Review 16](#_4xjendn08r6f)

[2.1.11 Essay Submit 17](#_erpjxaa6ccl)

[2.1.12 Essay Results 18](#_ftd2zd3lagi3)

[3\. Drafting Module and AI Staging 19](#_1gdr08k67x6x)

[3.1 Drafting Screen 20](#_8ebfkrfuguim)

[3.1.1 Lesson Editor 20](#_c2hk93u89eh4)

[3.1.2 Assignment List 21](#_80bw5n64vqjo)

[3.1.3 Assignment Details 23](#_ix6j24sbixjd)

[3.1.4 Question Detail 24](#_vuoswaweoaod)

[3.1.5 Flashcard Editor 26](#_24frlp0da2z)

[3.1.6 AI Flashcard Staging 27](#_czi75uukmko1)

[**III. High-Level Design (Hoang Nam) 28**](#_vvvfhsftza0t)

[1\. Software Architecture 28](#_5f91or3qhb4r)

[1.1 Sub-Systems/Components 29](#_v5s3gq8af7qi)

[1.1.1 User Interface 29](#_kav0645qud25)

[1.1.2 Presentation Logic Layer 29](#_316n4bpc64q3)

[1.1.3 … 29](#_arofnbrqbpz)

[1.2 External Interfaces 29](#_cp2vbgp285to)

[1.2.1 System NameX 29](#_f3b6wl164dz2)

[1.2.2 … 29](#_vh7dnzsymyib)

[2\. Package Diagram 29](#_gu518l91i38t)

[**IV. Database Design (Sy Huy) 30**](#_8kff3yrg8ns8)

[1\. Database Schema 30](#_rt1jpn2mgkp6)

[2\. Table Definitions 31](#_tt4nff8md1np)

[2.1 Table: users 31](#_djtn3ldboxyc)

[2.2 Table: jobs 32](#_gooccmntj743)

[2.3 Tables: applications, application_notes, interviews 32](#_g5z6pehkxukj)

[3\. Enum / Lookup Values 33](#_41tmvmqlobmi)

[4\. Indexing Strategy 33](#_mgg2m6u049nw)

[5\. Seed Data 34](#_arrojl3hyug3)

[5.1 Minimum accounts required: 34](#_ox1eqsrvfawi)

[5.2 Minimum domain data required: 34](#_l1or71uv9jgr)

[**V. Detailed Design (Tung) 35**](#_xrr06fiwmip4)

[1\. Class Diagram 36](#_wzhttt2clih9)

[2\. Sequence Diagram 36](#_p738ee4ab8pu)

[2.1 FT-02a: AI Course Outline Expansion by SME 37](#_b4gh8f2zw4gg)

[2.2 FT-02b: AI Video Summarization via YouTube Integration 38](#_lzb7tbb2b7iy)

[2.3 FT-03: AI-Powered Revision Quiz Generation and Approval 38](#_iapu7ilvbm6g)

[2.4 FT-04: AI Flashcard Extraction and Deck Management 39](#_7fu1mo77vtdo)

[2.5 FT-05: AI Preliminary Essay Evaluation and Instructor Verification 39](#_l0gclv4isn3s)

[2.6 FT-06: AI Student Performance Analysis and Targeted Remediation Roadmap 39](#_hmx6ffuzwyai)

[3\. Activity Diagram 41](#_j63rfwi1cnd)

[3.1 FT-02a: AI Course Outline Expansion to Lectures 41](#_a4upuo844gfu)

[3.2 FT-02b: AI Video Summarization (YouTube Integration) 43](#_ri2vy2gfs0tc)

[3.3 FT-03: AI Automated Revision Quiz Generation 44](#_ig7he6m4j87)

[3.4 FT-04: Educational Flashcard Deck Management 45](#_cnl6wfw99ybh)

[3.5 FT-05: Automated AI-Driven Assignment Grading and Feedback 47](#_9eic85m3e2xj)

[3.6 FT-06: AI Student Performance Analysis and Targeted Remediation Roadmap 48](#_2l4vf5cjpxla)

# **I. Record of Changes**

|     |     |     |     |
| --- | --- | --- | --- |
| **Date** | **A/M/D\*** | **In charge** | **Description** |
| 24/06/2026 | A   | Tung | +) Detailed Design |
| 24/06/2026 | A   | Kien | +) User Interface Design |
| 24/06/2026 | A   | Huy | +) Database Design |
| 24/06/2026 | A   | Kiên, Huy | +) High - Level Design |
|     |     |     |     |
|     |     |     |     |

\*A - Added M - Modified D - Deleted

# **II. User Interface Design (Kien)**

## **1\. User Authentication**

### **1.1 User Login**

This screen allows system member to:

· Login System: provide email and password to be authenticated to access the system.

### **1.2 User Register**

## **2\. System Student**

### **2.1 Student Screen**

#### **2.1.1 Personal Progress**

This screen allows the Instructor to:

- **View Submission & AI Insights:** view student’s essay content on the left pane and AI feedback with grade recommendations on the right pane.
- **Review Rubric Criteria:** view pre-populated AI suggestions for assignment rubrics (Structure, Style, Argumentation, Tone).
- **Modify AI Evaluations:** overwrite recommended numerical scores or edit qualitative feedback text.
- **Publish Grades:** click the Publish button to release official results and sync with the gradebook.

On the screen, s/he can also:

- **Save Draft:** cache progress without releasing grades to students immediately.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Assignment Metadata Banner | Display-only. Shows Assignment Name, Student Name, and Submission Status. |
| (2) Essay Content Panel (Left) | Scrollable text area. Displays the student's raw essay text (read-only). |
| (3) AI Insight Card (Right) | Container. Displays computed AI diagnostics. Kept hidden from student until published. |
| (4) Rubric Score Input | Editable field. Initial values: AI-recommended scores. Constraints: Positive decimal within criteria range. |
| (5) Qualitative Feedback Blocks | Editable text area. Initial values: AI-generated text. Allows manual editing. |
| (6) Publish Button | Action button. Validates inputs, updates assignment to "Graded", and syncs to gradebook. |
| (7) Save Draft Button | Action button. Caches changes safely without publishing to the student. |

#### **2.1.2 Student Library**

This screen allows the Administrator to:

- **View Setting List:** view a list of system master data including Setting Name, Type, Value, and Status.
- **Filter Setting List:** filter master data using dropdowns for Data Type and Status.
- **Search Settings:** enter keywords in the search bar to search master data by names or values.
- **Sort Setting List:** sort the list (ascending/descending) by clicking on the column headers.

On the screen, s/he can also:

- **Activate/Deactivate Setting:** toggle the status switch to instantly change a setting's state between Active and Inactive.
- **Navigate to Details:** click the "Add New" button or "Edit" link to open the Setting Details screen.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Type Filter Dropdown | Dropdown list. Initial value: "All Type". Filters the table content by selected configuration group. |
| (2) Status Filter Dropdown | Dropdown list. Initial values: Active, Inactive. Filters the table content by selected state. |
| (3) Search Bar | Text input. Placeholder: "Search by name, value...". Dynamically filters rows based on partial matching keywords. |
| (4) Status Toggle Switch | Toggle control. Changes status between Active (Green) and Inactive (Gray) depending on the current state. |
| (5) Action Links (Edit) | Hyperlink. Redirects the Administrator to the specific Setting Details screen for editing. |
| (6) Add New Button | Action button. Redirects the Administrator to a blank Setting Details screen to create a new master data entry. |

#### **2.1.3 Lesson View**

This screen allows the Administrator to:

- **View Setting Details:** view specific properties of a system master data entry, including Name, Type, Value, Order, and Description.
- **Update Setting Information:** modify input data fields to change the system configuration parameters.
- **Validate Inputs:** ensure data consistency through system checks on required fields and numeric formats.

On the screen, s/he can also:

- **Save Changes:** click the "Save" button to submit data, update the database, and return to the Setting List screen.
- **Cancel Action:** click the "Cancel" button to discard all modifications and return to the Setting List screen safely.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Setting Name | Text input. Required field. Allows the Administrator to enter or update the unique identifier name for the configuration. |
| (2) Setting Type | Dropdown list. Required field. Displays available classification groups for the configuration data. |
| (3) Setting Value | Text input. Required field. Specifies the operational value corresponding to this system setting. |
| (4) Display Order | Number input. Required field. Constraints: Must be a non-negative integer. Controls the sorting sequence layout in lists. |
| (5) Description | Text area. Optional field. Allows entering comprehensive notes or explanations regarding the setting's purpose. |
| (6) Save Button | Action button. Triggers data validation. Saves the records to the system database and redirects to the Setting List screen. |
| (7) Cancel Button | Action button. Discards all current text entries and inputs, then safely redirects back to the Setting List screen. |

#### **2.1.4 Flashcard Library**

This screen allows the User to:

- **View Flashcard Decks:** view a grid list of available flashcard collections, including deck names, categories, and total card counts.
- **Filter Flashcards:** filter the visible collections by specific subject areas or categories using the dropdown.
- **Search Decks:** enter keywords in the search input to instantly locate specific flashcard sets by their title.

On the screen, s/he can also:

- **Study Deck:** click on a specific card container to open the interactive flashcard learning interface.
- **Create New Deck:** click the "Create Flashcard" button to navigate to the setup interface for creating a new custom study set.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Category Filter Dropdown | Dropdown list. Initial value: "All Category". Filters the library grid based on selected subject topics. |
| (2) Search Bar | Text input. Placeholder: "Search flashcard name...". Dynamically updates the grid matching the deck title. |
| (3) Create Flashcard Button | Action button. Redirects the user to the custom flashcard creation wizard. |
| (4) Flashcard Deck Container | Interactive Card component. Displays the Deck Title, Category tag, and total item count. Clicking it triggers the study sequence. |

#### **2.1.5 Flashcard Practice**

This screen allows the User to:

- **Track Practice Progress:** view current session statistics including total remaining cards, memorized cards, and review intervals.
- **Review Flashcard Content:** view the question/term side or flip to reveal the answer/definition on the interactive central canvas.
- **Evaluate Memorization:** click feedback options to update memory states based on how easily the term was recalled.

On the screen, s/he can also:

- **Navigate Deck:** click the arrow buttons to jump back to the previous card or skip ahead to the next one.
- **Return to Library:** click the back arrow link to exit the practice session and return to the Flashcard Library.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Progress Summary Bar | Display-only indicators. Shows metadata tracking statistics: "Remaining" count, "Memorized" card metrics, and scheduling flags. |
| (2) Interactive Flashcard Area | Clipped container canvas. Displays the term block text. Clicking directly flips the asset animation between Front (Question) and Back (Answer). |
| (3) Navigation Controls (Arrows) | Action icons. Left and Right arrow controls mapped to sequence triggers. Allows jumping manually across the deck collection arrays. |
| (4) Memorization Feedback Block | Action button group. Options like "Forget", "Remembered", "Mastered". Triggers memory state calculations and updates study schedules. |

#### **2.1.6 Quiz History**

This screen allows the User to:

- **View Quiz History List:** view a detailed table of past quiz attempts, including Quiz Name, Course, Score, Correct Answers Ratio, Execution Date, and Status.
- **Filter Quiz Records:** filter the attempts history list by specific Course or completion Status using the dropdowns.
- **Search Quizzes:** enter keywords in the search bar to locate specific quiz records by their name.
- **Sort History List:** sort the records (ascending/descending) by clicking on the column headers.

On the screen, s/he can also:

- **Review Attempt Details:** click the "Review" link to navigate to the detailed question-by-question review screen for that specific attempt.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Course Filter Dropdown | Dropdown list. Initial value: "All Course". Filters the history logs based on the selected course selection. |
| (2) Status Filter Dropdown | Dropdown list. Initial value: "All Status". Filters rows by states such as Completed or Incomplete. |
| (3) Search Bar | Text input. Placeholder: "Search by quiz name...". Dynamically updates the table grid matching the quiz title keyword. |
| (4) Quiz History Table | Data grid. Displays tracking columns: Name, Course, Score, Accuracy Ratio, Date, and State. Headers support click-to-sort triggers. |
| (5) Action Links (Review) | Hyperlink. Redirects the user to the Quiz Review interface to check wrong answers and explanations. |

#### **2.1.7 Quiz Builder**

This screen allows the User (SME/Instructor) to:

- **Configure AI Quiz Criteria:** input setup criteria including Quiz Name, Course selection, Topic, Difficulty level, and Question Quantity.
- **Generate Automated Content:** leverage the "Generate by AI" feature to instantly draft a custom set of contextually relevant questionnaire options.

On the screen, s/he can also:

- **Cancel Session:** click the "Cancel" button to clear current target inputs and return safely to the Question Bank / Dashboard.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Quiz Name | Text input. Required field. Allows entering a custom administrative title for the quiz entry. |
| (2) Course Select Dropdown | Dropdown list. Required field. Maps the target quiz to a specific existing master course entity. |
| (3) Topic Field | Text input. Required field. Specifies the contextual scope or lecture material focus for the AI generation prompt. |
| (4) Difficulty Level Segment | Button group. Toggle options: Easy, Medium, Hard. Sets the baseline diagnostic complexity metric for the AI service generation rules. |
| (5) Number of Questions Input | Number spinner. Constraints: Positive integer limit. Defines the precise volume size of questions to compile into the dataset. |
| (6) Generate by AI Button | Action button. Triggers data schema validation and initiates backend connection to the AI generation process. |
| (7) Cancel Button | Action button. Discards input field buffers and routes the user back to the primary workspace view. |

#### **2.1.8 Quiz Taking**

This screen allows the User (Student) to:

- **View Quiz Questions:** view the current question content along with its multiple-choice answer options.
- **Select Answers:** interact with radio buttons to choose the preferred answer for each question.
- **Track Remaining Time:** monitor the countdown timer displaying the remaining duration for the active test session.
- **Navigate Questionnaire Array:** monitor the overall progress grid and track which questions are filled, currently active, or left blank.

On the screen, s/he can also:

- **Submit Assessment:** click the "Submit" button to instantly commit responses to the system for automatic evaluation and recording.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Countdown Timer Display | Display-only countdown. Shows the remaining hours, minutes, and seconds. Automatically triggers quiz submission when time hits zero. |
| (2) Question & Answer Block | Interactive container. Displays the question text context above and a list of alternative choice options attached to active radio controls. |
| (3) Navigation Panel Grid | Interactive progress map. Displays a block grid index of all question numbers. Highlights completed rows and allows direct jumping to any question card on click. |
| (4) Next / Previous Controls | Action buttons. Allow sequential navigation through the linear questionnaire array. |
| (5) Submit Button | Action button. Validates missing answer states, displays a final confirmation dialogue, and sends transaction inputs to the gradebook engine. |

#### **2.1.9 Quiz Results**

This screen allows the User (Student) to:

- **View Performance Summary:** view the structural score, correct answer percentage, diagnostic status, and total time spent on the quiz attempt.
- **Review Detailed Explanations:** scroll through the completed question blocks to verify selected answers against the official correct choices along with descriptive AI explanations.

On the screen, s/he can also:

- **Navigate Back:** click the "Back to Dashboard" or "Review History" actions to exit the detailed diagnostic report view.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Score Summary Header | Display-only indicators. Displays critical assessment metrics: Final Score (e.g., 8.0/10), Completion Status (Passed/Failed), and time elapsed. |
| (2) Question Card Array | Read-only grid. Displays the individual question texts marked with color-coded evaluation icons (Green for Correct, Red for Incorrect). |
| (3) Selected vs. Correct Answer | Display-only status tags. Highlights the precise multiple-choice alternative selected by the user relative to the verified solution key. |
| (4) AI Explanation Block | Display-only text area. Provides a contextually generated dynamic rationale breaking down why the official answer is correct. |
| (5) Back Navigation Button | Action button. Discards active window context and securely returns the user to the previous history index or course panel. |

#### **2.1.10 Quiz Review**

This screen allows the User (Student) to:

- **Review Questions State:** view individual quiz questions with color-coded evaluation indicator tags highlighting correctness.
- **Inspect Choice Analytics:** check the selected choice against the validated correct answer key for each question block.
- **Read AI Explanations:** view comprehensive, contextually generated breakdown rationales explaining the correct answer logic.
- **Navigate Question Index:** monitor and jump across the comprehensive question map grid pane located on the right side.

On the screen, s/he can also:

- **Exit Review:** click the "Back to Dashboard" button to close the performance details view and return safely.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Question Content Block | Read-only container. Displays the full question text context along with a color-coded evaluation state badge (Correct/Incorrect). |
| (2) Selected vs. Correct Options | Display-only fields. Highlights the precise choice selected by the student in comparison to the system's verified correct answer. |
| (3) AI Explanation Box | Display-only text area. Displays the AI-generated educational rationale breaking down the solution analysis. |
| (4) Navigation Sidebar Grid | Interactive status map. Displays a grid block index of all question numbers, color-coded by performance (e.g., Green for Correct, Red for Incorrect). Supports direct jumping to questions on click. |
| (5) Back Button | Action button. Safely terminates the active review session context and redirects back to the main student interface view. |

#### **2.1.11 Essay Submit**

This screen allows the User (Student) to:

- **Review Assignment Information:** view the topic requirements, description guidelines, maximum score, and the submission deadline.
- **Draft Essay Content:** enter, compose, or edit textual assignment arguments directly into the text editor space.
- **Upload Document Assets:** browse and attach local document files to support the primary assignment entry.

On the screen, s/he can also:

- **Submit Assignment:** click the "Submit" button to instantly lock responses and upload the finalized data file for grading.
- **Cancel Session:** click the "Cancel" button to clear current local string changes and return safely to the Course Panel.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Assignment Metadata Box | Display-only container. Displays Title, Description instructions, Max Score (e.g., 10), and the exact Due Date timestamp. |
| (2) Text Editor Workspace | Rich text area. Required field (if no file is uploaded). Allows entering or formatting the raw essay text context directly. |
| (3) File Upload Zone | Drag-and-drop file picker. Optional/Alternative control. Supports importing external document formats up to the specified maximum size limit. |
| (4) Submit Button | Action button. Triggers missing parameter validation checks, changes submission state to "Submitted", and routes data assets to the grading pipeline. |
| (5) Cancel Button | Action button. Discards active editor field buffers and redirects the user back to the primary course module view. |

#### **2.1.12 Essay Results**

This screen allows the User (Student) to:

- **View Essay Evaluation Details:** view the final total score alongside the specific rubric breakdown grades configured by the instructor.
- **Review Qualitative Feedback:** read detailed structured critique text addressing individual performance dimensions like Structure, Style, Argumentation, and Tone.

On the screen, s/he can also:

- **Navigate Back:** click the back arrow navigation action to return safely to the Assignment List or Course Panel.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Final Grade Banner | Display-only. Displays the verified official numeric grade authorized by the instructor (e.g., Score: 8.5/10). |
| (2) Rubrics Matrix Grid | Read-only container. Displays individual score values mapped directly against criteria metrics (Structure, Style, etc.). |
| (3) Evaluator Critique Cards | Display-only text blocks. Displays structural commentary strings reflecting qualitative strengths and areas for improvement. |
| (4) Back Navigation Link | Action link. Terminates the active assessment window view and securely redirects back to the main student interface. |

## **3\. Drafting Module and AI Staging**

### **3.1 Drafting Screen**

#### **3.1.1 Lesson Editor** 

This screen allows the User (SME/Instructor) to:

- **Configure Lesson Metadata:** enter structural identifiers including Lesson Name, parent Module mapping, and material Description.
- **Embed Video Content:** provide external streaming sources or leverage the "Generate Summary by AI" feature to automatically process and compile video transcription summaries.
- **Compose Educational Material:** draft comprehensive lecture notes or reference materials directly inside the primary text workspace.

On the screen, s/he can also:

- **Save Changes:** click the "Save" button to submit configurations and commit the lesson dataset updates.
- **Cancel Session:** click the "Cancel" button to wipe active local changes and safely exit the content manager layout.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Lesson Name | Text input. Required field. Allows entering the formal instructional title for the lesson row entry. |
| (2) Module Dropdown | Dropdown list. Required field. Associates the target lesson entry with an existing parent course module block. |
| (3) Video URL Field | Text input. Optional field. Accepts streaming endpoints (e.g., YouTube URL) to embed educational video frames. |
| (4) Summary Text Area | Rich text area. Pre-populated dynamically if the "Generate Summary by AI" hook is triggered. Allows manual text overrides. |
| (5) Description/Material Content | Rich text workspace. Required field. Allows manual drafting, formatting, and embedding of primary lecture content structures. |
| (6) Generate Summary by AI Button | Action button. Dispatches the active Video URL to the backend AI Service to extract automated timestamps or conceptual summaries. |
| (7) Save Button | Action button. Validates mandatory parameters, updates database states, and registers records to the course tree map. |
| (8) Cancel Button | Action button. Flushes temporary field buffers and routes the user back to the primary module content directory. |

#### **3.1.2 Assignment List**

This screen allows the Instructor / User to:

- **View Assignment List:** view a comprehensive table of assignments, including Assignment Name, Course, Class, Submission Count, and Status.
- **Filter Assignment List:** filter the records using dropdown selectors for Course, Class, and Status.
- **Search Assignments:** enter partial keywords in the search bar to locate specific assignments by their name.
- **Sort Assignment List:** sort the dataset (ascending/descending) by clicking on the column headers.

On the screen, s/he can also:

- **Manage Entries:** click the "Add New" button or individual "Edit" links to go to the Assignment Setup or Grading workspace screens.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Course Filter Dropdown | Dropdown list. Initial value: "All Course". Filters the data rows based on the selected master course. |
| (2) Class Filter Dropdown | Dropdown list. Initial value: "All Class". Narrow down visible records to a specific classroom instance. |
| (3) Status Filter Dropdown | Dropdown list. Initial value: "All Status". Filters assignments by active scheduling states (e.g., Active, Closed). |
| (4) Search Bar | Text input. Placeholder: "Search assignment...". Dynamically filters the grid rows matching the assignment title. |
| (5) Assignment Data Table | Data grid matrix. Displays core tracking columns: Name, Course, Class, Submissions, and Status. Headers support click-to-sort triggers. |
| (6) Action Links (Edit) | Hyperlink. Redirects the user to the detailed setup or dedicated split-screen workspace for manual/AI evaluation overrides. |
| (7) Add New Button | Action button. Redirects the user to a blank assignment creation form wizard. |

#### **3.1.3 Assignment Details**

This screen allows the Instructor to:

- **View Assignment Details:** view specific configuration fields of an assignment including Name, Course, Class, Max Score, Due Date, and Description.
- **Update Assignment Information:** input or edit data fields to setup or alter assignment parameters.
- **Validate Constraints:** ensure data completeness for required input parameters and correct date-time formatting logic.

On the screen, s/he can also:

- **Save Configuration:** click the "Save" button to validate entries, persist the assignment setup into the database, and return to the Assignment List.
- **Cancel Action:** click the "Cancel" button to discard all active form inputs and safely route back to the Assignment List.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Assignment Name | Text input. Required field. Allows the Instructor to enter or update the unique title for the assignment. |
| (2) Course Select Dropdown | Dropdown list. Required field. Binds the assignment to a specific master course module. |
| (3) Class Select Dropdown | Dropdown list. Required field. Maps the assignment to an active target classroom section instance. |
| (4) Max Score Input | Number input. Required field. Constraints: Must be a positive integer or decimal (e.g., 10). Defines the highest grade baseline. |
| (5) Due Date Picker | Date-Time calendar selector. Required field. Sets the exact submission expiration deadline for students. |
| (6) Description | Rich text area. Optional field. Allows writing comprehensive assignment prompts, task rules, and guidelines. |
| (7) Save Button | Action button. Triggers data structure schema checks, commits records to the database, and redirects to the Assignment List screen. |
| (8) Cancel Button | Action button. Flushes active text input box buffers and securely returns the user back to the primary list view. |

#### **3.1.4 Question Detail**

This screen allows the SME / Instructor to:

- **View Question Details:** view specific properties of a quiz question, including Question Content, Course mapping, Level, Answers list, and AI Explanation.
- **Update Question Information:** modify input data fields, configure multiple-choice options, and check radio buttons to set the correct answer key.
- **Validate Inputs:** ensure data consistency by enforcing required fields and verifying that at least one option is marked as correct.

On the screen, s/he can also:

- **Save Configuration:** click the "Save" button to validate entries, persist the question data into the database, and return to the Question Bank.
- **Cancel Action:** click the "Cancel" button to discard all active modifications and safely return to the Question Bank.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Question Content | Text area. Required field. Allows entering or editing the core text prompt of the question. |
| (2) Course Select Dropdown | Dropdown list. Required field. Binds the question entity to a specific master course module. |
| (3) Level Segment | Button group. Toggle choices: Easy, Medium, Hard. Sets the diagnostic complexity metric for test aggregation. |
| (4) Answer Option Inputs (A, B, C, D) | Text inputs. Required fields. Multiple text blocks to define alternative choice strings for the question. |
| (5) Correct Answer Selector | Radio buttons. Required choice. Allows marking the precise correct choice option corresponding to the answer text keys. |
| (6) AI Explanation | Text area. Optional/Auto-filled field. Displays the conceptual rationale and analysis explaining why the solution key is correct. |
| (7) Save Button | Action button. Triggers input schema validation checks, saves the records to the database, and redirects to the list view. |
| (8) Cancel Button | Action button. Flushes active field buffers and securely returns the user back to the primary question bank panel. |

#### **3.1.5 Flashcard Editor** 

This screen allows the SME / Instructor to:

- **Configure Flashcard Deck Metadata:** enter structural setup properties including Deck Name, Course selection, and Category classification.
- **Populate Interactive Content Rows:** input localized data properties dynamically within card collections split into Front (Term) and Back (Definition) properties.
- **Leverage Automated Generation:** click the "Generate by AI" button to instantly draft contextually comprehensive cards mapping back to the baseline metadata constraints.

On the screen, s/he can also:

- **Save Configuration:** click the "Save" button to validate row entry states, commit the deck to the database, and return to the Flashcard Library.
- **Cancel Action:** click the "Cancel" button to wipe field updates and safely revert to the previous library catalog panel.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Flashcard Deck Name | Text input. Required field. Allows specifying a unique conceptual title for the targeted flashcard collection. |
| (2) Course Select Dropdown | Dropdown list. Required field. Associates the flashcard deck configuration with a specific existing master course entity. |
| (3) Category Dropdown | Dropdown list. Required field. Sets the topic bucket tag to organize the target deck context layout inside the catalog view. |
| (4) Generate by AI a | Action button. Dispatches metadata inputs as structural prompt vectors to the backend AI engine to return automated cards. |
| (5) Front Text Input | Text input grid row. Required entry. Specifies the term description, phrase, or flashcard front canvas string layout. |
| (6) Back Text Input | Text input grid row. Required entry. Specifies the definition statement or response key attached to the card reverse canvas. |
| (7) Save Button | Action button. Validates text arrays, updates the primary datastore row parameters, and paths back to the catalog list view. |
| (8) Cancel Button | Action button. Discards active local text box field inputs and routes the user back to the primary workspace template view. |

#### **3.1.6 AI Flashcard Staging** 

This screen allows the SME / Instructor to:

- **Review AI-Generated Flashcards:** view a list of raw draft flashcard rows automatically created by the AI engine, separated into Front (Term) and Back (Definition).
- **Edit Staged Content:** modify or refine the text content of any generated flashcard term or definition directly within the data grid rows before saving.
- **Filter Staged List:** search or review specific text fragments within the temporary generated workspace collection.

On the screen, s/he can also:

- **Approve and Save:** click the "Save to Library" button to validate entries, migrate approved flashcards from the staging buffer into the permanent datastore, and sync with the Flashcard Library.
- **Cancel Session:** click the "Cancel" button to discard the entire AI-generated draft batch and safely return to the Flashcard Editor.

|     |     |
| --- | --- |
| Field Name | Description |
| (1) Target Deck Meta Banner | Display-only. Shows the targeted Flashcard Deck Name, Course selection, and Category mapping context. |
| (2) Staged Front Input | Editable grid cell input. Initial values: AI-generated candidate terms or phrases. Allows manual typing overrides. |
| (3) Staged Back Input | Editable grid cell input. Initial values: AI-generated candidate definitions or explanations. Allows manual text overrides. |
| (4) Save to Library Button | Action button. Enforces data validation rules, saves all active row records to the permanent database table, and redirects to the Library view. |
| (5) Cancel Button | Action button. Flushes the temporary staging memory array buffers and safely routes the user back to the Flashcard Editor screen. |

# **III. High-Level Design (Kien + Huy)**

## **1\. Software Architecture**

### **1.1 Sub-Systems/Components**

#### **1.1.1 User Interface (Razor Views, HTML/CSS/JS/Bootstrap)**

Receives display data from the Presentation Logic Layer (solid arrow Presentation Logic Layer → User Interface) and reads data directly from Entity Classes to render (solid arrow User Interface → Entity Classes) — e.g., displaying course lists, quiz questions, flashcards. Once the page is rendered, this layer sends the HTTP Response (dashed) back to the Web Browser.

#### **1.1.2 Presentation Logic Layer (ASP.NET Core Controllers)**

The entry point that receives the HTTP Request (solid) from the Web Browser. The Controller has three main responsibilities, represented by three outgoing solid arrows:

- Calls down to the **Business Logic Layer** to handle the core business logic.
- Calls directly into **DTO/ViewModel Classes** to bind user-submitted form/input data.
- In some cases, calls **Proxy Classes** directly (e.g., handling the Google OAuth login callback right at the Controller level, without going through a Service).  
    After the Business Logic Layer finishes processing, the result is returned back to the Controller via a **dashed**arrow (Business Logic Layer → Presentation Logic Layer), and the Controller then forwards it to the User Interface for rendering.

#### **1.1.3 DTO / ViewModel Classes (C# Models)**

Intermediate data structures used exclusively by the presentation layer (e.g., LoginViewModel, QuizTakingViewModel, EssaySubmitViewModel). They are called by both the **Presentation Logic Layer** and the **Business Logic Layer** (two solid arrows both pointing into DTO/ViewModel Classes) to package/filter data before display or after receiving user input, fully decoupling the UI from the Entity Classes.

#### **1.1.4 Business Logic Layer (Services)**

The central hub for business rules: user authentication, quiz scoring, essay rubric grading, flashcard scheduling (spaced repetition), and orchestration of AI-powered features (course outline generation, quiz generation, essay grading, flashcard extraction, student performance analysis). This layer has four outgoing solid arrows:

- To **Proxy Classes** — when the business logic requires calling an external service (AI, Payment, YouTube).
- To **DTO/ViewModel Classes** — when returning processed data to the Controller.
- To **Entity Classes** — when operating directly on the data model.
- To **Data Access Layer** — when data needs to be retrieved or persisted.  
    At the same time, the Business Logic Layer receives data back from the **Data Access Layer** via a **dashed** arrow, and returns its own result up to the **Presentation Logic Layer**, also via a dashed arrow.

#### **1.1.5 Data Access Layer (Repositories + DAOs – EF Core DbContext)**

Implements the Repository pattern on top of DAOs that use EF Core's DbContext. It receives solid-arrow calls from the Business Logic Layer and performs two actions:

- Maps data through **Entity Classes** (diagonal solid arrow).
- Executes queries against the **Database** (downward solid arrow).  
    Query results are returned back to the Business Logic Layer via a dashed arrow, and data from the Database is likewise returned to this layer via a dashed arrow.

#### **1.1.6 Entity Classes (EF Core Models)**

Classes that map one-to-one to database tables (User, Course, Module, Lesson, Quiz, Question, FlashcardDeck, Flashcard, Assignment, Submission, Payment, etc.). They serve as the shared intersection point of three layers: the Business Logic Layer, the Data Access Layer, and the User Interface (when data is displayed directly without going through a ViewModel).

#### **1.1.7 Proxy Classes (Service Clients: AI, Payment, YouTube, Google OAuth)**

Wrapper classes that isolate all communication with third-party APIs, called by both the **Presentation Logic Layer**and the **Business Logic Layer**. From here, the system calls out to **External Systems** (upward solid arrow) and receives an immediate response from the external system (downward solid arrow — since AI/Payment/YouTube APIs typically return results synchronously in a request-response manner, the return path is not separated into a dashed arrow as it is for the internal layers).

#### **1.1.8 Database (SQL Server / PostgreSQL)**

Stores all persistent system data as defined in the Database Design section (users, courses, quizzes, flashcards, assignments, submissions, payments, etc.).

### **1.2 External Interfaces**

#### **1.2.1 AI Service (LLM Engine)**

Invoked via Proxy Classes from the Business Logic Layer to power nearly all "smart" features: expanding course outlines/lecture content (FT-02a), generating quiz questions (FT-03), extracting flashcards from text (FT-04), grading essays against rubrics (FT-05), and analyzing student performance to produce a remediation roadmap (FT-06). The system sends a structured prompt (source text + instructions) and receives back structured JSON (questions, flashcards, scores, feedback).

#### **1.2.2 YouTube Data API**

Used in the Lesson Editor screen (FT-02b) to fetch the transcript/captions of a lesson's video, which is then forwarded to the AI Service to generate a summary.

#### **1.2.3 Payment Gateway (VNPay / SePay)**

Handles course/course-group purchase transactions. EduNexus creates a transaction, redirects the learner to the payment gateway, and receives a callback to update the Payment record status (PENDING, PAID, FAILED).

#### **1.2.4 Google OAuth 2.0**

Enables "Sign in with Google" on the Login/Register screens, called directly from the Presentation Logic Layer via Proxy Classes (not necessarily routed through the Business Logic Layer, since this is a simple, synchronous authentication flow).

#### **1.2.5 Notification Service (Email/Push)**

Sends notifications for asynchronous events — e.g., "your essay has been graded" (FT-05), "your quiz questions have been generated" (FT-03), or password-reset emails — via SMTP/SendGrid and/or in-app push notifications.

## **2\. Package Diagram**

**_Package descriptions_**

|     |     |     |
| --- | --- | --- |
| No  | Package Name | Description of roles and functions |
| **1** | **EduNexus.Controllers** | Acting as a bridge between the user interface and the system, it is responsible for receiving HTTP requests (such as login, submission, course viewing), and calling processing functions from the system layer.Services, and return the result toViews. |
| **2** | **EduNexus.Views** | Contains the user interface source code (HTML, CSS, JS, Razor Pages). This is where visual information is displayed for user interaction, rendered from the data provided.Controllers provide. |
| **3** | **EduNexus.Models**<br><br>_(Web Models / ViewModels)_ | It contains specialized data structures for web interfaces (ViewModels). Unlike Entities, this class only defines the data objects necessary for display.Viewsor securely receive form data from users. |
| **4** | **DataAccessLayer.Services** | The place that contains everything**Business Logic**of the system. Responsible for calculations, data validation, access control, etc., before making calls.Repositoriesto save to the database. |
| **5** | **DataAccessLayer.Repositories** | The middle layer follows the Repository Pattern design. It provides an abstract interface to the next layer.ServicesRetrieving data without knowing how that data was retrieved. |
| **6** | **DataAccessLayer.DAOs**<br><br>_(Data Access Objects)_ | The layer performs primitive operations with the database (CRUD - Create, Read, Update, Delete). The DAO classes directly call and use Entity Framework Core.DbContext) to execute the SQL query. |
| **7** | **DataAccessLayer.Models**<br><br>_(Entities)_ | Contains entities that map directly one-to-one to tables in an SQL database (e.g.,User, Course, Assignment,...). This layer is shared as a data standard for the entire system, from backend to frontend. |

# **IV. Database Design (Sy Huy)**

## **1\. Database Schema**

## **2\. Table Definitions**

### **2.1 Table: users**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| UserID | BIGINT | PK  | Auto Increment |
| FullName | VARCHAR(100) | NOT NULL | User full name |
| Email | VARCHAR(100) | UNIQUE, NOT NULL | Login email |
| PasswordHash | VARCHAR(255) | NOT NULL | Encrypted password |
| Role | VARCHAR(20) | NOT NULL | Student, Teacher, SME, Admin |
| AvatarUrl | VARCHAR(255) | NULL | Profile image |
| Status | VARCHAR(20) | NOT NULL | Active, Inactive |
| CreatedAt | DATETIME | NOT NULL | Creation date |

### **2.2 Table: CourseGroup**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| CourseGroupID | BIGINT | PK  | Auto Increment |
| Name | VARCHAR(100) | NOT NULL | Group name |
| Description | TEXT | NULL | Description |
| CreatedAt | DATETIME | NOT NULL | Creation date |

### **2.3 Tables: Course**

_Add one table block per additional entity following the same structure._

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| CourseID | BIGINT | PK  | Auto Increment |
| CourseGroupID | BIGINT | FK  | References CourseGroup |
| Title | VARCHAR(200) | NOT NULL | Course title |
| Description | TEXT | NULL | Course description |
| Status | VARCHAR(20) | NOT NULL | Draft, Published |
| CreatedAt | DATETIME | NOT NULL | Creation date |

### **2.4 Tables: Module**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| ModuleID | BIGINT | PK  | Auto Increment |
| CourseID | BIGINT | FK  | References Course |
| Title | VARCHAR(200) | NOT NULL | Module title |
| Description | TEXT | NULL | Description |
| OrderNo | INT | NOT NULL | Display order |

### **2.5 Tables: Lesson**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| LessonID | BIGINT | PK  | Auto Increment |
| ModuleID | BIGINT | FK  | References Module |
| Title | VARCHAR(200) | NOT NULL | Lesson title |
| VideoUrl | VARCHAR(500) | NULL | YouTube URL |
| Summary | TEXT | NULL | AI Summary |
| Content | LONGTEXT | NOT NULL | Lesson content |

### **2.6 Tables: Class**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| ClassID | BIGINT | PK  | Auto Increment |
| CourseID | BIGINT | FK  | References Course |
| TeacherID | BIGINT | FK  | References User |
| Name | VARCHAR(100) | NOT NULL | Class name |
| StartDate | DATE | NOT NULL | Start date |
| EndDate | DATE | NOT NULL | End date |
| Capacity | INT | NOT NULL | Max students |
| Status | VARCHAR(20) | NOT NULL | Open, Closed |

### **2.7 Tables: Enrollment**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| EnrollmentID | BIGINT | PK  | Auto Increment |
| UserID | BIGINT | FK  | References User |
| ClassID | BIGINT | FK  | References Class |
| EnrollDate | DATETIME | NOT NULL | Enrollment date |
| Status | VARCHAR(20) | NOT NULL | Active, Dropped |

### **2.8 Tables: Assignment**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| AssignmentID | BIGINT | PK  | Auto Increment |
| ClassID | BIGINT | FK  | References Class |
| Title | VARCHAR(200) | NOT NULL | Assignment title |
| Description | TEXT | NULL | Instructions |
| MaxScore | DECIMAL(5,2) | NOT NULL | Maximum score |
| DueDate | DATETIME | NOT NULL | Deadline |

### **2.9 Tables: Submission**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| SubmissionID | BIGINT | PK  | Auto Increment |
| AssignmentID | BIGINT | FK  | References Assignment |
| StudentID | BIGINT | FK  | References User |
| Content | LONGTEXT | NULL | Essay content |
| FileUrl | VARCHAR(500) | NULL | Uploaded file |
| Score | DECIMAL(5,2) | NULL | Final score |
| Feedback | TEXT | NULL | Teacher feedback |
| Status | VARCHAR(20) | NOT NULL | Submitted, Graded |
| SubmittedAt | DATETIME | NOT NULL | Submission date |

### **2.10 Tables: FlashcardDeck**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| DeckID | BIGINT | PK  | Auto Increment |
| CourseID | BIGINT | FK  | References Course |
| Name | VARCHAR(200) | NOT NULL | Deck name |
| Category | VARCHAR(100) | NOT NULL | Category |

### **2.11 Tables: Flashcard**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| CardID | BIGINT | PK  | Auto Increment |
| DeckID | BIGINT | FK  | References FlashcardDeck |
| FrontText | TEXT | NOT NULL | Question side |
| BackText | TEXT | NOT NULL | Answer side |

### **2.12 Tables: Payment**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| PaymentID | BIGINT | PK  | Auto Increment |
| UserID | BIGINT | FK  | References User |
| CourseGroupID | BIGINT | FK  | References CourseGroup |
| Amount | DECIMAL(10,2) | NOT NULL | Payment amount |
| Status | VARCHAR(20) | NOT NULL | Pending, Paid, Failed |
| Gateway | VARCHAR(20) | NOT NULL | VNPay, SePay |
| PaymentDate | DATETIME | NOT NULL | Transaction date |

### **2.13 Tables: Quiz**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| Quiz_ID | BIGINT | PK  | Auto Increment |
| Course_ID | BIGINT | FK  | References Course |
| Quiz_Name | VARCHAR(200) | NOT NULL | Quiz title |
| Difficulty | VARCHAR(20) | NOT NULL | Easy / Medium / Hard |
| Created_By | BIGINT | FK  | References User |

### **2.14 Tables: Question**

|     |     |     |     |
| --- | --- | --- | --- |
| **Column** | **Type** | **Constraints** | **Notes** |
| Question_ID | BIGINT | PK  | Auto Increment |
| Quiz_ID | BIGINT | FK  | References Quiz |
| Content | TEXT | NOT NULL | Question content |
| Option_A | VARCHAR(500) | NOT NULL | Answer option A |
| Option_B | VARCHAR(500) | NOT NULL | Answer option B |
| Option_C | VARCHAR(500) | NOT NULL | Answer option C |
| Option_D | VARCHAR(500) | NOT NULL | Answer option D |
| Correct_Answer | CHAR(1) | NOT NULL | A/B/C/D |
| AI_Explanation | TEXT | NULL | AI generated explanation |

## **3\. Enum / Lookup Values**

|     |     |     |     |
| --- | --- | --- | --- |
| **Table** | **Column** | **Allowed Values** | **Notes** |
| users | Role | ADMIN, SME, TEACHER, STUDENT | User role in system |
| users | Status | ACTIVE, INACTIVE | Account status |
| course | Status | DRAFT, PUBLISHED | Course lifecycle |
| class | Status | OPEN, CLOSED | Class availability |
| enrollment | Status | ACTIVE, DROPPED | Student enrollment state |
| submission | Status | SUBMITTED, GRADED | Assignment status |
| payment | Status | PENDING, PAID, FAILED | Payment transaction status |
| payment | Gateway | VNPAY, SEPAY | Payment provider |
| quiz | Difficulty | EASY, MEDIUM, HARD | Quiz difficulty level |

## **4\. Indexing Strategy**

|     |     |     |     |
| --- | --- | --- | --- |
| **Table** | **Index Column(s)** | **Type** | **Reason** |
| users | Email | UNIQUE | Login lookup and uniqueness |
| users | Role | BTREE | Filter users by role |
| course | CourseGroupID | BTREE | Retrieve courses by group |
| module | CourseID | BTREE | Retrieve modules by course |
| lesson | ModuleID | BTREE | Retrieve lessons by module |
| class | CourseID | BTREE | Retrieve classes by course |
| enrollment | UserID | BTREE | Find enrolled classes of a student |
| enrollment | ClassID | BTREE | List students in class |
| submission | AssignmentID | BTREE | Retrieve submissions by assignment |
| submission | StudentID | BTREE | Retrieve student's submissions |
| flashcarddeck | CourseID | BTREE | Retrieve decks by course |
| flashcard | DeckID | BTREE | Retrieve cards in a deck |
| quiz | Course_ID | BTREE | Retrieve quizzes by course |
| question | Quiz_ID | BTREE | Retrieve questions by quiz |
| payment | UserID | BTREE | Retrieve user payment history |
| payment | CourseGroupID | BTREE | Retrieve payments by course group |

## **5\. Seed Data**

### **5.1 Minimum accounts required:**

|     |     |     |
| --- | --- | --- |
| **Full Name** | **Role** | **Purpose** |
| System Admin | ADMIN | Manage users and system settings |
| SME User | SME | Create courses, quizzes and flashcards |
| Teacher User | TEACHER | Manage classes and assignments |
| Student One | STUDENT | Test learning functions |
| Student Two | STUDENT | Test quizzes, submissions and AI analysis |

**5.2 Minimum domain data required:  
**

|     |     |     |
| --- | --- | --- |
| **Entity** | **Count** | **States Needed** |
| Course Group | 2   | Active groups |
| Course | 2   | 1 Draft, 1 Published |
| Module | 4   | Linked to courses |
| Lesson | 6   | With AI summary data |
| Class | 2   | 1 Open, 1 Closed |
| Enrollment | 3   | Active students |
| Assignment | 2   | Available assignments |
| Submission | 2   | 1 Submitted, 1 Graded |
| Flashcard Deck | 2   | Learning decks |
| Flashcard | 10  | Vocabulary cards |
| Quiz | 2   | Easy and Medium difficulty |
| Question | 10  | Multiple-choice questions |
| Payment | 2   | 1 Paid, 1 Pending |

\-- src/main/resources/db/seed/data.sql

\-- All passwords = BCrypt hash of "Test@1234" (strength 12)

\-- Hash: $2a$12$RHpToERtUxpwgQFI5ySL4uiqjH.kVxTbdRHJAQJOkIMlrkK65OoVi

INSERT INTO users (username, password_hash, full_name, email, role, is_active) VALUES

('admin', '$2a$12$RHpTo...', 'System Admin', 'admin@co.com', 'ADMIN', true),

('hr_manager', '$2a$12$RHpTo...', 'HR Manager', 'hr@co.com', 'HR_MANAGER', true),

('interviewer', '$2a$12$RHpTo...', 'Interviewer', 'int@co.com', 'INTERVIEWER', true),

('candidate_01', '$2a$12$RHpTo...', 'Candidate One', 'cand01@gmail.com', 'CANDIDATE', true),

('candidate_02', '$2a$12$RHpTo...', 'Candidate Two', 'cand02@gmail.com', 'CANDIDATE', true);

INSERT INTO jobs (title, department, location, description, status, created_by) VALUES

('Senior Java Developer', 'Engineering', 'Hanoi', 'Build backend services', 'DRAFT', 2),

('Product Manager', 'Product', 'Hanoi', 'Own product roadmap', 'ACTIVE', 2);

INSERT INTO applications (job_id, candidate_id, cv_file_path, status) VALUES

(2, 4, 'uploads/cv/2/4_cv.pdf', 'APPLIED'),

(2, 5, 'uploads/cv/2/5_cv.pdf', 'SCREENING');

# **V. Detailed Design (Tung)**

## **1\. Class Diagram**

## **2\. Sequence Diagram**

### **2.1 FT-02a: AI Course Outline Expansion by SME**

### **2.2 FT-02b: AI Video Summarization via YouTube Integration**

### **2.3 FT-03: AI-Powered Revision Quiz Generation and Approval**

### **2.4 FT-04: AI Flashcard Extraction and Deck Management**

### **2.5 FT-05: AI Preliminary Essay Evaluation and Instructor Verification**

### **2.6 FT-06: AI Student Performance Analysis and Targeted Remediation Roadmap**

## **3\. Activity Diagram**

### **3.1 FT-02a: AI Course Outline Expansion to Lectures**

- **Summary:** The Subject Matter Expert (SME) provides an initial course title or a brief, rough syllabus. The system forwards the request to the AI Subsystem to analyze and automatically generate a detailed course hierarchical tree structure (containing major chapters and milestones). Subsequently, the SME can select specific milestones for the AI to dynamically expand into exhaustive lecture content, saving significant curriculum development time.
- **Preconditions:** The SME has successfully logged into the EduNexus platform with course management privileges and accessed the "Course Content Management" interface.
- **Main Sequence:**
    1.  The SME enters the core course title or basic raw outline metrics and triggers the "Generate Outline via AI" action.
    2.  The system captures the inputs and routes the processing prompt payload to the AI Service.
    3.  The AI Service processes the prompt and returns a structured lesson hierarchy tree array in JSON format within 25 seconds.
    4.  The system renders the draft hierarchical tree visually on the workspace for SME inspection.
    5.  The SME selects a specific chapter node and clicks "Expand Content".
    6.  The AI Service generates granular lecture notes and educational materials for that section, returning the final text to be saved by the SME.
- **Alternative Sequences:** \* _AI Subsystem Connection Timeout:_ If the AI Service fails to respond within the designated 25-second window, the system throws an alert saying "AI system is currently busy, please try again" and allows the SME to input the structure manually.
- **Postconditions:** The AI-generated course structure and comprehensive lecture materials are safely committed to the PostgreSQL database under a "Draft" state, awaiting further manual refinements by the SME.

### **3.2 FT-02b: AI Video Summarization (YouTube Integration)**

- **Summary:** The SME glues a standard YouTube video link into the course module setup. The system interfaces directly with the official YouTube API to fetch the embedded closed-captions data (transcript). It then transfers this data to the AI Service to interpret, translate, and synthesize the information into a cohesive Vietnamese summary write-up within a sub-4-second threshold.
- **Preconditions:** The SME possesses editing permissions for the target lesson unit, and the designated YouTube video must be set to Public or Unlisted visibility.
- **Main Sequence:**
    1.  The SME pastes the YouTube URL into the designated field and hits the "Summarize with AI" button.
    2.  The system verifies the URL format and invokes the YouTube API to extract the timestamped raw text transcript.
    3.  The system passes the unformatted raw transcript over to the AI Service alongside a pre-configured summarization prompt.
    4.  The AI Service interprets the dataset and returns a formatted summary markdown containing primary takeaways and key timestamps.
    5.  The system commits the summarized document to the course repository and displays it instantly to the SME.
- **Alternative Sequences:** \* _Missing Transcript or Invalid URL:_ If the YouTube API returns an empty dataset or an authorization error, the system halts execution and flashes an error notification: "Video transcript is unavailable or the URL is invalid."
- **Postconditions:** The Vietnamese-localized AI summary box is saved and immediately rendered directly beneath the student's video player window.

### **3.3 FT-03: AI Automated Revision Quiz Generation**

- **Summary:** The system automatically parses the textual content of a published lecture node (either a document uploaded by the SME or an AI-generated summary). It interfaces with the AI Subsystem to instantly engineer a target set of multiple-choice evaluation questions (Quizzes), complete with structured distractors, correct keys, and textual explanations.
- **Preconditions:** The target lecture item contains a valid text-based payload or an active cached summary within the database.
- **Main Sequence:**
    1.  The SME selects a lesson node and fires the "Generate Quiz via AI" command.
    2.  The system reads the full textual content of the lecture and transmits a structured prompt specifying the question quantity and format constraints to the AI Service.
    3.  The AI Service processes the input data and yields a draft list of single-choice questions (A, B, C, D) along with answer annotations.
    4.  The system pushes the pending questions into the "Review Buffer Queue" (BR-05) and maps them onto the SME's review interface.
    5.  The SME evaluates, rewires phrasing errors, adjusts incorrect keys, and clicks the "Publish Quiz" button.
- **Alternative Sequences:** \* _Insufficient Text Length:_ If the underlying text asset is too sparse or empty, the system blocks the dispatch loop and triggers an validation alert: "Insufficient lecture text depth to facilitate automated quiz generation."
- **Postconditions:** The revised assessment items are converted to an "Active/Published" status, immediately making the evaluation suite available for student completion.

### **3.4 FT-04: Educational Flashcard Deck Management**

- **Summary:** This module empowers the SME to construct vocabulary and terminology-driven memory card decks (Flashcards) to help students master keywords via 3 distinct workflows: manual data entry, bulk Excel template ingestion, or utilizing AI text scanning to dynamically parse terminology blocks.
- **Preconditions:** The SME has navigated to the Flashcard Management segment of an active classroom or module interface.
- **Main Sequence:**
    1.  The SME selects 1 of the 3 ingestion methods available on the control dashboard.
    2.  **\[Manual Branch\]:** The SME manually inputs the Front-face (Term) and Back-face (Definition) $\\rightarrow$ The system runs validations and commits the entries immediately.
    3.  **\[Excel Ingestion Branch\]:** The SME uploads a standardized .xlsx spreadsheet $\\rightarrow$ The system parses rows, extracts vocabulary columns, and triggers batch insertion.
    4.  **\[AI Extraction Branch\]:** The AI Service scans the specified course manual text $\\rightarrow$ It abstracts keyword-definition pairs $\\rightarrow$ The system inserts the items into the temporary holding queue (BR-07) and fires a system notification (NTF-02).
    5.  The SME undergoes an iterative review loop to filter or edit the AI-generated pairs, then clicks "Finalize Deck".
- **Alternative Sequences:** \* _Malformatted Spreadsheet Columns:_ If the uploaded Excel file violates the system's template architecture, the parser rejects the payload, mapping specific row failures onto the UI, and requests a clean re-upload.
- **Postconditions:** The newly validated flashcard deck is added to the student's study vault, instantly synchronizing learning indicators across both web and mobile client applications.

### **3.5 FT-05: Automated AI-Driven Assignment Grading and Feedback**

- **Summary:** When a student submits an assignment, the system automatically retrieves the grading criteria and sends the submission to the AI Engine. The AI Engine analyzes the work based on the criteria, generates a score and feedback, and updates the database. The system then immediately notifies the student and displays the final results.
- **Preconditions:** The student is logged into the system and the teacher has already set up the grading criteria (rubrics) for the assignment.

Main Sequence:

1.  The student uploads and submits their assignment.
2.  The System records the submission and retrieves both the submission content and the grading criteria.
3.  The System sends the submission data to the AI Engine for grading.
4.  The AI Engine analyzes the submission based on each specific criterion.
5.  The AI Engine generates the final score and detailed feedback, then sends the results back to the System.
6.  The System updates the database with the new score and feedback.
7.  The System sends a notification to the student.
8.  The student views their graded assignment and AI feedback directly on their interface.

Alternative Sequences:

- **AI Engine Failure:** If the AI Engine encounters an error or fails to analyze the submission, the System safely retains the student's assignment, marks the status as "Pending Manual Grading," and notifies the teacher to grade the work manually.

Postconditions:

- The score and feedback are saved in the system database.
- The student can view their graded results, and the master gradebook is updated automatically.

### **3.6 FT-06: AI Student Performance Analysis and Targeted Remediation Roadmap**

- Summary: When a student clicks to view their analysis, the system automatically accesses the database, packages their learning history, and sends an analysis request to the AI Engine. The AI Engine analyzes knowledge gaps and recommends ways to improve. After receiving the results, the system saves the data to the DB, automatically creates competency charts and improvement tips, and displays the strengths/weaknesses report and a personalized learning roadmap to the student.
- Preconditions: The student is logged into the system and has existing quiz/test history data stored in the database.

Main Sequence:

1.  The student clicks the "View AI Analysis" button.
2.  The System accesses the database to retrieve the student's historical data.
3.  The System packages the data and sends an analysis request to the AI Engine.
4.  The AI Engine analyzes the student's knowledge gaps.
5.  The AI Engine recommends specific ways and steps to improve.
6.  The System receives the analysis results and recommendations from the AI Engine.
7.  The System saves the analysis results into the database (DB).
8.  The System automatically creates competency charts and improvement tips.
9.  The student views their strengths and weaknesses report from the AI on the interface.
10. The student receives their personalized remediation roadmap.

Alternative Sequences:

- AI Analysis Failure: If the AI Engine encounters an error or fails to analyze the data, the System displays a message: "Analysis service is temporarily unavailable, please try again later," and shows the standard system performance charts without AI insights.

Postconditions:

- The AI-generated analysis data and roadmap are successfully saved in the database.
- The competency charts and remediation roadmap display correctly on the student's interface.

…