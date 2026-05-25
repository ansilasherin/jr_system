from django.urls import path
from . import api

urlpatterns = [
    path('applications/<int:application_id>/questions/', api.api_application_questions, name='api_application_questions'),
    path('applications/<int:application_id>/submit/', api.api_application_submit, name='api_application_submit'),
    path('start/<int:job_id>/<int:user_id>/', api.api_start_exam, name='api_mqc_start'),
    path('questions/', api.api_exam_questions, name='api_mqc_questions'),
    path('submit/', api.api_submit_exam, name='api_mqc_submit'),
]
