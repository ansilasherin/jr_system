import random
from django.shortcuts import render, redirect ,get_object_or_404
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, JsonResponse
from .models import user_detail, Employee, Job ,application,Notification,AutoLoginToken
from django.utils.crypto import get_random_string
from django.db.models import Count,Q
import string
from django.core.mail import send_mail
from django.conf import settings
import json
import requests
import os
import re
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST,require_http_methods
from django.utils import timezone
from django.core.mail import EmailMultiAlternatives
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_GET
from datetime import datetime
from datetime import timedelta
import urllib.parse
import pytz

from .cv_skills import extract_skills_from_cv

REDIRECT_URI = "http://127.0.0.1:8000/meta-callback/"
APP_ID     = "1234567890123456" 
APP_SECRET = "abc123def456..."  

# ─── REGISTER ───────────────────────────

def reg(request):
    return render(request, 'reg.html')

def insert_data(request):
    if request.method == "POST":
        name     = request.POST.get("name")
        email    = request.POST.get("email")
        phoneno  = request.POST.get("phone")
        course   = request.POST.get("course")
        cv_url      = None
        cv_name     = ""
        profile_url = None
        extracted_skills = ""
        fs = FileSystemStorage()

        cv = request.FILES.get('cv')
        if cv:
            extracted_skills = extract_skills_from_cv(cv)
            cv.seek(0)
            cv_name = cv.name
            file   = fs.save(fs.get_available_name(cv.name), cv)
            cv_url = fs.url(file)

        profile = request.FILES.get('photo')
        if profile:
            file        = fs.save(fs.get_available_name(profile.name), profile)
            profile_url = fs.url(file)

        password = get_random_string(10, string.ascii_letters + string.digits)
        user = user_detail(
            full_name=name, Email=email, phoneno=phoneno,
            course=course, cv_url=cv_url, profile_url=profile_url,
            cv_name=cv_name,
            user_pass=password, skills=extracted_skills,
        )
        user.save()

        send_mail(
            "Your InternHub Login Password",
            f"Hi {name},\n\nYour account is ready!\nEmail: {email}\nPassword: {password}\n\nRegards,\nInternHub Team",
            settings.EMAIL_HOST_USER,
            [email],
            fail_silently=False,
        )
        return render(request, 'login.html')

def add_hr(request):
    if request.method == "POST":
        try:
            full_name  = request.POST.get("full_name")
            email      = request.POST.get("Email")
            phone      = request.POST.get("phoneno")
            department = request.POST.get("course")
            role       = request.POST.get("role", "hr")

            if not full_name or not email:
                return JsonResponse({"success": False, "message": "Name and Email required"})

            password = get_random_string(10, string.ascii_letters + string.digits)

            user = user_detail.objects.create(
                full_name=full_name,
                Email=email,
                phoneno=phone,
                course=department,
                role=role,
                user_pass=password
            )

            send_mail(
                "InternHub HR Account Created",
                f"Hi {full_name},\n\nYour HR account has been created.\n\nEmail: {email}\nPassword: {password}\n\nRegards,\nInternHub Team",
                settings.EMAIL_HOST_USER,
                [email],
                fail_silently=False,
            )

            return JsonResponse({"success": True})

        except Exception as e:
            return JsonResponse({"success": False, "message": str(e)})

    return JsonResponse({"success": False, "message": "Invalid method"})

# ─── FIX 1: was using undefined "User" — must be "user_detail" ───────────────
def get_hr(request, id):
    try:
        user = user_detail.objects.get(id=id)          # FIX: User → user_detail
        return JsonResponse({
            "id":          user.id,
            "full_name":   user.full_name,              # FIX: was "name"
            "Email":       user.Email,                  # capital E — matches JS
            "phoneno":     user.phoneno or "",          # FIX: was "phone"
            "course":      user.course or "",           # FIX: was "department"
            "role":        user.role,
            "profile_url": user.profile_url or "",
        })
    except user_detail.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)

# ─── forgot password ───────────────────────────

_otp_store = {}
 
def _generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))
 
def forgot_password(request):
    return render(request, 'forgot_password.html')

@require_http_methods(["POST"])
def send_otp(request):
    try:
        data  = json.loads(request.body)
        email = data.get("email", "").strip().lower()
    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({"ok": False, "error": "Invalid request."}, status=400)
 
    if not email:
        return JsonResponse({"ok": False, "error": "Email is required."}, status=400)
 
    try:
        user = user_detail.objects.get(Email=email)
    except user_detail.DoesNotExist:
        return JsonResponse({"ok": False, "error": "No account found for that email."}, status=404)
 
    otp = _generate_otp()
    _otp_store[email] = {"otp": otp, "verified": False}
 
    try:
        send_mail(
            subject="Your InternHub Password Reset Code",
            message=(
                f"Hi {user.full_name},\n\n"
                f"Your one-time code is: {otp}\n\n"
                f"It expires in 10 minutes.\n\n"
                f"— InternHub Team"
            ),
            from_email=settings.EMAIL_HOST_USER,
            recipient_list=[email],
            fail_silently=False,
        )
    except Exception as exc:
        return JsonResponse({"ok": False, "error": "Failed to send email. Try again."}, status=500)
 
    return JsonResponse({"ok": True})
 
@require_http_methods(["POST"])
def verify_otp(request):
    try:
        data  = json.loads(request.body)
        email = data.get("email", "").strip().lower()
        otp   = data.get("otp", "").strip()
    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({"ok": False, "error": "Invalid request."}, status=400)
 
    record = _otp_store.get(email)
 
    if not record:
        return JsonResponse({"ok": False, "error": "No OTP found. Please restart."}, status=400)
 
    if record["otp"] != otp:
        return JsonResponse({"ok": False, "error": "Incorrect code. Try again."}, status=400)
 
    record["verified"] = True
    return JsonResponse({"ok": True})
 
@require_http_methods(["POST"])
def reset_password(request):
    try:
        data     = json.loads(request.body)
        email    = data.get("email", "").strip().lower()
        password = data.get("password", "")
    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({"ok": False, "error": "Invalid request."}, status=400)
 
    record = _otp_store.get(email)
    if not record or not record.get("verified"):
        return JsonResponse({"ok": False, "error": "OTP not verified. Please restart."}, status=403)
 
    if len(password) < 8:
        return JsonResponse({"ok": False, "error": "Password must be at least 8 characters."}, status=400)
 
    try:
        user = user_detail.objects.get(Email=email)
    except user_detail.DoesNotExist:
        return JsonResponse({"ok": False, "error": "User not found."}, status=404)

    user.user_pass = password
    user.save()
    _otp_store.pop(email, None)
 
    return JsonResponse({"ok": True}) 
 
def _create_autologin_token(user):
    token = get_random_string(64)
    AutoLoginToken.objects.create(
        user=user,
        token=token,
        expires_at=timezone.now() + timedelta(days=30),
    )
    return token

# ─── LOGIN / LOGOUT ─────────────────────
def login(request):
    if request.session.get('userid'):
        role = request.session.get('role')
        if role == 'admin': return redirect('admin_dashboard')
        if role == 'hr':    return redirect('hr_dashboard')
        return redirect('user_dashboard')

    token_val = request.COOKIES.get('jr_autologin')
    if token_val:
        try:
            token_obj = AutoLoginToken.objects.select_related('user').get(token=token_val)
            if token_obj.is_valid():
                user = token_obj.user
                request.session['userid'] = user.id
                request.session['role']   = user.role
                request.session['name']   = user.full_name
                request.session.set_expiry(60 * 60 * 24 * 30)
                token_obj.delete()
                new_token = _create_autologin_token(user)
                if user.role == 'admin':   
                    response = redirect('admin_dashboard')
                elif user.role == 'hr':    
                    response = redirect('hr_dashboard')
                else:                      
                    response = redirect('user_dashboard')
                response.set_cookie('jr_autologin', new_token,
                                    max_age=60*60*24*30, httponly=True, samesite='Lax')
                return response
            else:
                token_obj.delete()
        except AutoLoginToken.DoesNotExist:
            pass

    return render(request, 'login.html')

def logout(request):
    token_val = request.COOKIES.get('jr_autologin')
    if token_val:
        AutoLoginToken.objects.filter(token=token_val).delete()
    request.session.flush()
    response = redirect('login')
    response.delete_cookie('jr_autologin')
    response.delete_cookie('jr_email')
    return response

def login_user(request):
    if request.method == "POST":
        email       = (request.POST.get("email") or "").strip()
        password    = request.POST.get("password")
        remember_me = request.POST.get("remember_me")
        try:
            user = user_detail.objects.get(Email__iexact=email, user_pass=password)
            request.session['userid'] = user.id
            request.session['role']   = user.role
            request.session['name']   = user.full_name

            if remember_me:
                request.session.set_expiry(60 * 60 * 24 * 30)
            else:
                request.session.set_expiry(0)

            if user.role == "user":
                response = redirect('user_dashboard')
            elif user.role == "admin":
                response = redirect('admin_dashboard')
            else:
                response = redirect('hr_dashboard')

            if remember_me:
                token = _create_autologin_token(user)
                response.set_cookie('jr_autologin', token,
                                    max_age=60*60*24*30, httponly=True, samesite='Lax')
                response.set_cookie('jr_email', urllib.parse.quote(email),
                                    max_age=60*60*24*30, httponly=False, samesite='Lax')
            else:
                response.delete_cookie('jr_autologin')
                response.delete_cookie('jr_email')

            return response

        except user_detail.DoesNotExist:
            return render(request, 'login.html', {'error': 'Invalid email or password'})
    
    return render(request, 'login.html')

# ─── DASHBOARDS ─────────────────────────

def user_dashboard(request):
    if request.session.get('role') != 'user':
        return redirect('login')

    user = user_detail.objects.get(id=request.session.get('userid'))
    companies = Employee.objects.all()
    user_id = request.session.get('userid')
    notifications = Notification.objects.filter(user_id=user_id).order_by('-created_at')
        
    user_skills = []
    if user.skills:
        user_skills = [s.strip().lower() for s in user.skills.split(",")]

    from .department_utils import (
        filter_open_jobs_by_department,
        resolve_department,
        sort_jobs_for_candidate,
    )

    department = resolve_department(user.course)
    if department:
        jobs = sort_jobs_for_candidate(
            filter_open_jobs_by_department(department),
            department,
            user.skills,
        )
    else:
        jobs = []

    for job in jobs:
        if job.skills:
            job.skill_list = [s.strip() for s in job.skills.split(",")]
            job_skill_lower = [s.strip().lower() for s in job.skills.split(",")]
        else:
            job.skill_list = []
            job_skill_lower = []

        if job_skill_lower:
            common_skills = set(user_skills) & set(job_skill_lower)
            match_percent = int((len(common_skills) / len(job_skill_lower)) * 100)
        else:
            match_percent = 0

        job.match = match_percent

    applied_jobs = application.objects.filter(
        user_id=user
    ).values_list('job_id_id', flat=True)

    applied_job_ids = list(applied_jobs)
    user_applications = application.objects.filter(
        user_id=user
    ).select_related('job_id', 'job_id__company_id').order_by('-applied_at')
    
    assessments = get_assessment_context(user)
    completed_assessments = get_completeAssessment_context(user)

    return render(request, "user_dashboard.html", {
        "user":                user,
        "jobs":                jobs,
        "skills":              user_skills,
        "company":             companies,
        "applied_job_ids":     applied_job_ids,
        "user_applications":   user_applications,
        "notifications":       notifications,
        "unread_count":        notifications.filter(is_read=False).count(),
        "assessments":         assessments,
        "has_assessment":      len(assessments) > 0,
        "completed_assessments": completed_assessments,
        "has_completed":       len(completed_assessments) > 0,
    })
    
@require_POST
def mark_all_read(request):
    user_id = request.session.get('userid')
    Notification.objects.filter(user_id=user_id, is_read=False).update(is_read=True)
    return JsonResponse({'status': 'ok'})

@require_POST
def delete_notification(request):
    user_id = request.session.get('userid')
    notif_id = request.POST.get('notif_id')
    try:
        notif = Notification.objects.get(id=notif_id, user_id=user_id)
        notif.delete()
        return JsonResponse({'status': 'deleted'})
    except Notification.DoesNotExist:
        return JsonResponse({'status': 'error'}, status=404)

def admin_dashboard(request):
    if request.session.get('role') != 'admin':
        return redirect('login')

    admin      = user_detail.objects.get(id=request.session.get('userid'))
    users      = user_detail.objects.all().order_by('id')
    emp        = Employee.objects.all().order_by('id')
    emp_count  = Employee.objects.count()
    hr_count   = user_detail.objects.filter(role='hr').count()
    student_count = user_detail.objects.exclude(role__in=['hr','emp','admin']).count()

    return render(request, "admin_dashboard.html", {
        "admin":         admin,
        "users":         users,
        "emp":           emp,
        "emp_count":     emp_count,
        "hr_count":      hr_count,
        "student_count": student_count,
    })

def hr_dashboard(request):
    company = Employee.objects.all()
    hr_id = request.session.get('userid')
    
    job_queryset = Job.objects.all().order_by('id').annotate(
        app_count=Count('application', filter=Q(application__status='pending'))
    )

    hr_data   = user_detail.objects.get(id=hr_id)
    hr_jobs   = Job.objects.filter(hr_id=hr_id, status='open').select_related('company_id')
    user_data = user_detail.objects.filter(role='user').annotate(app_count=Count('application'))
    
    for u in user_data: 
        if u.skills:
            u.skills = [s.strip() for s in u.skills.split(',')]
    
    pending_list = application.objects.filter(status='pending').order_by('-applied_at')

    job_list = []
    for j in job_queryset:
        j.skills_list = [s.strip() for s in j.skills.split(',') if s.strip()] if j.skills else []
        job_list.append(j)

    approved_apps = application.objects.filter(
        status='approved'
    ).select_related('user_id', 'job_id').order_by('-applied_at')
    
    completed_interview = application.objects.filter(status='interview_completed')

    approved_list = []
    for app in approved_apps:
        user = app.user_id
        job  = app.job_id
        approved_list.append({
            "app_id":      app.id,         
            "job_id":      job.id,
            "name":        user.full_name,
            "email":       user.Email,
            "course":      user.course,
            "cv_url":      user.cv_url,
            "skills":      user.skills,
            "applied_on":  app.applied_at,
            "approved_on": app.applied_at,
            "job_title":   job.job_title,
            "match_score": app.match_score,
            "company":     job.company_id.company_name if job.company_id else "N/A",
            "location":    job.location,
            "duration":    job.duration,
            "stipend":     job.stipend,
            "req_skill":   job.skills,
            "has_mcq":     bool(app.mcq_date),
            "has_machine": bool(app.machine_test_date),
            "has_hr":      bool(app.hr_interview_date),
        })

    rejected_apps = application.objects.filter(
        status='rejected'
    ).select_related('user_id', 'job_id').order_by('-applied_at')

    rejected_list = []
    for app in rejected_apps:
        user = app.user_id
        job  = app.job_id
        rejected_list.append({
            "job_id":      job.id,
            "name":        user.full_name,
            "email":       user.Email,
            "course":      user.course,
            "skills":      user.skills,
            "applied_on":  app.applied_at,
            "rejected_on": app.applied_at,
            "reason":      getattr(app, "feedback", "Insufficient skill match"),
            "job_title":   job.job_title,
            "company":     job.company_id.company_name if job.company_id else "N/A",
            "location":    job.location,
            "duration":    job.duration,
            "stipend":     job.stipend,
        })

    today = timezone.localdate()

    scheduled_apps = application.objects.filter(
        job_id__hr_id=hr_id,
        status='approved',
        hr_interview_date__isnull=False
    ).select_related('user_id', 'job_id', 'job_id__company_id').order_by('hr_interview_date')

    today_interviews    = []
    upcoming_interviews = []

    for app in scheduled_apps:
        entry = {
            "app_id":            app.id,
            "applicant_name":    app.user_id.full_name,
            "applicant_email":   app.user_id.Email,
            "job_title":         app.job_id.job_title,
            "company":           app.job_id.company_id.company_name if app.job_id.company_id else "N/A",
            "duration":          app.job_id.duration,
            "hr_interview_date": app.hr_interview_date,
            "mcq_date":          app.mcq_date,
            "machine_test_date": app.machine_test_date,
            "mcq_score":         app.mcq_score,
            "machine_test_score":app.machine_test_score,
            "room_url":          app.get_room_url(),
        }

        if app.hr_interview_date.date() == today:
            today_interviews.append(entry)
        elif app.hr_interview_date.date() > today:
            upcoming_interviews.append(entry)

    app_list = application.objects.all()
    
    for u in app_list: 
        if u.job_id.skills:
            u.job_id.skills = [s.strip() for s in u.job_id.skills.split(',')]
    
    return render(request, 'hr_dashboard.html', {
        'user':                    user_data,
        'hr':                      hr_data,
        'company':                 company,
        'job':                     job_list,
        'applications':            app_list,     
        'approved_apps':           approved_list,
        'rejected_apps':           rejected_list,
        'pending_apps':            pending_list,
        'hr_jobs':                 hr_jobs,
        'today_interviews':        today_interviews,
        'upcoming_interviews':     upcoming_interviews,
        'today_count':             len(today_interviews),
        'upcoming_count':          len(upcoming_interviews),
        'job_total':               job_queryset.count(),
        'job_open':                job_queryset.filter(status='open').count(),
        'job_draft':               job_queryset.filter(status='draft').count(),
        'job_closed':              job_queryset.filter(status='closed').count(),
        'total_apps_count':        application.objects.count(),
        'approved_apps_count':     len(approved_list),
        'rejected_apps_count':     len(rejected_list),
        'pending_apps_count':      application.objects.filter(status='pending').count(),
        'completed_interview_count': completed_interview.count(),
    })

# ─── PASSWORD ───────────────────────────

def change_password(request):
    current = request.POST.get("current_password")
    new_pw  = request.POST.get("new_password")
    confirm = request.POST.get("confirm_password")

    if new_pw != confirm:
        return JsonResponse({"status": "error", "message": "Passwords do not match."})
    
    if len(new_pw) < 8:
        return JsonResponse({"status": "error", "message": "Password must be at least 8 characters."})

    try:
        user = user_detail.objects.get(id=request.session['userid'])
    except user_detail.DoesNotExist:
        return JsonResponse({"status": "error", "message": "User not found."})

    if user.user_pass != current:
        return JsonResponse({"status": "error", "message": "Current password is incorrect."})

    user.user_pass = new_pw
    user.save()
    return JsonResponse({"status": "success", "message": "Password updated successfully."})

# ─── USER CRUD ───────────────────────────

def update_profile(request):
    if 'userid' not in request.session:
        return redirect('login')

    user = user_detail.objects.get(id=request.session['userid'])
    if request.method == "POST":
        user.full_name = request.POST.get("name")
        user.Email     = request.POST.get("email")
        user.phoneno   = request.POST.get("phone")
        user.course    = request.POST.get("course")

        profile = request.FILES.get('photo')
        if profile:
            fs = FileSystemStorage()
            filename = fs.save(profile.name, profile)
            user.profile_url = fs.url(filename)
        user.save()
    return redirect('dashboard')

# FIX 2: get_user — was already correct, no changes needed
def get_user(request, id):
    try:
        u = user_detail.objects.get(id=id)
        return JsonResponse({
            'id':          u.id,
            'full_name':   u.full_name,
            'Email':       u.Email,
            'phoneno':     u.phoneno or '',
            'course':      u.course or '',
            'role':        u.role,
            'profile_url': u.profile_url or '',
        })
    except user_detail.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)

def edit_user(request, id):
    if request.method == "POST":
        try:
            u           = user_detail.objects.get(id=id)
            u.full_name = request.POST.get('full_name', u.full_name)
            u.Email     = request.POST.get('Email', u.Email)
            u.phoneno   = request.POST.get('phoneno', u.phoneno)
            u.course    = request.POST.get('course', u.course)
            u.save()
            return JsonResponse({'success': True})
        except user_detail.DoesNotExist:
            return JsonResponse({'success': False, 'message': 'User not found'})
    return JsonResponse({'success': False})

# FIX 3: delete_user — was using undefined "User", must be "user_detail"
#         Also must return JsonResponse (not redirect) so JS can handle it
@require_POST
def delete_user(request, id):
    print("678")
    try:
        u = user_detail.objects.get(id=id)
        u.delete()
        return JsonResponse({'success': True})
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=404)
# ─── COMPANY CRUD ───────────────────────

def add_company(request):
    if request.method == "POST":
        Employee.objects.create(
            company_name=request.POST.get("company_name"),
            email=request.POST.get("email"),
            website=request.POST.get("website"),
            location=request.POST.get("location"),
        )
        return JsonResponse({"success": True})
    return JsonResponse({"success": False})

def view_company(request, id):
    try:
        c = Employee.objects.get(id=id)
        return JsonResponse({
            "id":                c.id,
            "company_name":      c.company_name,
            "email":             c.email,
            "website":           c.website,
            "location":          c.location,
            "created":           c.created_at.strftime("%d %b %Y"),
            "is_meta_connected": c.is_meta_connected,
            "fb_page_id":        c.fb_page_id or '',
            "ig_account_id":     c.ig_account_id or '',
        })
    except Employee.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)

def edit_company(request, id):
    if request.method == "POST":
        try:
            company              = Employee.objects.get(id=id)
            company.company_name = request.POST.get("company_name")
            company.email        = request.POST.get("email")
            company.website      = request.POST.get("website")
            company.location     = request.POST.get("location")
            company.save()
            return JsonResponse({
                "success":      True,
                "id":           company.id,
                "company_name": company.company_name,
                "email":        company.email,
                "website":      company.website,
                "location":     company.location,
            })
        except Employee.DoesNotExist:
            return JsonResponse({"success": False, "message": "Company not found"})
    return JsonResponse({"success": False})

def delete_company(request, id):
    if request.method == "POST":
        try:
            Employee.objects.get(id=id).delete()
            return JsonResponse({"success": True})
        except Employee.DoesNotExist:
            return JsonResponse({"success": False})
    return JsonResponse({"success": False})

# ─── JOB CRUD ───────────────────────────

def add_job(request):
    hr_id = request.session.get('userid')
    if request.method == "POST":
        try:
            data         = json.loads(request.body)
            employee_obj = Employee.objects.get(id=data["company"])
            job = Job.objects.create(
                job_title   = data.get("job_title"),
                company_id  = employee_obj,
                location    = data.get("location"),
                duration    = data.get("duration"),
                stipend     = data.get("stipend"),
                deadline    = data.get("deadline"),
                skills      = data.get("skills"),
                description = data.get("description"),
                status      = data.get("status"),
                hr_id       = user_detail.objects.get(id=hr_id)
            )
            return JsonResponse({"success": True, "job": {
                "title":    job.job_title,
                "company":  job.company_id.company_name,
                "location": job.location,
                "status":   job.status,
            }})
        except Exception as e:
            return JsonResponse({"success": False, "error": str(e)})
    return JsonResponse({"success": False})

def edit_job(request):
    if request.method == "POST":
        try:
            data            = json.loads(request.body)
            job             = Job.objects.get(id=data.get("job_id"))
            job.job_title   = data.get("job_title")
            job.location    = data.get("location")
            job.duration    = data.get("duration")
            job.stipend     = data.get("stipend")
            job.deadline    = data.get("deadline") or None
            job.skills      = data.get("skills")
            job.description = data.get("description")
            job.status      = data.get("status")
            job.save()
            return JsonResponse({"success": True})
        except Exception as e:
            return JsonResponse({"success": False, "error": str(e)})
    return JsonResponse({"success": False})

def delete_job(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            Job.objects.get(id=data.get("job_id")).delete()
            return JsonResponse({"success": True})
        except Exception as e:
            return JsonResponse({"success": False, "error": str(e)})
    return JsonResponse({"success": False})

def connect_meta(request, company_id):
    request.session["connecting_company_id"] = company_id
    fb_login_url = (
        f"https://www.facebook.com/v18.0/dialog/oauth"
        f"?client_id={APP_ID}"
        f"&redirect_uri={REDIRECT_URI}"
        f"&scope=pages_show_list,pages_manage_posts,"
        f"instagram_basic,instagram_content_publish"
        f"&response_type=code"
    )
    return redirect(fb_login_url)

def get_long_lived_token(short_token):
    response = requests.get(
        "https://graph.facebook.com/v18.0/oauth/access_token",
        params={
            "grant_type":        "fb_exchange_token",
            "client_id":         APP_ID,
            "client_secret":     APP_SECRET,
            "fb_exchange_token": short_token,
        }
    ).json()
    return response.get("access_token")

def meta_callback(request):
    company_id = request.session.get("connecting_company_id")
    if not company_id:
        return redirect('/admin-dashboard/')

    try:
        company = Employee.objects.get(id=company_id)
    except Employee.DoesNotExist:
        return redirect('/admin-dashboard/')

    error = request.GET.get("error")
    if error:
        return redirect(f'/admin-dashboard/?meta_error={request.GET.get("error_reason","Unknown")}')

    code = request.GET.get("code")
    if not code:
        return redirect('/admin-dashboard/')

    try:
        token_response = requests.get(
            "https://graph.facebook.com/v18.0/oauth/access_token",
            params={
                "client_id":     APP_ID,
                "redirect_uri":  REDIRECT_URI,
                "client_secret": APP_SECRET,
                "code":          code,
            }
        ).json()

        short_token = token_response.get("access_token")
        if not short_token:
            return redirect('/admin-dashboard/?meta_error=token_failed')

        long_token = get_long_lived_token(short_token)
        if not long_token:
            return redirect('/admin-dashboard/?meta_error=longtoken_failed')

        pages_response = requests.get(
            "https://graph.facebook.com/v18.0/me/accounts",
            params={"access_token": long_token}
        ).json()

        pages = pages_response.get("data", [])
        if not pages:
            return redirect('/admin-dashboard/?meta_error=no_pages')

        page       = pages[0]
        page_id    = page["id"]
        page_token = page["access_token"]

        ig_response = requests.get(
            f"https://graph.facebook.com/v18.0/{page_id}",
            params={"fields": "instagram_business_account", "access_token": page_token}
        ).json()

        ig_id = None
        if "instagram_business_account" in ig_response:
            ig_id = ig_response["instagram_business_account"]["id"]

        company.fb_page_id        = page_id
        company.ig_account_id     = ig_id
        company.page_access_token = page_token
        company.is_meta_connected = True
        company.save()

        del request.session["connecting_company_id"]
        return redirect('/admin-dashboard/?meta_success=1')

    except Exception as e:
        print(f"Meta callback error: {e}")
        return redirect('/admin-dashboard/?meta_error=server_error')
    
def apply_job(request):
    if request.method == "POST":
        user_id  = request.session.get('userid')
        job_id   = request.POST.get('job_id')
        user_obj = user_detail.objects.get(id=user_id)
        job_obj  = Job.objects.get(id=job_id)

        already = application.objects.filter(user_id=user_obj, job_id=job_obj).exists()
        if not already:
            application.objects.create(user_id=user_obj, job_id=job_obj)
            return JsonResponse({"status": "success"})
        return JsonResponse({"status": "exists"})
    
def toggle_apply_job(request):
    if request.method == "POST":
        user_id  = request.session.get('userid')
        job_id   = request.POST.get('job_id')
        user_obj = user_detail.objects.get(id=user_id)
        job_obj  = Job.objects.get(id=job_id)

        existing = application.objects.filter(user_id=user_obj, job_id=job_obj).first()

        if existing:
            existing.delete()
            return JsonResponse({"status": "removed"})
        else:
            user_skills = [s.strip().lower() for s in user_obj.skills.split(",")] if user_obj.skills else []
            job_skills  = [s.strip().lower() for s in job_obj.skills.split(",")]  if job_obj.skills  else []

            if job_skills:
                common     = set(user_skills) & set(job_skills)
                match_score = int((len(common) / len(job_skills)) * 100)
            else:
                match_score = 0

            application.objects.create(user_id=user_obj, job_id=job_obj, match_score=match_score)
            return JsonResponse({"status": "applied", "match_score": match_score})
    
def view_applications(request, job_id):
    applications = application.objects.filter(job_id=job_id).select_related('user_id')
    data = []
    for app in applications:
        data.append({
            "id":     app.id,
            "name":   app.user_id.full_name,
            "email":  app.user_id.Email,
            "date":   app.applied_at.strftime("%b %d, %Y"),
            "status": app.status
        })
    return JsonResponse({"applications": data})

@csrf_exempt
def update_application_status(request):
    if request.method == "POST":
        data   = json.loads(request.body)
        app_id = data.get("id")
        status = data.get("status")
        app    = application.objects.get(id=app_id)
        app.status = status
        app.save()
        return JsonResponse({"success": True})

def save_process(request):
    try:
        data    = json.loads(request.body)
        job_id  = data.get("job_id")
        app_id  = data.get("app_id")
        stage   = data.get("stage")
        date    = data.get("date")
        action  = data.get("action")
        slots   = data.get("slots", [])

        ist = pytz.timezone('Asia/Kolkata')

        field_map = {
            "mcq":     "mcq_date",
            "machine": "machine_test_date",
            "hr":      "hr_interview_date"
        }
        stage_labels = {
            "mcq":     "MCQ Test",
            "machine": "Machine Test",
            "hr":      "HR Interview"
        }

        def parse_dt(dt_str):
            naive = datetime.strptime(dt_str[:16], "%Y-%m-%dT%H:%M")
            return ist.localize(naive)

        if stage not in field_map:
            return JsonResponse({"status": "error", "message": "Invalid stage"}, status=400)

        if stage == "hr" and slots:
            processed_apps = []
            job     = None
            message = ""

            for slot in slots:
                slot_app_id   = slot.get("app_id")
                slot_datetime = slot.get("datetime")
                if not slot_app_id:
                    continue
                try:
                    app = application.objects.select_related('user_id', 'job_id').get(id=slot_app_id)
                except application.DoesNotExist:
                    continue

                job  = app.job_id
                user = app.user_id

                if action == "remove":
                    app.hr_interview_date = None
                    app.save()
                    message = f"❌ {stage_labels['hr']} for '{job.job_title}' has been cancelled."
                else:
                    if not slot_datetime:
                        continue
                    parsed = parse_dt(slot_datetime)
                    app.hr_interview_date = parsed
                    app.save()
                    formatted = parsed.strftime("%B %d, %Y at %I:%M %p")
                    verb      = "scheduled" if action == "apply" else "rescheduled"
                    rank      = slot.get("rank", "")
                    message   = (
                        f"📅 HR Interview for '{job.job_title}' has been {verb}.\n"
                        f"Your slot: {formatted} IST (Rank #{rank})"
                    )

                Notification.objects.create(user=user, job=job, message=message, is_read=False)
                processed_apps.append(app)

            if processed_apps and job:
                send_notification_emails(
                    processed_apps,
                    subject=f"InternHub — {stage_labels['hr']}",
                    message=message,
                    stage_label=stage_labels['hr'],
                    job=job,
                    action=action
                )
            return JsonResponse({"status": "success"})

        if stage == "hr" and action == "remove" and job_id:
            apps = application.objects.select_related('user_id', 'job_id').filter(
                job_id=job_id, status='approved'
            )
            if not apps.exists():
                return JsonResponse({"status": "error", "message": "No applications found"}, status=404)

            job     = apps.first().job_id
            message = f"❌ HR Interview for '{job.job_title}' has been cancelled."

            for app in apps:
                app.hr_interview_date = None
                app.save()
                Notification.objects.create(user=app.user_id, job=job, message=message, is_read=False)

            send_notification_emails(
                list(apps),
                subject=f"InternHub — {stage_labels['hr']}",
                message=message,
                stage_label=stage_labels['hr'],
                job=job,
                action=action
            )
            return JsonResponse({"status": "success"})

        if job_id:
            apps = application.objects.select_related('user_id', 'job_id').filter(
                job_id=job_id, status='approved'
            )
            if not apps.exists():
                return JsonResponse({"status": "error", "message": "No applications found"}, status=404)
        else:
            apps = application.objects.select_related('user_id', 'job_id').filter(id=app_id)
            if not apps.exists():
                return JsonResponse({"status": "error", "message": "Application not found"}, status=404)

        job     = apps.first().job_id
        message = ""

        for app in apps:
            user = app.user_id
            if action in ["apply", "update"]:
                if not date:
                    return JsonResponse({"status": "error", "message": "Date required"}, status=400)
                parsed    = parse_dt(date)
                setattr(app, field_map[stage], parsed)
                app.save()
                formatted = parsed.strftime("%B %d, %Y at %I:%M %p")
                verb      = "scheduled" if action == "apply" else "rescheduled"
                message   = f"📅 {stage_labels[stage]} for '{job.job_title}' has been {verb} on {formatted} IST."
                Notification.objects.create(user=user, job=job, message=message, is_read=False)
            elif action == "remove":
                setattr(app, field_map[stage], None)
                app.save()
                message = f"❌ {stage_labels[stage]} for '{job.job_title}' has been cancelled."
                Notification.objects.create(user=user, job=job, message=message, is_read=False)

        send_notification_emails(
            list(apps),
            subject=f"InternHub — {stage_labels[stage]}",
            message=message,
            stage_label=stage_labels[stage],
            job=job,
            action=action
        )
        return JsonResponse({"status": "success"})

    except Exception as e:
        print("ERROR in save_process:", e)
        return JsonResponse({"status": "error", "message": str(e)}, status=500)
    
def get_process(request, id):
    try:
        if request.GET.get("type") == "job":
            app = application.objects.filter(job_id=id, status='approved').first()
            if not app:
                return JsonResponse({"mcq_date": None, "machine_test_date": None, "hr_interview_date": None})
        else:
            app = application.objects.get(id=id)

        return JsonResponse({
            "mcq_date":          app.mcq_date.strftime("%Y-%m-%d %H:%M") if app.mcq_date else None,
            "machine_test_date": app.machine_test_date.strftime("%Y-%m-%d %H:%M") if app.machine_test_date else None,
            "hr_interview_date": app.hr_interview_date.strftime("%Y-%m-%d %H:%M") if app.hr_interview_date else None,
            "room_url":          app.get_room_url(),
        })
    except application.DoesNotExist:
        return JsonResponse({"mcq_date": None, "machine_test_date": None, "hr_interview_date": None})
    
def send_notification_emails(approved_apps, subject, message, stage_label, job, action):  
    for app in approved_apps:
        user = app.user_id
        if not user.Email:
            continue

        if action == "remove":
            icon        = "❌"
            color       = "#dc2626"
            badge_bg    = "#fff0f0"
            badge_color = "#dc2626"
            badge_text  = "CANCELLED"
            action_text = f"Unfortunately, the <strong>{stage_label}</strong> for <strong>{job.job_title}</strong> has been cancelled."
            footer_note = "Please check your dashboard for updates or contact your HR."
        else:
            icon        = "📅"
            color       = "#0a0a0a"
            badge_bg    = "#f0fdf4"
            badge_color = "#16a34a"
            badge_text  = "SCHEDULED" if action == "apply" else "RESCHEDULED"
            action_text = f"Your <strong>{stage_label}</strong> for <strong>{job.job_title}</strong> has been <strong>{'scheduled' if action == 'apply' else 'rescheduled'}</strong>."
            footer_note = "Please be prepared and log in to your dashboard for more details."

        html_content = f"""
        <!DOCTYPE html><html><head><meta charset="UTF-8"></head>
        <body style="margin:0;padding:0;background:#f5f5f5;font-family:Arial,sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f5;padding:40px 0;">
            <tr><td align="center">
              <table width="560" cellpadding="0" cellspacing="0" style="background:#fff;border:1px solid #e5e5e5;">
                <tr><td style="background:#0a0a0a;padding:28px 36px;">
                  <span style="color:#fff;font-size:16px;font-weight:700;">InternHub</span>
                  <span style="float:right;background:{badge_bg};color:{badge_color};font-size:9px;font-weight:700;padding:4px 10px;">{badge_text}</span>
                </td></tr>
                <tr><td style="background:{color};padding:20px;text-align:center;font-size:28px;">{icon}</td></tr>
                <tr><td style="padding:36px;">
                  <p style="font-size:22px;font-weight:900;color:#0a0a0a;margin:0 0 8px;">Hi {user.full_name},</p>
                  <p style="font-size:14px;color:#6b6b6b;margin:0 0 28px;">{action_text}</p>
                  <table width="100%" style="background:#f5f5f5;border:1px solid #ebebeb;margin-bottom:28px;">
                    <tr><td style="padding:20px;">
                      <div style="font-size:9px;color:#a0a0a0;text-transform:uppercase;margin-bottom:4px;">Position</div>
                      <div style="font-size:14px;font-weight:700;color:#0a0a0a;">{job.job_title}</div>
                      <div style="font-size:9px;color:#a0a0a0;text-transform:uppercase;margin:14px 0 4px;">Details</div>
                      <div style="font-size:14px;color:#3d3d3d;">{message}</div>
                    </td></tr>
                  </table>
                  <p style="font-size:12px;color:#a0a0a0;">{footer_note}</p>
                </td></tr>
                <tr><td style="background:#0a0a0a;padding:20px 36px;">
                  <span style="font-size:11px;color:#6b6b6b;">© 2026 InternHub · Do not reply</span>
                </td></tr>
              </table>
            </td></tr>
          </table>
        </body></html>
        """

        email_msg = EmailMultiAlternatives(
            subject=subject,
            body=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user.Email]
        )
        email_msg.attach_alternative(html_content, "text/html")
        email_msg.send(fail_silently=True)

def get_assessment_context(user):
    approved_apps = application.objects.filter(
        user_id=user, status='approved'
    ).select_related('job_id', 'job_id__company_id')

    assessments = []
    for app in approved_apps:
        assessments.append({
            'job':               app.job_id,
            'application_id':    app.id,
            'mcq_date':          app.mcq_date,
            'machine_test_date': app.machine_test_date,
            'hr_interview_date': app.hr_interview_date,
            'mcq_mark':          app.mcq_score,
            'machine_mark':      app.machine_test_score,
            'room_url':          app.get_room_url(),
            'can_start_mcq':     app.mcq_score is None,
        })
    return assessments

def get_completeAssessment_context(user):
    approved_apps = application.objects.filter(
        user_id=user, status='interview_completed'
    ).select_related('job_id')

    assessments = []
    for app in approved_apps:
        if not any([app.mcq_date, app.machine_test_date, app.hr_interview_date]):
            continue
        assessments.append({
            'job':                app.job_id,
            'mcq_date':           app.mcq_date,
            'machine_test_date':  app.machine_test_date,
            'hr_interview_date':  app.hr_interview_date,
            'mcq_mark':           app.mcq_score,
            'machine_mark':       app.machine_test_score,
            'room_url':           app.get_room_url(),
            'interview_feedback': app.interview_feedback,
        })
    return assessments

def api_calendar_interviews(request):
    hr_id = request.session.get('userid')
    if not hr_id:
        return JsonResponse({'error': 'Not authenticated'}, status=401)

    import datetime as dt
    import calendar as cal

    _today = dt.date.today()

    try:
        year  = int(request.GET.get('year',  _today.year))
        month = int(request.GET.get('month', _today.month))
    except (ValueError, TypeError):
        return JsonResponse({'error': 'Invalid'}, status=400)

    month_apps = application.objects.filter(
        job_id__hr_id=hr_id,
        status='approved',
        hr_interview_date__year=year,
        hr_interview_date__month=month,
    ).select_related('user_id', 'job_id', 'job_id__company_id').order_by('hr_interview_date')

    events = []
    for app in month_apps:
        events.append({
            'id':        app.id,
            'date':      app.hr_interview_date.strftime('%Y-%m-%d'),
            'time':      app.hr_interview_date.strftime('%I:%M %p'),
            'day':       app.hr_interview_date.day,
            'candidate': app.user_id.full_name,
            'job_title': app.job_id.job_title,
            'company':   app.job_id.company_id.company_name if app.job_id.company_id else 'N/A',
            'status':    'not_started',
            'room_url':  app.get_room_url(),
        })

    today_apps = application.objects.filter(
        job_id__hr_id=hr_id,
        status='approved',
        hr_interview_date__date=_today,
    ).select_related('user_id', 'job_id', 'job_id__company_id').order_by('hr_interview_date')

    today_events = []
    for app in today_apps:
        today_events.append({
            'id':        app.id,
            'time':      app.hr_interview_date.strftime('%I:%M %p'),
            'candidate': app.user_id.full_name,
            'job_title': app.job_id.job_title,
            'company':   app.job_id.company_id.company_name if app.job_id.company_id else 'N/A',
            'status':    'not_started',
            'room_url':  app.get_room_url(),
        })

    week_start = _today - dt.timedelta(days=_today.weekday())
    week_end   = week_start + dt.timedelta(days=6)
    week_count = application.objects.filter(
        job_id__hr_id=hr_id,
        status='approved',
        hr_interview_date__date__gte=week_start,
        hr_interview_date__date__lte=week_end,
    ).count()

    return JsonResponse({
        'year':          year,
        'month':         month,
        'month_name':    cal.month_name[month],
        'days_in_month': cal.monthrange(year, month)[1],
        'first_weekday': cal.monthrange(year, month)[0],
        'events':        events,
        'today_events':  today_events,
        'stats': {
            'today': len(today_events),
            'week':  week_count,
        }
    })
    
def get_ranklist(request):
    try:
        job_id       = request.GET.get('job_id')
        applications = application.objects.filter(
            job_id=job_id, status__in=['approved', 'interview_completed']
        ).select_related('user_id')

        students = []
        for app in applications:
            students.append({
                'name':                 app.user_id.full_name,
                'email':                app.user_id.Email,
                'course':               app.user_id.course,
                'phone':                app.user_id.phoneno,
                'skills':               app.user_id.skills or '',
                'cv_url':               app.user_id.cv_url,
                'profile_url':          app.user_id.profile_url,
                'mcq_score':            app.mcq_score,
                'machine_score':        app.machine_test_score,
                'approved_on':          app.applied_at.strftime('%b %d, %Y') if app.applied_at else '',
                'mcq_date':             app.mcq_date.strftime('%b %d, %Y') if app.mcq_date else '',
                'machine_date':         app.machine_test_date.strftime('%b %d, %Y') if app.machine_test_date else '',
                'interview_date':       app.hr_interview_date.strftime('%b %d, %Y · %I:%M %p') if app.hr_interview_date else '',
                'interview_result':     app.interview_result,
                'interview_feedback':   app.interview_feedback or '',
                'interview_analysis':   app.interview_analysis,
                'interview_transcript': app.interview_transcript or '',
                'match_score':          app.match_score,
                'status':               app.status,
                'job_title':            app.job_id.job_title,
                'app_id':               app.id,
            })

        return JsonResponse({'students': students})

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return JsonResponse({'error': str(e)}, status=500)    
 
def google_login_callback(request):
    django_user = request.user
    if not django_user.is_authenticated:
        return redirect('login')
 
    google_email = django_user.email
 
    try:
        jr_user = user_detail.objects.get(Email__iexact=google_email)
    except user_detail.DoesNotExist:
        return render(request, 'login.html', {
            'error': f'No InternHub account found for {google_email}. Please register first.'
        })
 
    request.session['userid'] = jr_user.id
    request.session['role']   = jr_user.role
    request.session['name']   = jr_user.full_name
 
    if jr_user.role == 'admin':
        return redirect('admin_dashboard')
    elif jr_user.role == 'hr':
        return redirect('hr_dashboard')
    else:
        return redirect('user_dashboard')
