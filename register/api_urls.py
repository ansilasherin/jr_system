from django.urls import path

from . import api


urlpatterns = [
    path("auth/register/candidate/", api.api_register_candidate, name="api_register_candidate"),
    path("auth/register/hr/", api.api_register_hr, name="api_register_hr"),
    path("auth/login/", api.api_login, name="api_login"),
    path("auth/logout/", api.api_logout, name="api_logout"),

    path("candidate/profile/", api.api_profile, name="api_profile"),
    path("candidate/skills/extract/", api.api_extract_skills, name="api_extract_skills"),
    path("candidate/dashboard/", api.api_candidate_dashboard, name="api_candidate_dashboard"),
    path("candidate/saved-jobs/", api.api_saved_jobs, name="api_saved_jobs"),

    path("jobs/", api.api_job_list, name="api_job_list"),
    path("jobs/<int:job_id>/", api.api_job_detail, name="api_job_detail"),
    path("jobs/<int:job_id>/save/", api.api_toggle_saved_job, name="api_toggle_saved_job"),
    path("hr/companies/", api.api_hr_companies, name="api_hr_companies"),
    path("hr/jobs/", api.api_create_job, name="api_create_job"),

    path("applications/", api.api_applications, name="api_applications"),
    path("applications/apply/", api.api_apply_job, name="api_apply_job"),
    path("candidate/applications/", api.api_my_applications, name="api_candidate_applications"),
    path("applications/mine/", api.api_my_applications, name="api_my_applications_alias"),

    path("hr/applications/", api.api_hr_applications, name="api_hr_applications"),
    path("hr/applications/<int:app_id>/", api.api_update_application_status, name="api_update_application_status_flutter"),
    path("hr/applications/<int:app_id>/status/", api.api_update_application_status, name="api_update_application_status"),
    path("hr/applications/<int:app_id>/hire/", api.api_mark_hired, name="api_mark_hired"),
]
