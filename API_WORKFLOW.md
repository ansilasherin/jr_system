# Job Recruitment API Workflow
```bash
python manage.py runserver 0.0.0.0:8000
```

Base URLs:
- Core workflow APIs: `/api/register/`
- MCQ APIs: `/api/mcq/`

Secured routes use:
- `Authorization: Bearer <token>`
- `Content-Type: application/json` for JSON requests
- `Content-Type: multipart/form-data` for CV/profile uploads

The token is returned by login and stored in `register.models.AutoLoginToken`.

## 1. Authentication

### Candidate Registration
- Endpoint: `/api/register/auth/register/candidate/`
- Method: `POST`
- Auth: Public
- Content-Type: `multipart/form-data`
- Request:
  - `full_name`, `email`, `phone`, `course`, `password`
  - Optional files: `cv`/`resume`, `photo`/`profile`
- Response:
```json
n
```
- Related code: `register.api.api_register_candidate`, `user_detail`, `extract_skills_from_cv`

### HR Registration
- Endpoint: `/api/register/auth/register/hr/`
- Method: `POST`
- Auth: Public
- Request:
```json
{
  "full_name": "HR Name",
  "email": "hr@example.com",
  "phone": "9999999999",
  "department": "Recruitment",
  "password": "password123"
}
```
- Response: user object with `"role": "hr"`
- Related code: `register.api.api_register_hr`, `user_detail`

### Login
- Endpoint: `/api/register/auth/login/`
- Method: `POST`
- Auth: Public
- Request:
```json
{"email": "candidate@example.com", "password": "password123"}
```
- Response:
```json
{"success": true, "token": "token-value", "token_type": "Bearer", "user": {}}
```
- Related code: `register.api.api_login`, `AutoLoginToken`

### Logout
- Endpoint: `/api/register/auth/logout/`
- Method: `POST`
- Auth: Candidate/HR
- Headers: `Authorization: Bearer <token>`
- Response:
```json
{"success": true, "message": "Logged out."}
```

## 2. Candidate Profile and CV Upload

### View Profile
- Endpoint: `/api/register/candidate/profile/`
- Method: `GET`
- Auth: Candidate/HR
- Response: current user profile
- Related code: `register.api.api_profile`

### Update Profile / Upload CV
- Endpoint: `/api/register/candidate/profile/`
- Method: `POST`, `PUT`, or `PATCH`
- Auth: Candidate/HR
- Content-Type: `multipart/form-data`
- Request:
  - `full_name`, `email`, `phone`, `course`
  - Optional files: `cv`/`resume`, `photo`/`profile`
- Response: updated user profile with `cv_url` and extracted `skills`
- Related code: `register.api.api_profile`, `FileSystemStorage`, `extract_skills_from_cv`

## 3. Skill Extraction from CV

### Extract Skills
- Endpoint: `/api/register/candidate/skills/extract/`
- Method: `POST`
- Auth: Candidate
- Content-Type: `multipart/form-data`
- Request: `cv` or `resume`
- Allowed files: `.pdf`, `.doc`, `.docx`, up to 5 MB
- Response:
```json
{"success": true, "skills": ["Python", "Django"], "cv_url": "/media/resume.pdf"}
```
- Related code: `register.api.api_extract_skills`, `register.views.extract_skills_from_cv`
- AI/NLP runs only on the Django backend. Do not put AI keys in Flutter.
- Optional backend env:
```env
CV_SKILL_AI_PROVIDER=auto
OPENAI_API_KEY=your_openai_key
GROQ_API_KEY=your_groq_key
```
- If no AI key is configured, the backend falls back to local keyword-based skill extraction.

## 4. HR Company

### Create Company
- Endpoint: `/api/register/hr/companies/`
- Method: `POST`
- Auth: HR
- Single-company request:
```json
{
  "company_name": "Nucore Software Solutions",
  "email": "hr@nucore.com",
  "website": "https://www.nucore.in/",
  "location": "Calicut"
}
```
- Multi-company request:
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
- A raw JSON list is also accepted:
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
- Response:
```json
{
  "success": true,
  "company": {
    "id": 1,
    "company_name": "Nucore Software Solutions",
    "email": "hr@nucore.com",
    "website": "https://www.nucore.in/",
    "location": "Calicut"
  }
}
```
- Use the returned `company.id` as `company_id` when creating a job.
- Multi-company responses return `companies`, each with an `id`.
- Related code: `register.api.api_hr_companies`, `Employee`

### List Companies
- Endpoint: `/api/register/hr/companies/`
- Method: `GET`
- Auth: HR
- Response: company list with IDs for job creation
- Related code: `register.api.api_hr_companies`, `Employee`

## 5. Job Vacancy

### List Jobs
- Endpoint: `/api/register/jobs/`
- Method: `GET`
- Auth: Public, token optional
- Query:
  - `q=python`
  - `location=Kochi`
  - `skills=Flutter,Dart`
  - `page=1&page_size=10`
  - `skill_match=1` requires candidate token and sorts by extracted-skill match
- Response:
```json
{"success": true, "jobs": [{"id": 1, "job_title": "Django Developer", "match_score": 75}], "pagination": {}}
```
- Related code: `register.api.api_job_list`, `Job`

### Candidate Dashboard
- Endpoint: `/api/register/candidate/dashboard/`
- Method: `GET`
- Auth: Candidate
- Response includes `profile`, `recommended_jobs`, `recent_applications`, and `saved_jobs`.

### Save Job
- Endpoint: `/api/register/jobs/<job_id>/save/`
- Method: `POST` to save, `DELETE` to remove
- Auth: Candidate

### Saved Jobs
- Endpoint: `/api/register/candidate/saved-jobs/`
- Method: `GET`
- Auth: Candidate

### Job Details
- Endpoint: `/api/register/jobs/<job_id>/`
- Method: `GET`
- Auth: Public, token optional
- Response: single job object
- Related code: `register.api.api_job_detail`

### HR Create Job
- Endpoint: `/api/register/hr/jobs/`
- Method: `POST`
- Auth: HR
- Single-job request:
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
- Multi-job request:
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
- A raw JSON list is also accepted:
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
- `skills` can be a comma-separated string or a JSON list:
```json
"skills": ["Python", "Django", "SQL"]
```
- Response: created job object
- Multi-job responses return `jobs`.
- Related code: `register.api.api_create_job`, `Job`

## 6. Job Application

### Apply for Job
- Endpoint: `/api/register/applications/apply/`
- Method: `POST`
- Auth: Candidate
- Request:
```json
{"job_id": 1}
```
- Response:
```json
{
  "success": true,
  "application": {
    "id": 10,
    "match_score": 80,
    "status": "applied",
    "mcq_score": null
  }
}
```
- Related code: `register.api.api_apply_job`, `application`

### My Applications
- Endpoint: `/api/register/applications/`
- Method: `GET`
- Auth: Candidate
- Response: candidate applications with status
- Related code: `register.api.api_my_applications`

## 7. HR Review and Approval

### View Applications
- Endpoint: `/api/register/hr/applications/`
- Method: `GET`
- Auth: HR
- Query: optional `status=applied|under_review|approved|rejected|hired`
- Response: applications for jobs owned by the HR user
- Related code: `register.api.api_hr_applications`

### Approve / Reject / Mark Under Review
- Endpoint: `/api/register/hr/applications/<app_id>/status/`
<!-- http://127.0.0.1:8000/api/register/hr/applications/4/status/ -->
- Method: `PATCH` or `POST`
- Auth: HR
- Request:
```json
{"status": "approved"}
```
- Allowed status values: `under_review`, `approved`, `rejected`
- Response: updated application
- Related code: `register.api.api_update_application_status`

## 8. MCQ Test Only

### Start MCQ
- Endpoint: `/api/mcq/start/<job_id>/<user_id>/`
<!-- http://127.0.0.1:8000/api/mcq/start/17/3/ , usertocken rqrd-->
- Method: `GET`
- Auth: Approved Candidate
- Response:
```json
{"success": true, "title": "Internship Screening Test", "duration_seconds": 1200}
```
- Related code: `mcq_exam.api.api_start_exam`

### Fetch Questions
- Endpoint: `/api/mcq/questions/`
- Method: `GET`
- Auth: Candidate
- Response: randomized MCQ questions without answers
- Related code: `mcq_exam.api.api_exam_questions`

### Submit Answers
- Endpoint: `/api/mcq/submit/`
- Method: `POST`
- Auth: Candidate
- Request:
```json
{"answers": {"1": "Python", "2": "git commit"}, "time_taken": 300}
```
- Response:
```json
{"success": true, "score": 18, "total": 20, "percentage": 90.0, "passed": true}
```
- Related code: `mcq_exam.api.api_submit_exam`, stores `application.mcq_score`

## 9. Final Hiring

### Mark Candidate Hired
- Endpoint: `/api/register/hr/applications/<app_id>/hire/`
<!-- http://127.0.0.1:8000/api/register/hr/applications/17/hire/ -->
- Method: `PATCH` or `POST` (empty body)
- Auth: HR
- Rule: `mcq_score` must be at least `60`
- Response: updated application with `"status": "hired"`
- Related code: `register.api.api_mark_hired`

## Already Available / Reused

- `user_detail`, `Job`, `application`, `Employee`, `AutoLoginToken`
- CV upload storage using `FileSystemStorage`
- Skill extraction using `register.views.extract_skills_from_cv`
- Skill-match scoring from existing application logic
- MCQ question bank and scoring from `mcq_exam`

## Excluded APIs

- Machine test API: `/api/mtest/`
- Interview API: `/api/interview/`
- AI interview API

These were removed from project-level API routing in `jr_system/urls.py`. The original apps and web routes still exist.

## Missing / Notes

- There are no DRF serializers in the current project for these models; the API uses reusable payload helpers in `register/api.py`.
- Passwords are still stored in the existing plain-text `user_pass` field. This follows the current codebase but should be replaced with Django password hashing before production.
- CV storage is local `media/` storage. For production, move to private/cloud storage.
