# JR System — Job Recruitment Platform

A full-stack web application for managing the end-to-end recruitment process — from job posting and candidate applications to automated assessments, real-time video interviews, and AI-powered interview analysis.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Installation & Setup](#installation--setup)
- [Environment Variables](#environment-variables)
- [Groq API Setup](#groq-api-setup)
- [Database Setup](#database-setup)
- [Running the Server](#running-the-server)
- [User Roles](#user-roles)
- [Recruitment Pipeline](#recruitment-pipeline)
- [Apps Overview](#apps-overview)
- [API Endpoints](#api-endpoints)
- [Known Issues & TODOs](#known-issues--todos)

---

## Overview

JR System is a Django-based recruitment management platform designed for companies to streamline their hiring pipeline. It supports three user roles — Admin, HR, and Candidate — and automates each stage of recruitment from application to final interview result.

---

## Features

- **Multi-role authentication** — Admin, HR, and Candidate dashboards with session-based login and Google OAuth (via django-allauth)
- **Job posting & management** — HR users can create, edit, and manage job listings with skills, deadlines, and status controls
- **Smart resume matching** — Candidate applications are scored against job skill requirements
- **Automated MCQ exam** — 20-minute timed screening test (59 questions, randomly selected) auto-graded on submission
- **Machine coding test** — Multi-language code submission (Python, C, C++, Java, JavaScript) with verdict tracking (Accepted, Wrong Answer, Runtime Error, TLE, etc.)
- **Real-time video interview** — WebSocket-powered interview rooms using Django Channels and Daphne (ASGI), with recording support
- **AI interview analysis** — Post-interview audio transcription via faster-whisper (local, offline) and analysis via Groq (LLaMA 3.3 70B), producing scores for communication, technical skill, confidence, and a hiring recommendation
- **Notification system** — In-app notifications for candidates on application status changes
- **Admin dashboard** — Full platform oversight including company, job, and user management
- **Meta/Facebook integration** — Optional hooks to connect company pages for job sharing

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django 5.2 |
| Database | PostgreSQL |
| Real-time | Django Channels + Daphne (ASGI) |
| Auth | Session auth + django-allauth (Google OAuth) |
| REST API | Django REST Framework |
| AI Transcription | faster-whisper (local, CPU, int8) |
| AI Analysis | Groq API (LLaMA 3.3 70B) |
| Email | SMTP via Gmail |
| Frontend | Django templates + vanilla JS + Bootstrap |

---

## Project Structure

```
JR_SYSTEM/
├── jr_system/          # Project config (settings, URLs, ASGI/WSGI)
├── register/           # Core app — users, jobs, applications, HR & admin views
├── mcq_exam/           # MCQ screening test module
├── m_test/             # Machine/coding test module
├── interview/          # Real-time video interview + AI analysis
├── templates/          # All HTML templates
│   ├── interview/      # Interview room, lobby, ended screens
│   └── m_test/         # Coding test UI
├── static/             # CSS and JS assets
├── media/              # Uploaded files (CVs, profile images, recordings)
└── manage.py
```

---

## Installation & Setup

### Prerequisites

- Python 3.10+
- PostgreSQL
- Redis *(optional — currently uses in-memory channel layer)*

### 1. Clone the repository

```bash
git clone https://github.com/Bhagathsurendran/JR_SYSTEM.git
cd JR_SYSTEM
```

### 2. Create a virtual environment

```bash
python -m venv venv
source venv/bin/activate        # Linux/macOS
venv\Scripts\activate           # Windows
```

### 3. Install dependencies

```bash
pip install django djangorestframework channels daphne django-allauth \
            python-dotenv faster-whisper groq psycopg2-binary pillow
```

> **Note:** `faster-whisper` requires `ffmpeg` to be installed on your system.
> Install via: `sudo apt install ffmpeg` (Linux) or `brew install ffmpeg` (macOS)

---

## Environment Variables

Create a `.env` file in the project root:

```env
SECRET_KEY=your-django-secret-key

# Database
DB_ENGINE=postgresql
DB_NAME=jr_system
DB_USER=postgres
DB_PASSWORD=your_db_password
DB_HOST=localhost
DB_PORT=5432

# Email (Gmail SMTP)
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_app_password

# AI Analysis
GROQ_API_KEY=your_groq_api_key

# Google OAuth (from Google Cloud Console)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

> **Security Warning:** The repository currently contains hardcoded credentials in `settings.py`. These must be replaced with environment variables before any production deployment.

---

## Groq API Setup

The AI interview analysis feature uses the [Groq API](https://console.groq.com) to run LLaMA 3.3 70B on the interview transcript. Groq offers a **free tier** with generous rate limits, making it suitable for development and small-scale production use.

### 1. Create a Groq account

Go to [https://console.groq.com](https://console.groq.com) and sign up for a free account.

### 2. Generate an API key

- After logging in, navigate to **API Keys** in the left sidebar
- Click **Create API Key**
- Give it a name (e.g. `jr-system`) and copy the key — it won't be shown again

### 3. Add the key to your `.env` file

```env
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 4. Verify the key is loaded

The key is read in `interview/ai_analysis.py` via:

```python
from dotenv import load_dotenv
load_dotenv()
groq_client = Groq(api_key=os.getenv('GROQ_API_KEY'))
```

Make sure `python-dotenv` is installed and your `.env` file is in the project root (same directory as `manage.py`).

### 5. Model used

The project uses `llama-3.3-70b-versatile`. This model is available on Groq's free tier. If you need to switch models, update the `model` parameter in `interview/ai_analysis.py`:

```python
response = groq_client.chat.completions.create(
    model='llama-3.3-70b-versatile',   # change this if needed
    ...
)
```

Other available Groq models include `llama3-8b-8192`, `llama3-70b-8192`, and `mixtral-8x7b-32768`. See the full list at [https://console.groq.com/docs/models](https://console.groq.com/docs/models).

### 6. Free tier limits

| Limit | Value |
|---|---|
| Requests per minute | 30 |
| Tokens per minute | 14,400 |
| Tokens per day | 14,400 |

For higher throughput, upgrade to a paid Groq plan at [https://console.groq.com/settings/billing](https://console.groq.com/settings/billing).

### Troubleshooting

- **`AuthenticationError`** — The API key is missing or incorrect. Double-check your `.env` file and ensure `load_dotenv()` is called before the `Groq()` client is initialised.
- **`RateLimitError`** — You've hit the free tier limit. Wait a minute and retry, or upgrade your plan.
- **Analysis not running** — Check the Django console for `[AI]` prefixed log lines. The analysis runs in a background thread after audio is uploaded; errors are printed there, not surfaced to the UI.
- **Empty or garbled transcript** — This is a `faster-whisper` issue, not Groq. Ensure `ffmpeg` is installed and the uploaded audio file is a valid `.webm`.

---

## Database Setup

For an existing MySQL installation, first follow [MYSQL_TO_POSTGRESQL_MIGRATION.md](MYSQL_TO_POSTGRESQL_MIGRATION.md) to back up and export the current data before switching `.env` to PostgreSQL.

### 1. Create the PostgreSQL database

```sql
CREATE DATABASE jr_system;
```

### 2. Apply migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### 3. Create a superuser

```bash
python manage.py createsuperuser
```

### 4. Set up the Django site object (required for allauth)

In the Django admin (`/admin/`), navigate to **Sites** and update the default site's domain and display name to match your local or production URL.

---

## Running the Server

Since the project uses Django Channels (WebSockets), run with Daphne instead of `runserver`:

```bash
daphne jr_system.asgi:application
```

Or for development with auto-reload:

```bash
python manage.py runserver
```

> WebSocket features (live interview rooms) require Daphne or another ASGI server. `runserver` supports basic WebSocket for local development via Django Channels.

Access the app at: `http://localhost:8000`

---

## User Roles

| Role | Description |
|---|---|
| **Admin** | Full platform control — manage companies, users, jobs, and view all data |
| **HR** | Manage job postings for their company, review applications, schedule and conduct interviews |
| **Candidate (User)** | Register, apply for jobs, take assessments, and attend video interviews |

---

## Recruitment Pipeline

The platform guides candidates through a structured hiring funnel:

```
Register → Apply for Job → Resume Scored → MCQ Exam →
Machine Coding Test → HR Video Interview → AI Analysis → Final Result
```

1. **Apply** — Candidate applies; their CV skills are matched against job requirements to produce a match score
2. **MCQ Exam** — 20-minute timed test with 15 randomly selected questions from a pool of 59
3. **Machine Test** — Coding problem submission with multi-language support and automated verdict
4. **HR Interview** — Live WebSocket video call between HR and candidate; HR records the session
5. **AI Analysis** — Recording is transcribed offline (faster-whisper) then analyzed by LLaMA 3.3 via Groq, producing scores and a hiring recommendation saved to the database
6. **Decision** — HR marks the interview result (Passed / Failed) with optional feedback; candidate is notified

---

## Apps Overview

### `register`

The core app. Handles:
- User and HR registration/login
- Job CRUD (create, read, update, delete) for HR users
- Application management and status tracking
- Admin, HR, and user dashboards
- In-app notification system
- Company management (add, edit, delete, Meta/Facebook connection)
- Calendar view for scheduled interviews

**Key models:** `user_detail`, `Employee`, `Job`, `application`, `Notification`

### `mcq_exam`

- Delivers a randomized 15-question subset from a 59-question bank
- 20-minute countdown timer enforced server-side
- Auto-grades on submission and stores `mcq_score` on the application record

### `m_test`

- Presents a coding problem with multi-language editor
- Submits code and returns a verdict: Accepted, Wrong Answer, Runtime Error, Compile Error, or Time Limit Exceeded
- Tracks pass/fail per test case and stores `machine_test_score`

**Key model:** `Submission`

### `interview`

- WebSocket-based video interview rooms (one unique room per application via UUID)
- Lobby page for pre-join, room page for the live session, ended page post-interview
- HR can save live notes during the interview
- On interview end, HR submits result + feedback and uploads the audio recording
- Background thread runs AI analysis (transcription → LLM scoring) without blocking the response

**AI pipeline:**
1. `faster-whisper` (local, CPU, `base` model, int8) transcribes the `.webm` audio
2. Groq API (`llama-3.3-70b-versatile`) analyzes the transcript and returns a structured JSON report:
   - Overall score (1–10)
   - Communication, technical, and confidence scores
   - Strengths and weaknesses
   - Key quotes
   - Hiring recommendation (`strongly_recommended` / `recommended` / `neutral` / `not_recommended`)
   - Hiring notes for the manager

---

## API Endpoints

| Method | URL | Description |
|---|---|---|
| GET | `/` | Login page |
| GET/POST | `/reg/` | Candidate registration |
| POST | `/login_user/` | Login |
| GET | `/logout/` | Logout |
| GET | `/user_dashboard/` | Candidate dashboard |
| GET | `/hr_dashboard/` | HR dashboard |
| GET | `/admin_dashboard/` | Admin dashboard |
| POST | `/toggle-apply/` | Apply / withdraw job application |
| GET | `/view_applications/<job_id>/` | List applications for a job |
| POST | `/update_application_status/` | Approve / reject an application |
| GET | `/hr/api/calendar/` | Calendar data for scheduled interviews |
| GET | `/get_ranklist/` | Candidate ranking by scores |
| GET | `/mcq_exam/<job_id>/<user_id>/` | Start MCQ exam |
| GET | `/m_test/<job_id>/<user_id>/` | Start machine test |
| GET | `/interview/lobby/<room_id>/` | Interview lobby |
| GET | `/interview/room/<room_id>/` | Live interview room |
| POST | `/interview/end/<room_id>/` | End interview and submit result |
| POST | `/interview/save-audio/<room_id>/` | Upload recording for AI analysis |
| GET | `/accounts/google/login/` | Google OAuth login |

---

## Known Issues & TODOs

- **Hardcoded credentials** — `SECRET_KEY`, database password, and email credentials are currently in `settings.py`. Move all secrets to `.env` before deploying.
- **`DEBUG = True` and `ALLOWED_HOSTS = ['*']`** — Not safe for production. Set `DEBUG = False` and restrict `ALLOWED_HOSTS` to your domain.
- **In-memory channel layer** — The current `InMemoryChannelLayer` does not support multi-process deployments. Switch to `channels_redis` backed by a Redis instance for production.
- **Media file duplication** — The `media/` directory contains many duplicate files. A deduplication strategy or cloud storage (e.g. AWS S3) is recommended.
- **MCQ question bank** — Questions are hardcoded in `mcq_exam/views.py`. Consider moving them to the database for easier management and per-job customisation.
- **No `requirements.txt`** — A `requirements.txt` or `pyproject.toml` should be added for reproducible installs.
- **CSRF trusted origins** — `CSRF_TRUSTED_ORIGINS` is set to `*.ngrok-free.app` for ngrok tunnelling. Update this for production.

---

## License

This project does not currently include a license file. All rights reserved by the author unless otherwise stated.
