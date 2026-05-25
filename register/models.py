from django.db import models
import uuid
from django.utils import timezone


class user_detail(models.Model):
    id=models.AutoField(primary_key=True)
    full_name=models.CharField(max_length=100)
    Email=models.EmailField(unique=True)
    phoneno=models.CharField(max_length=15)
    course=models.CharField(max_length=100)
    cv_url=models.CharField(max_length=200)
    cv_name=models.CharField(max_length=255, blank=True, default="")
    profile_url=models.CharField(max_length=200)
    user_pass=models.CharField(max_length=100)  
    role=models.CharField(max_length=20, default="user")
    skills = models.TextField(blank=True, null=True)
    reg_date = models.DateTimeField(default=timezone.now)
 
class AutoLoginToken(models.Model):
    user       = models.ForeignKey(user_detail, on_delete=models.CASCADE, related_name='auto_login_tokens')
    token      = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    def is_valid(self):
        from django.utils import timezone
        return timezone.now() < self.expires_at 
    
class Employee(models.Model):
    company_name = models.CharField(max_length=200)
    email = models.EmailField(max_length=150, blank=True, null=True)
    website = models.URLField(max_length=150, blank=True, null=True)
    location = models.CharField(max_length=150, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    role=models.CharField(max_length=20, default="emp")
    
    # META CONNECTION FIELDS
    fb_page_id = models.CharField(max_length=255, blank=True, null=True)
    ig_account_id = models.CharField(max_length=255, blank=True, null=True)
    page_access_token = models.TextField(blank=True, null=True)
    is_meta_connected = models.BooleanField(default=False)
    

    def __str__(self):
        return self.company_name
    
class Job(models.Model):
    STATUS_CHOICES = (
        ('open', 'Open'),
        ('draft', 'Draft'),
        ('closed', 'Closed'),
    )

    job_title = models.CharField(max_length=200)
    company_id = models.ForeignKey(Employee, on_delete=models.CASCADE)
    hr_id = models.ForeignKey(user_detail, on_delete=models.CASCADE)
    location = models.CharField(max_length=200)
    duration = models.CharField(max_length=100)
    stipend = models.CharField(max_length=100)

    deadline = models.DateField()

    skills = models.TextField(help_text="Comma separated skills")
    department = models.CharField(max_length=100, blank=True, null=True)
    description = models.TextField()

    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='open')

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.job_title

class application(models.Model):
    STATUS_CHOICES = [
        ('applied', 'Applied'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('mcq_completed', 'MCQ Completed'),
        ('hired', 'Hired'),
        # Legacy values kept so old rows/admin pages do not break.
        ('pending', 'Pending'),
        ('under_review', 'Under Review'),
        ('interview_completed', 'Interview Completed'),
    ]

    user_id = models.ForeignKey(user_detail, on_delete=models.CASCADE)
    job_id = models.ForeignKey(Job, on_delete=models.CASCADE)
    match_score = models.IntegerField(default=0)
    applied_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(
        max_length=20,
        default='applied',
        choices=STATUS_CHOICES,
    )
    mcq_score = models.FloatField(null=True, blank=True)
    machine_test_score = models.FloatField(null=True, blank=True)

    mcq_date          = models.DateTimeField(null=True, blank=True)
    machine_test_date = models.DateTimeField(null=True, blank=True)
    hr_interview_date = models.DateTimeField(null=True, blank=True)
    interview_room_id = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)

    INTERVIEW_RESULT_CHOICES = [
        ('pending',  'Pending'),
        ('passed',   'Passed'),
        ('failed',   'Failed'),
    ]

    # ... your existing fields ...
    interview_result   = models.CharField(
        max_length=20,
        choices=INTERVIEW_RESULT_CHOICES,
        default='pending'
    )
    interview_feedback = models.TextField(null=True, blank=True)
    interview_recording = models.FileField(
        upload_to='interview_recordings/',
        null=True, blank=True
    )
    interview_transcript = models.TextField(null=True, blank=True)
    interview_analysis   = models.JSONField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.user_id.full_name} - {self.job_id.job_title}"

    def get_room_url(self):
        return f"/interview/lobby/{self.interview_room_id}/"
    
class Notification(models.Model):
    user = models.ForeignKey(user_detail, on_delete=models.CASCADE)
    job  = models.ForeignKey(Job, on_delete=models.CASCADE)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.full_name}"


class SavedJob(models.Model):
    user = models.ForeignKey(user_detail, on_delete=models.CASCADE, related_name='saved_jobs')
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='saved_by')
    saved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'job')
        ordering = ['-saved_at']

    def __str__(self):
        return f"{self.user.full_name} saved {self.job.job_title}"
