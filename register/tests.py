import json
from datetime import date, timedelta

from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from .models import AutoLoginToken, Employee, Job, application, user_detail


class HrApplicationsApiTests(TestCase):
    def setUp(self):
        self.owner_hr = user_detail.objects.create(
            full_name="Job Owner HR",
            Email="owner-hr@example.com",
            phoneno="9000000001",
            course="HR",
            cv_url="",
            profile_url="",
            user_pass="pass1234",
            role="hr",
        )
        self.viewer_hr = user_detail.objects.create(
            full_name="Viewer HR",
            Email="viewer-hr@example.com",
            phoneno="9000000002",
            course="HR",
            cv_url="",
            profile_url="",
            user_pass="pass1234",
            role="hr",
        )
        self.candidate = user_detail.objects.create(
            full_name="Applied Candidate",
            Email="candidate@example.com",
            phoneno="9000000003",
            course="Flutter",
            cv_url="/media/candidate_cv.pdf",
            cv_name="candidate_cv.pdf",
            profile_url="",
            user_pass="pass1234",
            role="user",
            skills="Flutter,Dart",
        )
        self.company = Employee.objects.create(company_name="JR Systems")
        self.job = Job.objects.create(
            job_title="Flutter Developer",
            company_id=self.company,
            hr_id=self.owner_hr,
            location="Kochi",
            duration="0-1 years",
            stipend="12000/month",
            deadline=date.today() + timedelta(days=30),
            skills="Flutter,Dart",
            department="Flutter",
            description="Build Flutter screens.",
            status="open",
        )
        self.application = application.objects.create(
            user_id=self.candidate,
            job_id=self.job,
            match_score=95,
            status="applied",
        )
        token = AutoLoginToken.objects.create(
            user=self.viewer_hr,
            token="viewer-token",
            expires_at=timezone.now() + timedelta(days=1),
        )
        self.auth_headers = {"HTTP_AUTHORIZATION": f"Bearer {token.token}"}

    def test_hr_can_see_existing_applications_for_all_jobs(self):
        response = self.client.get(
            reverse("api_hr_applications"),
            **self.auth_headers,
        )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(len(body["applications"]), 1)
        payload = body["applications"][0]
        self.assertEqual(payload["candidate_name"], "Applied Candidate")
        self.assertEqual(payload["candidate_cv_url"], "/media/candidate_cv.pdf")
        self.assertEqual(payload["job_title"], "Flutter Developer")
        self.assertEqual(payload["status"], "applied")

    def test_hr_can_approve_existing_application(self):
        response = self.client.post(
            reverse("api_update_application_status", args=[self.application.id]),
            data=json.dumps({"status": "approved"}),
            content_type="application/json",
            **self.auth_headers,
        )

        self.assertEqual(response.status_code, 200)
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "approved")
        self.assertEqual(response.json()["application"]["status"], "approved")

    def test_hr_cannot_make_final_rejection_before_mcq_completion(self):
        response = self.client.post(
            reverse("api_update_application_status", args=[self.application.id]),
            data=json.dumps({"status": "rejected"}),
            content_type="application/json",
            **self.auth_headers,
        )

        self.assertEqual(response.status_code, 400)
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "applied")

    def test_hr_can_reject_after_mcq_completion(self):
        self.application.status = "mcq_completed"
        self.application.mcq_score = 42
        self.application.save(update_fields=["status", "mcq_score"])

        response = self.client.post(
            reverse("api_update_application_status", args=[self.application.id]),
            data=json.dumps({"status": "rejected"}),
            content_type="application/json",
            **self.auth_headers,
        )

        self.assertEqual(response.status_code, 200)
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "rejected")

    def test_hr_can_hire_after_passing_mcq_completion(self):
        self.application.status = "mcq_completed"
        self.application.mcq_score = 82
        self.application.save(update_fields=["status", "mcq_score"])

        response = self.client.post(
            reverse("api_mark_hired", args=[self.application.id]),
            **self.auth_headers,
        )

        self.assertEqual(response.status_code, 200)
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "hired")
