import json
import string
from datetime import date, timedelta

from django.core.files.storage import FileSystemStorage
from django.core.mail import send_mail
from django.conf import settings
from django.core.paginator import EmptyPage, Paginator
from django.db.models import Q
from django.http import JsonResponse
from django.utils import timezone
from django.utils.crypto import get_random_string
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .department_utils import (
    department_filter_q,
    filter_open_jobs_by_department,
    resolve_department,
    sort_jobs_for_candidate,
)
from .models import AutoLoginToken, Employee, Job, Notification, SavedJob, application, user_detail
from .cv_skills import extract_skills_from_cv


CANDIDATE_ROLE = "user"
HR_ROLE = "hr"
PASS_MARK = 60
ALLOWED_CV_EXTENSIONS = {".pdf", ".doc", ".docx"}
MAX_CV_SIZE = 5 * 1024 * 1024


def _json_body(request):
    if not request.body:
        return {}
    try:
        return json.loads(request.body)
    except json.JSONDecodeError:
        return None


def _token_from_request(request):
    header = request.headers.get("Authorization", "")
    if header.lower().startswith("bearer "):
        return header.split(" ", 1)[1].strip()
    if header.lower().startswith("token "):
        return header.split(" ", 1)[1].strip()
    return None


def _create_token(user):
    token = get_random_string(64)
    AutoLoginToken.objects.create(
        user=user,
        token=token,
        expires_at=timezone.now() + timedelta(days=30),
    )
    return token


def _api_user(request):
    token = _token_from_request(request)
    if not token:
        return None
    token_obj = AutoLoginToken.objects.select_related("user").filter(token=token).first()
    if not token_obj:
        return None
    if not token_obj.is_valid():
        token_obj.delete()
        return None
    return token_obj.user


def _require_user(request, roles=None):
    user = _api_user(request)
    if not user:
        return None, JsonResponse({"success": False, "message": "Authentication required."}, status=401)
    if roles and user.role not in roles:
        return None, JsonResponse({"success": False, "message": "Permission denied."}, status=403)
    return user, None


def _candidate_payload(user):
    return {
        "id": user.id,
        "full_name": user.full_name,
        "email": user.Email,
        "phone": user.phoneno,
        "course": user.course,
        "role": user.role,
        "cv_url": user.cv_url,
        "cv_name": user.cv_name or "",
        "profile_url": user.profile_url,
        "skills": [s.strip() for s in user.skills.split(",") if s.strip()] if user.skills else [],
        "registered_at": user.reg_date.isoformat() if user.reg_date else None,
    }


def _skills_to_text(skills):
    if isinstance(skills, list):
        return ", ".join(str(skill).strip() for skill in skills if str(skill).strip())
    return skills or ""


def _skill_list(skills):
    skills_text = _skills_to_text(skills)
    return [s.strip() for s in skills_text.split(",") if s.strip()] if skills_text else []


def _validate_cv_file(file_obj):
    if not file_obj:
        return "CV file is required."
    name = (getattr(file_obj, "name", "") or "").lower()
    if not any(name.endswith(ext) for ext in ALLOWED_CV_EXTENSIONS):
        return "Only PDF, DOC, and DOCX resumes are allowed."
    if getattr(file_obj, "size", 0) and file_obj.size > MAX_CV_SIZE:
        return "CV file must be 5 MB or smaller."
    return None


def _pagination_meta(page_obj, paginator):
    return {
        "page": page_obj.number,
        "page_size": page_obj.paginator.per_page,
        "total": paginator.count,
        "total_pages": paginator.num_pages,
        "has_next": page_obj.has_next(),
        "has_previous": page_obj.has_previous(),
    }


def _empty_jobs_response(page, page_size):
    return JsonResponse({
        "success": True,
        "jobs": [],
        "pagination": {
            "page": page,
            "page_size": page_size,
            "total": 0,
            "total_pages": 0,
            "has_next": False,
            "has_previous": False,
        },
    })


def _job_payload(job, candidate=None):
    skills_text = _skills_to_text(job.skills)
    job_skills = _skill_list(skills_text)
    deadline = job.deadline
    payload = {
        "id": job.id,
        "job_title": job.job_title,
        "company": job.company_id.company_name if job.company_id else None,
        "company_id": job.company_id_id,
        "hr_id": job.hr_id_id,
        "location": job.location,
        "department": job.department or "",
        "duration": job.duration,
        "stipend": job.stipend,
        "salary_stipend": job.stipend,
        "experience_required": job.duration,
        "deadline": deadline.isoformat() if hasattr(deadline, "isoformat") else deadline,
        "skills": job_skills,
        "skills_required": job_skills,
        "description": job.description,
        "status": job.status,
        "posted_date": job.created_at.isoformat() if job.created_at else None,
        "created_at": job.created_at.isoformat() if job.created_at else None,
    }
    if candidate:
        payload["match_score"] = _match_score(candidate.skills, skills_text)
        payload["applied"] = application.objects.filter(user_id=candidate, job_id=job).exists()
        payload["saved"] = SavedJob.objects.filter(user=candidate, job=job).exists()
    else:
        payload["applied"] = False
        payload["saved"] = False
    return payload


def _company_payload(company):
    return {
        "id": company.id,
        "company_name": company.company_name,
        "email": company.email,
        "website": company.website,
        "location": company.location,
        "created_at": company.created_at.isoformat() if company.created_at else None,
    }


def _application_status_message(status, can_take_mcq):
    if can_take_mcq:
        return "HR approved your application. You can take the MCQ test now."
    if status == "applied":
        return "Application submitted. Waiting for HR review."
    if status == "under_review":
        return "HR is reviewing your application and CV."
    if status == "approved":
        return "HR approved your application."
    if status == "mcq_completed":
        return "MCQ completed. HR will evaluate your result before the final hiring decision."
    if status == "rejected":
        return "Application was rejected after HR evaluation."
    if status == "hired":
        return "You have been selected after HR evaluated your MCQ result."
    return "Application status updated."


def _application_payload(app):
    job = app.job_id
    candidate = app.user_id
    skills_text = _skills_to_text(job.skills)
    can_take_mcq = app.status == "approved" and app.mcq_score is None
    return {
        "id": app.id,
        "job_id": job.id,
        "job_title": job.job_title,
        "company": job.company_id.company_name if job.company_id else None,
        "job_location": job.location,
        "job_department": job.department or "",
        "job_duration": job.duration,
        "job_stipend": job.stipend,
        "job_description": job.description,
        "job_deadline": job.deadline.isoformat() if job.deadline else None,
        "candidate_name": candidate.full_name,
        "candidate_email": candidate.Email,
        "candidate_phone": candidate.phoneno,
        "candidate_course": candidate.course,
        "candidate_cv_url": candidate.cv_url,
        "candidate_cv_name": candidate.cv_name or "",
        "candidate_skills": [s.strip() for s in candidate.skills.split(",") if s.strip()] if candidate.skills else [],
        "candidate": _candidate_payload(candidate),
        "job": _job_payload(job),
        "match_score": app.match_score,
        "status": app.status,
        "can_take_mcq": can_take_mcq,
        "status_message": _application_status_message(app.status, can_take_mcq),
        "skills": [skill.strip() for skill in skills_text.split(",") if skill.strip()] if skills_text else [],
        "applied_at": app.applied_at.isoformat() if app.applied_at else None,
        "mcq_score": app.mcq_score,
        "mcq_passed": app.mcq_score is not None and app.mcq_score >= PASS_MARK,
        "interview_room_id": str(app.interview_room_id) if app.interview_room_id else None,
        "interview_result": app.interview_result,
        "interview_feedback": app.interview_feedback,
        "interview_transcript": app.interview_transcript,
        "interview_analysis": app.interview_analysis,
        "interview_recording_url": app.interview_recording.url if app.interview_recording else None,
    }


def _saved_job_payload(saved_job, candidate):
    payload = _job_payload(saved_job.job, candidate)
    payload["saved_at"] = saved_job.saved_at.isoformat() if saved_job.saved_at else None
    return payload


def _match_score(candidate_skills, job_skills):
    user_skills = [s.strip().lower() for s in candidate_skills.split(",")] if candidate_skills else []
    job_skills_text = _skills_to_text(job_skills)
    required_skills = [s.strip().lower() for s in job_skills_text.split(",")] if job_skills_text else []
    if not required_skills:
        return 0
    common = set(user_skills) & set(required_skills)
    return int((len(common) / len(required_skills)) * 100)


def _skill_overlap_score(candidate_skills, job_skills):
    user_skills = set(s.strip().lower() for s in _skill_list(candidate_skills))
    required_skills = set(s.strip().lower() for s in _skill_list(job_skills))
    if not user_skills or not required_skills:
        return 0
    common = user_skills & required_skills
    return int((len(common) / len(required_skills)) * 100)


@csrf_exempt
@require_http_methods(["POST"])
def api_register_candidate(request):
    name = request.POST.get("full_name") or request.POST.get("name")
    email = request.POST.get("email") or request.POST.get("Email")
    phone = request.POST.get("phone") or request.POST.get("phoneno")
    course = request.POST.get("course", "")
    password = request.POST.get("password") or get_random_string(10, string.ascii_letters + string.digits)

    if not name or not email:
        return JsonResponse({"success": False, "message": "full_name and email are required."}, status=400)
    if user_detail.objects.filter(Email=email).exists():
        return JsonResponse({"success": False, "message": "Email already registered."}, status=409)

    fs = FileSystemStorage()
    cv_url = ""
    cv_name = ""
    profile_url = ""
    skills = ""

    cv = request.FILES.get("cv") or request.FILES.get("resume")
    if cv:
        cv_error = _validate_cv_file(cv)
        if cv_error:
            return JsonResponse({"success": False, "message": cv_error}, status=400)
        skills = extract_skills_from_cv(cv)
        cv.seek(0)
        cv_name = cv.name
        cv_url = fs.url(fs.save(fs.get_available_name(cv.name), cv))

    profile = request.FILES.get("photo") or request.FILES.get("profile")
    if profile:
        profile_url = fs.url(fs.save(fs.get_available_name(profile.name), profile))

    user = user_detail.objects.create(
        full_name=name,
        Email=email,
        phoneno=phone or "",
        course=resolve_department(course) or course,
        cv_url=cv_url,
        cv_name=cv_name,
        profile_url=profile_url,
        user_pass=password,
        role=CANDIDATE_ROLE,
        skills=skills,
    )
    return JsonResponse({"success": True, "user": _candidate_payload(user)}, status=201)


@csrf_exempt
@require_http_methods(["POST"])
def api_register_hr(request):
    data = _json_body(request)
    if data is None:
        return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)

    name = data.get("full_name")
    email = data.get("email") or data.get("Email")
    phone = data.get("phone") or data.get("phoneno", "")
    department = data.get("department") or data.get("course", "")
    password = data.get("password") or get_random_string(10, string.ascii_letters + string.digits)

    if not name or not email:
        return JsonResponse({"success": False, "message": "full_name and email are required."}, status=400)
    if user_detail.objects.filter(Email=email).exists():
        return JsonResponse({"success": False, "message": "Email already registered."}, status=409)

    user = user_detail.objects.create(
        full_name=name,
        Email=email,
        phoneno=phone,
        course=resolve_department(department) or department,
        cv_url="",
        cv_name="",
        profile_url="",
        user_pass=password,
        role=HR_ROLE,
    )
    return JsonResponse({"success": True, "user": _candidate_payload(user)}, status=201)


@csrf_exempt
@require_http_methods(["POST"])
def api_login(request):
    data = request.POST.dict() if request.POST else _json_body(request)
    if data is None:
        return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)

    email = (data.get("email") or data.get("Email") or "").strip()
    password = data.get("password")
    try:
        user = user_detail.objects.get(Email__iexact=email, user_pass=password)
    except user_detail.DoesNotExist:
        return JsonResponse({"success": False, "message": "Invalid email or password."}, status=401)

    token = _create_token(user)
    return JsonResponse({"success": True, "token": token, "token_type": "Bearer", "user": _candidate_payload(user)})


@csrf_exempt
@require_http_methods(["POST"])
def api_logout(request):
    token = _token_from_request(request)
    if token:
        AutoLoginToken.objects.filter(token=token).delete()
    return JsonResponse({"success": True, "message": "Logged out."})


@csrf_exempt
@require_http_methods(["GET", "PUT", "PATCH", "POST"])
def api_profile(request):
    user, error = _require_user(request, [CANDIDATE_ROLE, HR_ROLE])
    if error:
        return error

    if request.method == "GET":
        return JsonResponse({"success": True, "user": _candidate_payload(user)})

    if request.content_type and request.content_type.startswith("application/json"):
        data = _json_body(request)
        if data is None:
            return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)
        user.full_name = data.get("full_name", user.full_name)
        user.Email = data.get("email", data.get("Email", user.Email))
        user.phoneno = data.get("phone", data.get("phoneno", user.phoneno))
        if "course" in data:
            user.course = resolve_department(data.get("course")) or data.get("course") or user.course
    else:
        user.full_name = request.POST.get("full_name") or request.POST.get("name") or user.full_name
        user.Email = request.POST.get("email") or request.POST.get("Email") or user.Email
        user.phoneno = request.POST.get("phone") or request.POST.get("phoneno") or user.phoneno
        if request.POST.get("course"):
            user.course = resolve_department(request.POST.get("course")) or request.POST.get("course")

        fs = FileSystemStorage()
        cv = request.FILES.get("cv") or request.FILES.get("resume")
        if cv:
            cv_error = _validate_cv_file(cv)
            if cv_error:
                return JsonResponse({"success": False, "message": cv_error}, status=400)
            user.skills = extract_skills_from_cv(cv)
            cv.seek(0)
            user.cv_name = cv.name
            user.cv_url = fs.url(fs.save(fs.get_available_name(cv.name), cv))

        profile = request.FILES.get("photo") or request.FILES.get("profile")
        if profile:
            user.profile_url = fs.url(fs.save(fs.get_available_name(profile.name), profile))

    user.save()
    return JsonResponse({"success": True, "user": _candidate_payload(user)})


@csrf_exempt
@require_http_methods(["POST"])
def api_extract_skills(request):
    user, error = _require_user(request, [CANDIDATE_ROLE])
    if error:
        return error

    cv = request.FILES.get("cv") or request.FILES.get("resume")
    cv_error = _validate_cv_file(cv)
    if cv_error:
        return JsonResponse({"success": False, "message": cv_error}, status=400)

    skills = extract_skills_from_cv(cv)
    cv.seek(0)
    fs = FileSystemStorage()
    user.cv_url = fs.url(fs.save(fs.get_available_name(cv.name), cv))
    user.cv_name = cv.name
    user.skills = skills
    user.save()
    return JsonResponse({
        "success": True,
        "skills": _candidate_payload(user)["skills"],
        "cv_url": user.cv_url,
        "cv_name": user.cv_name,
    })


@require_http_methods(["GET"])
def api_job_list(request):
    user = _api_user(request)
    jobs = Job.objects.filter(status="open").select_related("company_id", "hr_id").order_by("-created_at")
    query = request.GET.get("q")
    if query:
        jobs = jobs.filter(Q(job_title__icontains=query) | Q(skills__icontains=query) | Q(location__icontains=query))
    department = (request.GET.get("department") or request.GET.get("course") or "").strip()
    if not department and user and user.role == CANDIDATE_ROLE and user.course:
        department = user.course.strip()
    department = resolve_department(department)
    wants_skill_match = request.GET.get("skill_match") in ["1", "true", "True"]
    if department:
        jobs = jobs.filter(department_filter_q(department))
    location = request.GET.get("location")
    if location:
        jobs = jobs.filter(location__icontains=location)
    skills_filter = request.GET.get("skills") or request.GET.get("skill")
    if skills_filter:
        for skill in _skill_list(skills_filter):
            jobs = jobs.filter(skills__icontains=skill)

    try:
        page = max(int(request.GET.get("page", 1) or 1), 1)
        page_size = min(max(int(request.GET.get("page_size", 10) or 10), 1), 50)
    except (TypeError, ValueError):
        return JsonResponse({"success": False, "message": "Invalid pagination parameters."}, status=400)

    if wants_skill_match:
        if not user or user.role != CANDIDATE_ROLE:
            return JsonResponse({"success": False, "message": "Candidate authentication required."}, status=401)
        if not department:
            return JsonResponse(
                {
                    "success": False,
                    "message": "Set your department/course on your profile to see matching jobs.",
                },
                status=400,
            )
        user_skills = request.GET.get("match_skills") or user.skills
        sorted_jobs = sort_jobs_for_candidate(list(jobs), department, user_skills)
        paginator = Paginator(sorted_jobs, page_size)
        if paginator.count == 0:
            return _empty_jobs_response(page, page_size)
        try:
            page_obj = paginator.page(page)
        except EmptyPage:
            page_obj = paginator.page(paginator.num_pages)
        return JsonResponse({
            "success": True,
            "jobs": [_job_payload(job, user) for job in page_obj.object_list],
            "pagination": _pagination_meta(page_obj, paginator),
        })

    paginator = Paginator(jobs, page_size)
    if paginator.count == 0:
        return _empty_jobs_response(page, page_size)
    try:
        page_obj = paginator.page(page)
    except EmptyPage:
        page_obj = paginator.page(paginator.num_pages)
    candidate = user if user and user.role == CANDIDATE_ROLE else None
    return JsonResponse({
        "success": True,
        "jobs": [_job_payload(job, candidate) for job in page_obj.object_list],
        "pagination": _pagination_meta(page_obj, paginator),
    })


@require_http_methods(["GET"])
def api_job_detail(request, job_id):
    user = _api_user(request)
    try:
        job = Job.objects.select_related("company_id", "hr_id").get(id=job_id)
    except Job.DoesNotExist:
        return JsonResponse({"success": False, "message": "Job not found."}, status=404)
    return JsonResponse({"success": True, "job": _job_payload(job, user if user and user.role == CANDIDATE_ROLE else None)})


@csrf_exempt
@require_http_methods(["GET", "POST"])
def api_hr_companies(request):
    user, error = _require_user(request, [HR_ROLE])
    if error:
        return error

    if request.method == "GET":
        companies = Employee.objects.all().order_by("id")
        return JsonResponse({"success": True, "companies": [_company_payload(company) for company in companies]})

    data = _json_body(request)
    if data is None:
        return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)

    company_items = data
    if isinstance(data, dict):
        company_items = data.get("companies", data)

    if isinstance(company_items, dict):
        company_items = [company_items]

    if not isinstance(company_items, list) or not company_items:
        return JsonResponse({"success": False, "message": "Send a company object or a non-empty companies list."}, status=400)

    companies = []
    errors = []
    for index, item in enumerate(company_items):
        if not isinstance(item, dict):
            errors.append({"index": index, "message": "Company must be an object."})
            continue
        company_name = item.get("company_name") or item.get("name")
        if not company_name:
            errors.append({"index": index, "message": "company_name is required."})
            continue
        companies.append(Employee(
            company_name=company_name,
            email=item.get("email", ""),
            website=item.get("website", ""),
            location=item.get("location", ""),
        ))

    if errors:
        return JsonResponse({"success": False, "message": "Some companies are invalid.", "errors": errors}, status=400)

    created_companies = Employee.objects.bulk_create(companies)
    payload = [_company_payload(company) for company in created_companies]
    if len(payload) == 1 and isinstance(data, dict) and "companies" not in data:
        return JsonResponse({"success": True, "company": payload[0]}, status=201)
    return JsonResponse({"success": True, "companies": payload}, status=201)


@csrf_exempt
@require_http_methods(["POST"])
def api_create_job(request):
    user, error = _require_user(request, [HR_ROLE])
    if error:
        return error
    data = _json_body(request)
    if data is None:
        return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)

    job_items = data
    if isinstance(data, dict):
        job_items = data.get("jobs", data)

    if isinstance(job_items, dict):
        job_items = [job_items]

    if not isinstance(job_items, list) or not job_items:
        return JsonResponse({"success": False, "message": "Send a job object or a non-empty jobs list."}, status=400)

    required_fields = ["job_title", "company_id", "location", "duration", "stipend", "deadline", "skills", "description"]
    company_ids = set()
    for item in job_items:
        if isinstance(item, dict) and item.get("company_id"):
            try:
                company_ids.add(int(item.get("company_id")))
            except (TypeError, ValueError):
                pass
    companies = {company.id: company for company in Employee.objects.filter(id__in=company_ids)}

    jobs = []
    errors = []
    for index, item in enumerate(job_items):
        if not isinstance(item, dict):
            errors.append({"index": index, "message": "Job must be an object."})
            continue

        missing = [field for field in required_fields if not item.get(field)]
        if missing:
            errors.append({"index": index, "message": "Missing required fields.", "fields": missing})
            continue

        try:
            company_id = int(item.get("company_id"))
        except (TypeError, ValueError):
            errors.append({"index": index, "message": "company_id must be a number."})
            continue

        company = companies.get(company_id)
        if not company:
            errors.append({"index": index, "message": "Company not found.", "company_id": company_id})
            continue

        try:
            deadline = date.fromisoformat(str(item.get("deadline")))
        except ValueError:
            errors.append({"index": index, "message": "deadline must be in YYYY-MM-DD format."})
            continue

        status = item.get("status", "open")
        if status not in ["open", "draft", "closed"]:
            errors.append({"index": index, "message": "status must be open, draft, or closed."})
            continue

        jobs.append(Job(
            job_title=item.get("job_title"),
            company_id=company,
            hr_id=user,
            location=item.get("location"),
            department=item.get("department") or item.get("course") or "",
            duration=item.get("duration"),
            stipend=item.get("stipend"),
            deadline=deadline,
            skills=_skills_to_text(item.get("skills")),
            description=item.get("description"),
            status=status,
        ))

    if errors:
        return JsonResponse({"success": False, "message": "Some jobs are invalid.", "errors": errors}, status=400)

    created_jobs = Job.objects.bulk_create(jobs)
    payload = [_job_payload(job) for job in created_jobs]
    if len(payload) == 1 and isinstance(data, dict) and "jobs" not in data:
        return JsonResponse({"success": True, "job": payload[0]}, status=201)
    return JsonResponse({"success": True, "jobs": payload}, status=201)


def _candidate_applications_response(user):
    apps = application.objects.filter(user_id=user).select_related("user_id", "job_id", "job_id__company_id").order_by("-applied_at")
    return JsonResponse({"success": True, "applications": [_application_payload(app) for app in apps]})


@csrf_exempt
def api_applications(request):
    if request.method == "GET":
        return api_my_applications(request)
    if request.method == "POST":
        return api_apply_job(request)
    return JsonResponse({"success": False, "message": "Method not allowed."}, status=405)


@csrf_exempt
def api_apply_job(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "POST required."}, status=405)

    user, error = _require_user(request, [CANDIDATE_ROLE])
    if error:
        return error
    data = _json_body(request)
    if data is None:
        return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)

    job_id = data.get("job_id")
    if not job_id:
        return JsonResponse({"success": False, "message": "job_id is required."}, status=400)

    try:
        job = Job.objects.get(id=job_id, status="open")
    except (Job.DoesNotExist, ValueError, TypeError):
        return JsonResponse({"success": False, "message": "Job not found"}, status=404)

    existing = application.objects.filter(user_id=user, job_id=job).select_related("user_id", "job_id", "job_id__company_id").first()
    if existing:
        return JsonResponse({"success": False, "message": "Already applied.", "application": _application_payload(existing)}, status=409)

    app = application.objects.create(
        user_id=user,
        job_id=job,
        match_score=_match_score(user.skills, job.skills),
        status="applied",
    )
    Notification.objects.create(
        user=user,
        job=job,
        message=f"You applied for {job.job_title}. HR will review your application soon.",
    )
    return JsonResponse({"success": True, "application": _application_payload(app)}, status=201)


def api_my_applications(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "GET required."}, status=405)

    user, error = _require_user(request, [CANDIDATE_ROLE])
    if error:
        return error
    return _candidate_applications_response(user)


def api_candidate_dashboard(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "GET required."}, status=405)

    user, error = _require_user(request, [CANDIDATE_ROLE])
    if error:
        return error

    course_value = user.course.strip() if user.course else ""
    matched_jobs = filter_open_jobs_by_department(course_value, limit=50)
    matched_jobs = sort_jobs_for_candidate(matched_jobs, course_value, user.skills)[:10]
    recent_apps = application.objects.filter(user_id=user).select_related(
        "user_id", "job_id", "job_id__company_id"
    ).order_by("-applied_at")[:5]
    saved_jobs = SavedJob.objects.filter(user=user).select_related("job", "job__company_id", "job__hr_id")[:5]

    return JsonResponse({
        "success": True,
        "profile": _candidate_payload(user),
        "recommended_jobs": [_job_payload(job, user) for job in matched_jobs],
        "recent_applications": [_application_payload(app) for app in recent_apps],
        "saved_jobs": [_saved_job_payload(saved_job, user) for saved_job in saved_jobs],
    })


@csrf_exempt
def api_saved_jobs(request):
    user, error = _require_user(request, [CANDIDATE_ROLE])
    if error:
        return error

    if request.method == "GET":
        saved_jobs = SavedJob.objects.filter(user=user).select_related("job", "job__company_id", "job__hr_id")
        return JsonResponse({
            "success": True,
            "jobs": [_saved_job_payload(saved_job, user) for saved_job in saved_jobs],
        })
    return JsonResponse({"success": False, "message": "Method not allowed."}, status=405)


@csrf_exempt
def api_toggle_saved_job(request, job_id):
    user, error = _require_user(request, [CANDIDATE_ROLE])
    if error:
        return error

    try:
        job = Job.objects.get(id=job_id, status="open")
    except Job.DoesNotExist:
        return JsonResponse({"success": False, "message": "Job not found."}, status=404)

    if request.method == "POST":
        saved_job, created = SavedJob.objects.get_or_create(user=user, job=job)
        return JsonResponse({
            "success": True,
            "saved": True,
            "job": _saved_job_payload(saved_job, user),
            "message": "Job saved." if created else "Job already saved.",
        }, status=201 if created else 200)

    if request.method == "DELETE":
        SavedJob.objects.filter(user=user, job=job).delete()
        return JsonResponse({"success": True, "saved": False, "message": "Job removed from saved jobs."})

    return JsonResponse({"success": False, "message": "Method not allowed."}, status=405)


def api_hr_applications(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "GET required."}, status=405)

    user, error = _require_user(request, [HR_ROLE])
    if error:
        return error
    apps = application.objects.select_related(
        "user_id",
        "job_id",
        "job_id__company_id",
        "job_id__hr_id",
    ).order_by("-applied_at")
    status = request.GET.get("status")
    if status:
        apps = apps.filter(status=status)
    return JsonResponse({"success": True, "applications": [_application_payload(app) for app in apps]})


@csrf_exempt
def api_update_application_status(request, app_id):
    if request.method not in ["PATCH", "POST"]:
        return JsonResponse({"success": False, "message": "PATCH required."}, status=405)

    user, error = _require_user(request, [HR_ROLE])
    if error:
        return error
    data = _json_body(request)
    if data is None:
        return JsonResponse({"success": False, "message": "Invalid JSON."}, status=400)

    status = data.get("status")
    if status not in ["under_review", "approved", "rejected"]:
        return JsonResponse({"success": False, "message": "Status must be under_review, approved, or rejected."}, status=400)

    try:
        app = application.objects.select_related("user_id", "job_id").get(id=app_id)
    except application.DoesNotExist:
        return JsonResponse({"success": False, "message": "Application not found."}, status=404)

    if status == "rejected" and app.mcq_score is None:
        return JsonResponse({
            "success": False,
            "message": "Candidate can be rejected only after MCQ completion and HR evaluation.",
        }, status=400)

    previous_status = app.status
    app.status = status
    app.save(update_fields=["status"])
    if status == "approved" and previous_status != "approved":
        Notification.objects.create(
            user=app.user_id,
            job=app.job_id,
            message=(
                f"Your application for {app.job_id.job_title} was approved. "
                "You can now take the MCQ test from My Applications."
            ),
        )
    elif status == "rejected" and previous_status != "rejected":
        Notification.objects.create(
            user=app.user_id,
            job=app.job_id,
            message=(
                f"After HR evaluated your MCQ result for {app.job_id.job_title}, "
                "your application was not selected."
            ),
        )
    elif status == "under_review" and previous_status == "applied":
        Notification.objects.create(
            user=app.user_id,
            job=app.job_id,
            message=f"Your application for {app.job_id.job_title} is under HR review.",
        )
    return JsonResponse({"success": True, "application": _application_payload(app)})


@csrf_exempt
@require_http_methods(["PATCH", "POST"])
def api_mark_hired(request, app_id):
    user, error = _require_user(request, [HR_ROLE])
    if error:
        return error
    try:
        app = application.objects.select_related("user_id", "job_id").get(id=app_id)
    except application.DoesNotExist:
        return JsonResponse({"success": False, "message": "Application not found."}, status=404)

    if app.mcq_score is None:
        return JsonResponse({"success": False, "message": "MCQ score is missing."}, status=400)
    if app.mcq_score < PASS_MARK:
        return JsonResponse({"success": False, "message": "Candidate has not passed MCQ."}, status=400)

    app.status = "hired"
    app.save()
    Notification.objects.create(
        user=app.user_id,
        job=app.job_id,
        message=(
            f"After HR evaluated your MCQ result for {app.job_id.job_title}, "
            "you have been selected."
        ),
    )
    return JsonResponse({"success": True, "application": _application_payload(app)})
