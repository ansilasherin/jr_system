import json
import random
from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from register.models import AutoLoginToken, application
from .views import MCQ_TEST


def _token_from_request(request):
    header = request.headers.get('Authorization', '')
    if header.lower().startswith('bearer '):
        return header.split(' ', 1)[1].strip()
    if header.lower().startswith('token '):
        return header.split(' ', 1)[1].strip()
    return None


def _api_user(request):
    token = _token_from_request(request)
    if not token:
        return None
    token_obj = AutoLoginToken.objects.select_related('user').filter(token=token).first()
    if not token_obj:
        return None
    if timezone.now() >= token_obj.expires_at:
        token_obj.delete()
        return None
    return token_obj.user


def _random_questions():
    all_questions = MCQ_TEST['questions'].copy()
    random.shuffle(all_questions)
    return all_questions[:20]


def _json_body(request):
    if not request.body:
        return {}
    try:
        return json.loads(request.body)
    except json.JSONDecodeError:
        return None


def _approved_candidate_application(request, application_id):
    user = _api_user(request)
    if not user:
        return None, JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    if user.role != 'user':
        return None, JsonResponse({'success': False, 'message': 'Candidate authorization required.'}, status=403)
    try:
        app_obj = application.objects.select_related('user_id', 'job_id').get(id=application_id, user_id=user)
    except application.DoesNotExist:
        return None, JsonResponse({'success': False, 'message': 'Application not found.'}, status=404)
    if app_obj.status != 'approved':
        return None, JsonResponse({'success': False, 'message': 'Application is not approved for MCQ.'}, status=403)
    if app_obj.mcq_score is not None:
        return None, JsonResponse({'success': False, 'message': 'MCQ has already been submitted for this application.'}, status=403)
    return app_obj, None


def _question_payload(question):
    return {
        'id': question['id'],
        'question': question['question'],
        'options': question['options'],
    }


@csrf_exempt
def api_application_questions(request, application_id):
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'GET required.'}, status=405)

    app_obj, error = _approved_candidate_application(request, application_id)
    if error:
        return error

    selected = _random_questions()
    request.session[f'mcq_answers_{app_obj.id}'] = {str(q['id']): q['answer'] for q in selected}
    request.session[f'mcq_total_{app_obj.id}'] = len(selected)
    request.session.modified = True
    return JsonResponse({
        'success': True,
        'questions': [_question_payload(q) for q in selected],
    })


@csrf_exempt
def api_application_submit(request, application_id):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'POST required.'}, status=405)

    app_obj, error = _approved_candidate_application(request, application_id)
    if error:
        return error

    data = _json_body(request)
    if data is None:
        return JsonResponse({'success': False, 'message': 'Invalid JSON.'}, status=400)

    submitted_answers = data.get('answers')
    if not isinstance(submitted_answers, list):
        return JsonResponse({'success': False, 'message': 'answers must be a list.'}, status=400)

    answer_key = request.session.get(f'mcq_answers_{app_obj.id}')
    if not answer_key:
        answer_key = {str(q['id']): q['answer'] for q in MCQ_TEST['questions']}

    total = request.session.get(f'mcq_total_{app_obj.id}') or len(submitted_answers) or 1
    correct = 0
    for item in submitted_answers:
        if not isinstance(item, dict):
            continue
        question_id = str(item.get('question_id'))
        if question_id in answer_key and item.get('answer') == answer_key[question_id]:
            correct += 1

    score = round((correct / total) * 100, 1)
    app_obj.mcq_score = score
    app_obj.status = 'mcq_completed'
    app_obj.mcq_date = timezone.now()
    app_obj.save(update_fields=['mcq_score', 'status', 'mcq_date'])

    from register.api import _application_payload

    return JsonResponse({
        'success': True,
        'application': _application_payload(app_obj),
    })


@csrf_exempt
def api_start_exam(request, job_id, user_id):
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'GET required.'}, status=405)
    user = _api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    if user.role != 'user' or user.id != user_id:
        return JsonResponse({'success': False, 'message': 'Candidate authorization required.'}, status=403)
    try:
        app_obj = application.objects.get(job_id=job_id, user_id=user_id, status='approved')
    except application.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Approved application not found.'}, status=404)
    request.session['app_id'] = app_obj.id
    request.session.modified = True
    return JsonResponse({'success': True, 'title': MCQ_TEST['title'], 'duration_seconds': MCQ_TEST['duration'] * 60})


@csrf_exempt
def api_exam_questions(request):
    if request.method != 'GET':
        return JsonResponse({'success': False, 'message': 'GET required.'}, status=405)
    user = _api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    app_id = request.session.get('app_id')
    if not app_id or not application.objects.filter(id=app_id, user_id=user, status='approved').exists():
        return JsonResponse({'success': False, 'message': 'Start an approved MCQ exam first.'}, status=400)
    selected = _random_questions()
    answers = {str(q['id']): q['answer'] for q in selected}
    request.session['answers'] = answers
    request.session['total'] = len(selected)
    request.session.modified = True
    questions = [
        {
            'id': q['id'],
            'question': q['question'],
            'options': q['options'],
        }
        for q in selected
    ]
    return JsonResponse({'success': True, 'questions': questions, 'duration_seconds': MCQ_TEST['duration'] * 60})


@csrf_exempt
def api_submit_exam(request):
    if request.method != 'POST':
        return JsonResponse({'success': False, 'message': 'POST required.'}, status=405)

    user = _api_user(request)
    if not user:
        return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'success': False, 'message': 'Invalid JSON.'}, status=400)
    user_answers = data.get('answers', {})
    time_taken = data.get('time_taken', 0)
    correct_answers = request.session.get('answers', {})
    total = request.session.get('total', 20)
    if not correct_answers:
        return JsonResponse({'success': False, 'message': 'Exam session expired.'}, status=400)
    score = 0
    results = []
    for qid, correct in correct_answers.items():
        user_ans = user_answers.get(qid)
        is_correct = user_ans == correct
        if is_correct:
            score += 1
        results.append({'qid': qid, 'correct': correct, 'user': user_ans, 'is_correct': is_correct})
    percentage = round((score / total) * 100, 1)
    passed = percentage >= 60
    app_id = request.session.get('app_id')
    if app_id:
        try:
            app = application.objects.get(id=app_id, user_id=user, status='approved')
            app.mcq_score = percentage
            app.status = 'mcq_completed'
            app.mcq_date = timezone.now()
            app.save(update_fields=['mcq_score', 'status', 'mcq_date'])
        except application.DoesNotExist:
            pass
    mins = time_taken // 60
    secs = time_taken % 60
    return JsonResponse({'success': True, 'score': score, 'total': total, 'percentage': percentage, 'passed': passed, 'time_taken': f'{mins}m {secs}s', 'results': results})
