import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from .views import exam_start, api_run, api_submit
from register.models import application


def _serialize_start(request, job_id, user_id):
    try:
        app_obj = application.objects.get(job_id=job_id, user_id=user_id)
    except application.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Application not found.'}, status=404)
    request.session['app_id'] = app_obj.id
    request.session['exam_job_id'] = job_id
    request.session['exam_user_id'] = user_id
    request.session['solved_count'] = 0
    request.session['solved_problems'] = []
    request.session.modified = True
    return JsonResponse({'success': True, 'title': 'Machine Test', 'duration_minutes': 30, 'total_questions': 3})


def api_start_exam(request, job_id, user_id):
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'GET required.'}, status=405)
    return _serialize_start(request, job_id, user_id)


@csrf_exempt
def api_run_code(request):
    return api_run(request)


@csrf_exempt
@require_POST
def api_submit_problem(request, problem_id):
    return api_submit(request, problem_id)
