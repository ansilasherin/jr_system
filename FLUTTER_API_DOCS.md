# Flutter API Documentation - Job Recruitment System

This document contains the APIs needed to build the Flutter app for the Job Recruitment workflow.

## Base URLs

Local Django server:

```text
http://127.0.0.1:8000
```

Core API base:

```text
http://127.0.0.1:8000/api/register
```

MCQ API base:

```text
http://127.0.0.1:8000/api/mcq
```

For Android emulator, use this instead of `127.0.0.1`:

```text
http://10.0.2.2:8000
```

## Common Headers

For public JSON APIs:

```http
Content-Type: application/json
```

For protected APIs:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

For file upload APIs:

```http
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

Login returns the token. Store it in Flutter using secure storage.

## User Roles

Candidate role:

```text
user
```

HR role:

```text
hr
```

## Application Status Values

```text
applied
under_review
approved
rejected
hired
```

Legacy status still present in database:

```text
pending
interview_completed
```

For the Flutter app workflow, use only:

```text
applied -> under_review -> approved/rejected -> hired
```

## Complete API Flow

```text
Candidate Register/Login
        ↓
Create/Update Profile + Upload CV
        ↓
Extract Skills from CV
        ↓
List Jobs / Skill Matched Jobs
        ↓
Apply Job
        ↓
HR Review
        ↓
HR Approves Candidate
        ↓
Candidate Takes MCQ
        ↓
HR Marks Candidate as Hired
```

# 1. Authentication APIs

## 1.1 Candidate Registration

Endpoint:

```http
POST /api/register/auth/register/candidate/
```

Authentication:

```text
Not required
```

Content-Type:

```http
multipart/form-data
```

Request fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `full_name` | string | Yes | Candidate full name |
| `email` | string | Yes | Candidate email |
| `phone` | string | No | Phone number |
| `course` | string | No | Course/department |
| `password` | string | No | If not sent, backend creates one |
| `cv` or `resume` | file | No | Resume PDF |
| `photo` or `profile` | file | No | Profile photo |

Example response:

```json
{
  "success": true,
  "user": {
    "id": 1,
    "full_name": "Ameer Shirin",
    "email": "ameer@example.com",
    "phone": "9876543210",
    "course": "BCA",
    "role": "user",
    "cv_url": "/media/resume.pdf",
    "profile_url": "/media/photo.jpg",
    "skills": ["Python", "Django"],
    "registered_at": "2026-05-05T10:00:00+00:00"
  }
}
```

Flutter note:

Use `MultipartRequest` for this API.

## 1.2 HR Registration

Endpoint:

```http
POST /api/register/auth/register/hr/
```

Authentication:

```text
Not required
```

Headers:

```http
Content-Type: application/json
```

Request body:

```json
{
  "full_name": "HR Manager",
  "email": "hr@example.com",
  "phone": "9876543210",
  "department": "Recruitment",
  "password": "password123"
}
```

Example response:

```json
{
  "success": true,
  "user": {
    "id": 2,
    "full_name": "HR Manager",
    "email": "hr@example.com",
    "role": "hr",
    "skills": []
  }
}
```

## 1.3 Login

Endpoint:

```http
POST /api/register/auth/login/
```

Authentication:

```text
Not required
```

Headers:

```http
Content-Type: application/json
```

Request body:

```json
{
  "email": "ameer@example.com",
  "password": "password123"
}
```

Example response:

```json
{
  "success": true,
  "token": "abc123tokenvalue",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "full_name": "Ameer Shirin",
    "email": "ameer@example.com",
    "role": "user",
    "skills": ["Python", "Django"]
  }
}
```

Flutter token usage:

```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

## 1.4 Logout

Endpoint:

```http
POST /api/register/auth/logout/
```

Authentication:

```text
Candidate or HR
```

Headers:

```http
Authorization: Bearer <token>
```

Example response:

```json
{
  "success": true,
  "message": "Logged out."
}
```

# 2. Candidate Profile and CV APIs

## 2.1 Get Profile

Endpoint:

```http
GET /api/register/candidate/profile/
```

Authentication:

```text
Candidate or HR
```

Headers:

```http
Authorization: Bearer <token>
```

Example response:

```json
{
  "success": true,
  "user": {
    "id": 1,
    "full_name": "Ameer Shirin",
    "email": "ameer@example.com",
    "phone": "9876543210",
    "course": "BCA",
    "role": "user",
    "cv_url": "/media/resume.pdf",
    "profile_url": "/media/photo.jpg",
    "skills": ["Python", "Django"]
  }
}
```

## 2.2 Update Profile

Endpoint:

```http
PATCH /api/register/candidate/profile/
```

Authentication:

```text
Candidate or HR
```

Headers:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

Request body:

```json
{
  "full_name": "Updated Name",
  "email": "updated@example.com",
  "phone": "9876543210",
  "course": "BCA"
}
```

Example response:

```json
{
  "success": true,
  "user": {
    "id": 1,
    "full_name": "Updated Name",
    "email": "updated@example.com",
    "role": "user",
    "skills": ["Python", "Django"]
  }
}
```

## 2.3 Upload CV / Profile Photo

Endpoint:

```http
POST /api/register/candidate/profile/
```

Authentication:

```text
Candidate or HR
```

Content-Type:

```http
multipart/form-data
```

Request fields:

| Field | Type | Required |
|---|---|---|
| `full_name` | string | No |
| `email` | string | No |
| `phone` | string | No |
| `course` | string | No |
| `cv` or `resume` | file | No |
| `photo` or `profile` | file | No |

Example response:

```json
{
  "success": true,
  "user": {
    "id": 1,
    "cv_url": "/media/new_resume.pdf",
    "profile_url": "/media/new_photo.jpg",
    "skills": ["Python", "Django", "SQL"]
  }
}
```

# 3. Skill Extraction API

## 3.1 Extract Skills From CV

Endpoint:

```http
POST /api/register/candidate/skills/extract/
```

Authentication:

```text
Candidate only
```

Content-Type:

```http
multipart/form-data
```

Request:

| Field | Type | Required |
|---|---|---|
| `cv` or `resume` | file | Yes |

Example response:

```json
{
  "success": true,
  "skills": ["Python", "Django", "React", "SQL"],
  "cv_url": "/media/resume.pdf"
}
```

Allowed CV formats:

```text
PDF, DOC, DOCX
```

Maximum upload size:

```text
5 MB
```

## 3.2 Candidate Dashboard Aggregate

Endpoint:

```http
GET /api/register/candidate/dashboard/
```

Authentication:

```text
Candidate only
```

Response:

```json
{
  "success": true,
  "profile": {},
  "recommended_jobs": [],
  "recent_applications": [],
  "saved_jobs": []
}
```

# 4. Job Vacancy APIs

## 4.1 List All Open Jobs

Endpoint:

```http
GET /api/register/jobs/
```

Authentication:

```text
Optional
```

Example response:

```json
{
  "success": true,
  "jobs": [
    {
      "id": 1,
      "job_title": "Django Developer",
      "company": "ABC Tech",
      "company_id": 1,
      "hr_id": 2,
      "location": "Kochi",
      "duration": "6 months",
      "stipend": "10000",
      "deadline": "2026-06-01",
      "skills": ["Python", "Django", "SQL"],
      "description": "Backend developer internship",
      "status": "open",
      "match_score": 66
    }
  ]
}
```

## 4.2 Search Jobs

Endpoint:

```http
GET /api/register/jobs/?q=python
```

Authentication:

```text
Optional
```

Search checks:

```text
job title, skills, location
```

Pagination and filters:

```http
GET /api/register/jobs/?page=1&page_size=10
GET /api/register/jobs/?location=Kochi
GET /api/register/jobs/?skills=Flutter,Dart
GET /api/register/jobs/?q=flutter&location=Calicut&skills=REST API
```

Job responses include dashboard-friendly fields:

```json
{
  "salary_stipend": "8000",
  "experience_required": "0-1 years",
  "skills_required": ["Flutter", "Dart"],
  "posted_date": "2026-05-15T10:00:00+00:00",
  "applied": false,
  "saved": true
}
```

## 4.3 Skill Matched Jobs

Endpoint:

```http
GET /api/register/jobs/?skill_match=1
```

Authentication:

```text
Candidate only
```

Headers:

```http
Authorization: Bearer <candidate_token>
```

Response:

Jobs are sorted by `match_score`.

## 4.4 Job Details

Endpoint:

```http
GET /api/register/jobs/<job_id>/
```

Example:

```http
GET /api/register/jobs/1/
```

Authentication:

```text
Optional
```

Example response:

```json
{
  "success": true,
  "job": {
    "id": 1,
    "job_title": "Django Developer",
    "company": "ABC Tech",
    "location": "Kochi",
    "skills": ["Python", "Django", "SQL"],
    "description": "Backend developer internship",
    "status": "open",
    "match_score": 66
  }
}
```

## 4.5 HR Companies

Endpoint:

```http
POST /api/register/hr/companies/
```

Authentication:

```text
HR only
```

Headers:

```http
Authorization: Bearer <hr_token>
Content-Type: application/json
```

Single company body:

```json
{
  "company_name": "Nucore Software Solutions",
  "email": "hr@nucore.com",
  "website": "https://www.nucore.in/",
  "location": "Calicut"
}
```

Multiple companies body:

```json
{
  "companies": [
    {
      "company_name": "Nucore Software Solutions",
      "email": "hr@nucore.com",
      "website": "https://www.nucore.in/",
      "location": "Calicut"
    },
    {
      "company_name": "ABC Tech",
      "email": "hr@abctech.com",
      "website": "https://www.abctech.com/",
      "location": "Kochi"
    }
  ]
}
```

Raw JSON list is also accepted:

```json
[
  {
    "company_name": "Nucore Software Solutions",
    "email": "hr@nucore.com",
    "website": "https://www.nucore.in/",
    "location": "Calicut"
  },
  {
    "company_name": "ABC Tech",
    "email": "hr@abctech.com",
    "website": "https://www.abctech.com/",
    "location": "Kochi"
  }
]
```

Example response:

```json
{
  "success": true,
  "companies": [
    {
      "id": 1,
      "company_name": "Nucore Software Solutions",
      "email": "hr@nucore.com",
      "website": "https://www.nucore.in/",
      "location": "Calicut"
    },
    {
      "id": 2,
      "company_name": "ABC Tech",
      "email": "hr@abctech.com",
      "website": "https://www.abctech.com/",
      "location": "Kochi"
    }
  ]
}
```

List companies:

```http
GET /api/register/hr/companies/
```

Use the returned company `id` as `company_id` when creating a job.

## 4.6 HR Create Job

Endpoint:

```http
POST /api/register/hr/jobs/
```

Authentication:

```text
HR only
```

Headers:

```http
Authorization: Bearer <hr_token>
Content-Type: application/json
```

Single-job request body:

```json
{
  "job_title": "Django Developer",
  "company_id": 1,
  "location": "Kochi",
  "duration": "6 months",
  "stipend": "10000",
  "deadline": "2026-06-01",
  "skills": "Python, Django, SQL",
  "description": "Backend developer internship for Django projects.",
  "status": "open"
}
```

`skills` can be a comma-separated string or a JSON list:

```json
"skills": ["Python", "Django", "SQL"]
```

Multiple jobs request body:

```json
{
  "jobs": [
    {
      "job_title": "Django Developer",
      "company_id": 1,
      "location": "Kochi",
      "duration": "6 months",
      "stipend": "10000",
      "deadline": "2026-06-01",
      "skills": "Python, Django, SQL",
      "description": "Backend developer internship for Django projects.",
      "status": "open"
    },
    {
      "job_title": "Flutter Developer",
      "company_id": 1,
      "location": "Calicut",
      "duration": "3 months",
      "stipend": "8000",
      "deadline": "2026-06-15",
      "skills": "Flutter, Dart, REST API",
      "description": "Mobile app internship for Flutter projects.",
      "status": "open"
    }
  ]
}
```

Raw JSON list is also accepted:

```json
[
  {
    "job_title": "Django Developer",
    "company_id": 1,
    "location": "Kochi",
    "duration": "6 months",
    "stipend": "10000",
    "deadline": "2026-06-01",
    "skills": "Python, Django, SQL",
    "description": "Backend developer internship for Django projects.",
    "status": "open"
  },
  {
    "job_title": "Flutter Developer",
    "company_id": 1,
    "location": "Calicut",
    "duration": "3 months",
    "stipend": "8000",
    "deadline": "2026-06-15",
    "skills": "Flutter, Dart, REST API",
    "description": "Mobile app internship for Flutter projects.",
    "status": "open"
  }
]
```

Required fields:

```text
job_title
company_id
location
duration
stipend
deadline
skills
description
```

Allowed status values:

```text
open
draft
closed
```

Example response:

```json
{
  "success": true,
  "job": {
    "id": 1,
    "job_title": "Django Developer",
    "company": "ABC Tech",
    "company_id": 1,
    "hr_id": 2,
    "location": "Kochi",
    "duration": "6 months",
    "stipend": "10000",
    "deadline": "2026-06-01",
    "skills": ["Python", "Django", "SQL"],
    "description": "Backend developer internship for Django projects.",
    "status": "open"
  }
}
```

# 5. Job Application APIs

## 5.0 Save / Unsave Job

Save:

```http
POST /api/register/jobs/<job_id>/save/
```

Unsave:

```http
DELETE /api/register/jobs/<job_id>/save/
```

List saved jobs:

```http
GET /api/register/candidate/saved-jobs/
```

Authentication:

```text
Candidate only
```

## 5.1 Apply For Job

Endpoint:

```http
POST /api/register/applications/apply/
```

Authentication:

```text
Candidate only
```

Headers:

```http
Authorization: Bearer <candidate_token>
Content-Type: application/json
```

Request body:

```json
{
  "job_id": 1
}
```

Example response:

```json
{
  "success": true,
  "application": {
    "id": 10,
    "match_score": 80,
    "status": "applied",
    "applied_at": "2026-05-05T10:30:00+00:00",
    "mcq_score": null,
    "mcq_passed": false
  }
}
```

If already applied:

```json
{
  "success": false,
  "message": "Already applied.",
  "application": {}
}
```

## 5.2 Candidate Application List

Endpoint:

```http
GET /api/register/applications/
```

Authentication:

```text
Candidate only
```

Headers:

```http
Authorization: Bearer <candidate_token>
```

Example response:

```json
{
  "success": true,
  "applications": [
    {
      "id": 10,
      "status": "approved",
      "match_score": 80,
      "mcq_score": null,
      "mcq_passed": false,
      "job": {
        "id": 1,
        "job_title": "Django Developer"
      }
    }
  ]
}
```

# 6. HR Review APIs

## 6.1 HR View Applications

Endpoint:

```http
GET /api/register/hr/applications/
```

Authentication:

```text
HR only
```

Headers:

```http
Authorization: Bearer <hr_token>
```

Optional filter:

```http
GET /api/register/hr/applications/?status=applied
GET /api/register/hr/applications/?status=approved
GET /api/register/hr/applications/?status=rejected
GET /api/register/hr/applications/?status=hired
```

Example response:

```json
{
  "success": true,
  "applications": [
    {
      "id": 10,
      "candidate": {
        "id": 1,
        "full_name": "Ameer Shirin",
        "email": "ameer@example.com",
        "cv_url": "/media/resume.pdf",
        "skills": ["Python", "Django"]
      },
      "job": {
        "id": 1,
        "job_title": "Django Developer"
      },
      "match_score": 80,
      "status": "applied",
      "mcq_score": null
    }
  ]
}
```

## 6.2 HR Approve / Reject Candidate

Endpoint:

```http
PATCH /api/register/hr/applications/<app_id>/status/
```

Authentication:

```text
HR only
```

Allowed status values:

```text
under_review
approved
rejected
```

Request body:

```json
{
  "status": "approved"
}
```

Example response:

```json
{
  "success": true,
  "application": {
    "id": 10,
    "status": "approved",
    "match_score": 80,
    "mcq_score": null
  }
}
```

Important:

Only candidates with `approved` status can start MCQ.

# 7. MCQ Test APIs

## 7.1 Start MCQ Exam

Endpoint:

```http
GET /api/mcq/start/<job_id>/<user_id>/
```

Example:

```http
GET /api/mcq/start/1/1/
```

Authentication:

```text
Approved candidate only
```

Headers:

```http
Authorization: Bearer <candidate_token>
```

Example response:

```json
{
  "success": true,
  "title": "Internship Screening Test",
  "duration_seconds": 1200
}
```

If HR has not approved the application:

```json
{
  "success": false,
  "message": "Approved application not found."
}
```

## 7.2 Get MCQ Questions

Endpoint:

```http
GET /api/mcq/questions/
```

Authentication:

```text
Candidate only
```

Headers:

```http
Authorization: Bearer <candidate_token>
```

Example response:

```json
{
  "success": true,
  "questions": [
    {
      "id": 1,
      "question": "Which language is used in Django?",
      "options": ["Java", "Python", "C++", "PHP"]
    }
  ],
  "duration_seconds": 1200
}
```

Important:

Answers are not sent in this response.

## 7.3 Submit MCQ Answers

Endpoint:

```http
POST /api/mcq/submit/
```

Authentication:

```text
Candidate only
```

Headers:

```http
Authorization: Bearer <candidate_token>
Content-Type: application/json
```

Request body:

```json
{
  "answers": {
    "1": "Python",
    "2": "git commit",
    "3": "PostgreSQL"
  },
  "time_taken": 300
}
```

Example response:

```json
{
  "success": true,
  "score": 18,
  "total": 20,
  "percentage": 90.0,
  "passed": true,
  "time_taken": "5m 0s",
  "results": [
    {
      "qid": "1",
      "correct": "Python",
      "user": "Python",
      "is_correct": true
    }
  ]
}
```

The backend saves:

```text
application.mcq_score = percentage
```

# 8. Final Hiring API

## 8.1 HR Mark Candidate as Hired

Endpoint:

```http
PATCH /api/register/hr/applications/<app_id>/hire/
```

Authentication:

```text
HR only
```

Headers:

```http
Authorization: Bearer <hr_token>
```

Condition:

```text
Candidate MCQ score must be 60 or above.
```

Example response:

```json
{
  "success": true,
  "application": {
    "id": 10,
    "status": "hired",
    "mcq_score": 90.0,
    "mcq_passed": true
  }
}
```

If MCQ is not passed:

```json
{
  "success": false,
  "message": "Candidate has not passed MCQ."
}
```

# Flutter Implementation Notes

## Suggested Screens

Candidate side:

```text
Login
Register
Profile + CV Upload
Job List
Job Details
My Applications
MCQ Test
Result
```

HR side:

```text
HR Login
Application List
Application Detail
Approve / Reject
MCQ Result View
Mark Hired
```

## Suggested Flutter Models

```text
UserModel
JobModel
ApplicationModel
McqQuestionModel
McqResultModel
```

## Suggested API Service Methods

```dart
Future<LoginResponse> login(String email, String password)
Future<UserModel> getProfile()
Future<UserModel> updateProfile(...)
Future<UserModel> uploadCv(File cv)
Future<List<JobModel>> getJobs()
Future<List<JobModel>> getSkillMatchedJobs()
Future<JobModel> getJobDetail(int jobId)
Future<ApplicationModel> applyJob(int jobId)
Future<List<ApplicationModel>> getMyApplications()
Future<List<ApplicationModel>> getHrApplications({String? status})
Future<ApplicationModel> updateApplicationStatus(int appId, String status)
Future<void> startMcq(int jobId, int userId)
Future<List<McqQuestionModel>> getMcqQuestions()
Future<McqResultModel> submitMcq(Map<String, String> answers, int timeTaken)
Future<ApplicationModel> markHired(int appId)
```

# APIs Excluded From Flutter Workflow

Do not use these for the requested app flow:

```text
/api/mtest/
/api/interview/
/ai_interview/
```

Machine test, HR interview, video interview, and AI interview modules are not required for this Flutter workflow.

# Backend Files Related To These APIs

```text
register/api.py
register/api_urls.py
register/models.py
mcq_exam/api.py
mcq_exam/api_urls.py
jr_system/urls.py
API_WORKFLOW.md
```

# Important Backend Notes

- CV files are stored in local `media/`.
- Skills are extracted from uploaded CV using existing backend logic.
- Token auth uses `AutoLoginToken`.
- Passwords currently use existing `user_pass` field. For production, use Django password hashing.
- Run migrations after pulling this change:

```powershell
.venv\Scripts\python.exe manage.py migrate
```
<!-- You are a senior Flutter developer and UI/UX architect.

Build a production-level Candidate Dashboard module for a job portal application using Flutter.

Requirements:

1. Candidate Login
- After successful candidate login, navigate to the Candidate Dashboard page.
- Use clean architecture and professional UI design.
- Responsive design for mobile and tablet.

2. Dashboard Features

A. CV Upload Section
- Show a prominent “Upload CV / Resume” card at the top.
- Allow candidate to upload:
  - PDF
  - DOC
  - DOCX
- Store uploaded CV locally or through API integration.
- Show upload progress indicator.
- After successful upload:
  - Display uploaded CV file name
  - Display upload success message
  - Allow preview/open uploaded CV
  - Allow replace/update CV

B. AI Skill Extraction
- AI skill extraction should happen ONLY after CV upload.
- Extract skills automatically from uploaded CV using AI/NLP.
- Display extracted skills in modern skill chips/tags UI.
- Example:
  Flutter, Dart, Firebase, REST API, Python, UI/UX

- Show:
  - Loading animation while extracting skills
  - Empty state before CV upload
  - Error handling if extraction fails

C. Skill-Based Job Recommendations
- After skills are extracted, automatically fetch and display matching jobs based on extracted skills.
- Jobs should appear like a real-world job portal.

Each job card should contain:
- Job title
- Company name
- Location
- Salary/Stipend
- Experience required
- Skills required
- Posted date
- Apply button

D. Apply Job Feature
- Candidate should be able to apply directly from dashboard.
- On clicking Apply:
  - Show confirmation dialog
  - Submit application through API
  - Show success snackbar/message
  - Change button state to “Applied”

E. Real-World UX Features
- Pull to refresh
- Skeleton loading
- Pagination or lazy loading
- Search jobs
- Filter by skills/location
- Save jobs feature
- Recently applied jobs section

3. Technical Requirements
- Flutter latest version
- MVVM architecture
- Provider or GetX state management
- REST API integration
- Clean folder structure
- Repository pattern
- Proper model classes
- Error handling
- Loading states
- Reusable widgets
- Null safety
- Responsive UI

4. UI Design
- Modern job portal style UI
- Minimal and professional
- Gradient cards
- Rounded containers
- Smooth animations
- Dark/light mode support

5. Dashboard Flow
Login → Dashboard → Upload CV → AI Skill Extraction → Display Skills → Recommended Jobs → Apply Job

6. Additional Expectations
- Write scalable production-ready code
- Include comments where necessary
- Follow best Flutter practices
- Use dummy API/mock data if backend is unavailable
- Create realistic sample extracted skills and job data

Generate:
- Complete Flutter UI
- Models
- ViewModels/Controllers
- Services
- Repository layer
- API integration structure
- Reusable widgets
- Full folder structure. inghaneyaan enik flutter appil vendath . athukond ee backendil ndhenkilum mmattam undo?  undenkil fix cheyu 


itheelenne ee projectil thanne ith base cheithit enik flutter app create cheitholu. nereteh paranjhapole
-->