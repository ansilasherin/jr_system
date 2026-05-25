from django.urls import path
from . import api

urlpatterns = [
    path('start/<int:job_id>/<int:user_id>/', api.api_start_exam, name='api_mtest_start'),
    path('run/', api.api_run_code, name='api_mtest_run'),
    path('submit/<int:problem_id>/', api.api_submit_problem, name='api_mtest_submit'),
]
