import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.shortcuts import get_object_or_404
from register.models import application, user_detail
from register import api as register_api
from django.core.files.base import ContentFile


def get_api_user(request):
    return register_api.authenticate_token(request)


def api_room_info(request, room_id):
    user = get_api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    app_obj = get_object_or_404(application, interview_room_id=room_id)
    is_hr = user.role == 'hr'
    is_candidate = app_obj.user_id.id == user.id
    if not (is_hr or is_candidate):
        return JsonResponse({'success': False, 'message': 'Not authorized.'}, status=403)
    return JsonResponse({
        'room_id': str(room_id),
        'is_hr': is_hr,
        'role': 'hr' if is_hr else 'candidate',
        'my_name': user.full_name,
        'candidate': {
            'id': app_obj.user_id.id,
            'full_name': app_obj.user_id.full_name,
            'email': app_obj.user_id.Email,
        },
        'hr_user': {
            'id': app_obj.job_id.hr_id.id,
            'full_name': app_obj.job_id.hr_id.full_name,
            'email': app_obj.job_id.hr_id.Email,
        },
        'job_title': app_obj.job_id.job_title,
        'room_notes': app_obj.interview_feedback or '',
    })


@csrf_exempt
@require_POST
def api_end_room(request, room_id):
    user = get_api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    if user.role != 'hr':
        return JsonResponse({'success': False, 'message': 'HR role required.'}, status=403)
    app_obj = get_object_or_404(application, interview_room_id=room_id)
    data = json.loads(request.body or '{}')
    app_obj.status = 'interview_completed'
    app_obj.interview_result = data.get('result', app_obj.interview_result)
    app_obj.interview_feedback = data.get('feedback', app_obj.interview_feedback)
    app_obj.save()
    return JsonResponse({'success': True})


@csrf_exempt
@require_POST
def api_save_notes(request, room_id):
    user = get_api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    if user.role != 'hr':
        return JsonResponse({'success': False, 'message': 'HR role required.'}, status=403)
    app_obj = get_object_or_404(application, interview_room_id=room_id)
    data = json.loads(request.body or '{}')
    app_obj.interview_feedback = data.get('notes', app_obj.interview_feedback)
    app_obj.save()
    return JsonResponse({'success': True})


@csrf_exempt
@require_POST
def api_save_audio(request, room_id):
    user = get_api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    if user.role != 'hr':
        return JsonResponse({'success': False, 'message': 'HR role required.'}, status=403)
    app_obj = get_object_or_404(application, interview_room_id=room_id)
    audio_file = request.FILES.get('audio')
    if not audio_file:
        return JsonResponse({'success': False, 'message': 'Audio file missing.'}, status=400)
    app_obj.interview_recording.save(f'recording_{room_id}.webm', ContentFile(audio_file.read()), save=True)
    return JsonResponse({'success': True})
