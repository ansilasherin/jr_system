from django.urls import path
from . import api

urlpatterns = [
    path('room/<uuid:room_id>/', api.api_room_info, name='api_interview_room'),
    path('end/<uuid:room_id>/', api.api_end_room, name='api_interview_end'),
    path('notes/<uuid:room_id>/', api.api_save_notes, name='api_interview_notes'),
    path('save-audio/<uuid:room_id>/', api.api_save_audio, name='api_interview_save_audio'),
]
