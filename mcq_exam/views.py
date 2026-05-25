import json
import random
from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from register.models import application

MCQ_TEST = {
    "title": "Internship Screening Test",
    "duration": 20,
    "questions": [
        {"id":1,"question":"Which language is used in Django?","options":["Java","Python","C++","PHP"],"answer":"Python"},
        {"id":2,"question":"Which Git command saves changes?","options":["git save","git commit","git store","git update"],"answer":"git commit"},
        {"id":3,"question":"Which database is best with Django?","options":["Oracle","PostgreSQL","Excel","Firebase"],"answer":"PostgreSQL"},
        {"id":4,"question":"Which symbol is used for comments in Python?","options":["//","#","!--","**"],"answer":"#"},
        {"id":5,"question":"CSS stands for?","options":["Color Style Sheets","Cascading Style Sheets","Computer Style Sheets","Creative Style Sheets"],"answer":"Cascading Style Sheets"},
        {"id":6,"question":"Which is frontend language?","options":["Python","Java","HTML","Django"],"answer":"HTML"},
        {"id":7,"question":"JS stands for?","options":["JavaScript","JavaSource","JustScript","None"],"answer":"JavaScript"},
        {"id":8,"question":"Which is Python framework?","options":["React","Laravel","Django","Bootstrap"],"answer":"Django"},
        {"id":9,"question":"Which method adds item to list?","options":["add()","append()","push()","insert()"],"answer":"append()"},
        {"id":10,"question":"Which is not a data type?","options":["int","float","char","banana"],"answer":"banana"},
        {"id":11,"question":"Which HTML tag is used for image?","options":["img","pic","src","image"],"answer":"img"},
        {"id":12,"question":"Which is CSS framework?","options":["Django","Bootstrap","Flask","Node"],"answer":"Bootstrap"},
        {"id":13,"question":"SQL used for?","options":["Styling","Database","AI","Design"],"answer":"Database"},
        {"id":14,"question":"Which keyword for function in Python?","options":["func","def","function","create"],"answer":"def"},
        {"id":15,"question":"Which loop in Python?","options":["for","loop","repeat","iterate"],"answer":"for"},
        {"id":16,"question":"Which operator is exponent?","options":["^","**","//","%%"],"answer":"**"},
        {"id":17,"question":"Which is backend language?","options":["Python","CSS","HTML","Figma"],"answer":"Python"},
        {"id":18,"question":"Which HTTP method sends data?","options":["GET","POST","PUT","Both POST & PUT"],"answer":"Both POST & PUT"},
        {"id":19,"question":"Which tag creates table?","options":["table","tb","tab","tr"],"answer":"table"},
        {"id":20,"question":"Which joins tables in SQL?","options":["MERGE","JOIN","LINK","CONNECT"],"answer":"JOIN"},
        {"id":21,"question":"Which is JS library?","options":["React","Django","Flask","MySQL"],"answer":"React"},
        {"id":22,"question":"Which tag creates input field?","options":["input","form","field","text"],"answer":"input"},
        {"id":23,"question":"Which method removes list item?","options":["delete()","remove()","pop()","Both remove() & pop()"],"answer":"Both remove() & pop()"},
        {"id":24,"question":"Which is version control?","options":["Git","Excel","Chrome","Word"],"answer":"Git"},
        {"id":25,"question":"Which command pushes code?","options":["git push","git add","git commit","git init"],"answer":"git push"},
        {"id":26,"question":"Which HTML tag is used for paragraph?","options":["p","para","text","pg"],"answer":"p"},
        {"id":27,"question":"Which CSS property changes color?","options":["bgcolor","color","fontcolor","textcolor"],"answer":"color"},
        {"id":28,"question":"Which DB query fetches data?","options":["SELECT","INSERT","DELETE","UPDATE"],"answer":"SELECT"},
        {"id":29,"question":"Which loop repeats forever?","options":["while True","for loop","repeat","loop"],"answer":"while True"},
        {"id":30,"question":"Which Python structure stores key-value?","options":["List","Tuple","Dictionary","Set"],"answer":"Dictionary"},
        {"id":31,"question":"Which Python keyword is used for conditional statements?","options":["if","when","case","switch"],"answer":"if"},
        {"id":32,"question":"Which HTML tag creates an unordered list?","options":["ol","ul","li","list"],"answer":"ul"},
        {"id":33,"question":"Which CSS property adds space inside element?","options":["margin","padding","border","spacing"],"answer":"padding"},
        {"id":34,"question":"Which SQL keyword inserts data?","options":["PUT","INSERT","ADD","IN"],"answer":"INSERT"},
        {"id":35,"question":"Which Python data type is immutable?","options":["List","Dictionary","Set","Tuple"],"answer":"Tuple"},
        {"id":36,"question":"Which HTML tag defines heading?","options":["h1","head","title","heading"],"answer":"h1"},
        {"id":37,"question":"Which CSS property sets background color?","options":["bgcolor","background-color","color","bg-style"],"answer":"background-color"},
        {"id":38,"question":"Which Python function returns length?","options":["count()","size()","len()","length()"],"answer":"len()"},	
        {"id":39,"question":"Which SQL command removes data?","options":["DELETE","REMOVE","DROP","CLEAR"],"answer":"DELETE"},
        {"id":40,"question":"Which tag defines table row?","options":["td","tr","th","row"],"answer":"tr"},
        {"id":41,"question":"Which Python loop iterates sequence?","options":["for","while","repeat","iterate"],"answer":"for"},
        {"id":42,"question":"Which symbol denotes ID in CSS?","options":[".","#","$","@"],"answer":"#"},
        {"id":43,"question":"Which JavaScript runs in browser?","options":["Server JS","Node JS","Client JS","Django"],"answer":"Client JS"},
        {"id":44,"question":"Which Python keyword stops loop?","options":["exit","break","stop","end"],"answer":"break"},
        {"id":45,"question":"Which SQL clause groups rows?","options":["GROUP BY","ORDER BY","SORT BY","JOIN"],"answer":"GROUP BY"},
        {"id":46,"question":"Which HTML tag creates line break?","options":["lb","br","break","line"],"answer":"<br>"},
        {"id":47,"question":"Which operator divides in Python?","options":["/","//","%","All"],"answer":"All"},
        {"id":48,"question":"Which Python structure allows duplicates?","options":["Set","List","Dictionary","Tuple"],"answer":"List"},
        {"id":49,"question":"Which Django pattern used?","options":["MVC","MVT","MVVM","None"],"answer":"MVT"},   
        {"id":50,"question":"What is output of: print(2 + 3 * 4)?","options":["20","14","24","10"],"answer":"14"},
        {"id":51,"question":"What is output of: print(len('Python'))?","options":["5","6","7","Error"],"answer":"6"},
        {"id":52,"question":"What is output of: print(10 // 3)?","options":["3.3","3","4","1"],"answer":"3"},
        {"id":53,"question":"What is output of: print(2 ** 3)?","options":["6","8","9","5"],"answer":"8"},
        {"id":54,"question":"What is output of: print('Hello' + 'World')?","options":["Hello World","HelloWorld","Error","Hello+World"],"answer":"HelloWorld"},
        {"id":55,"question":"What is output of: print(type(5))?","options":["int","float","str","number"],"answer":"int"},
        {"id":56,"question":"What is output of: print(bool(0))?","options":["True","False","0","Error"],"answer":"False"},
        {"id":57,"question":"What is output of: print(5 % 2)?","options":["1","2","2.5","0"],"answer":"1"},
        {"id":58,"question":"What is output of: print([1,2,3][1])?","options":["1","2","3","Error"],"answer":"2"},
        {"id":59,"question":"What is output of: print('Python'[0])?","options":["P","p","0","Error"],"answer":"P"},
    ]
}


def start_exam(request, job_id, user_id):
    try:
        app_obj = application.objects.get(job_id=job_id, user_id=user_id)
    except application.DoesNotExist:
        return render(request, "exam_locked.html", {
            "title": "MCQ Not Available",
            "message": "No application was found for this job.",
        })

    if app_obj.status != "approved":
        return render(request, "exam_locked.html", {
            "title": "MCQ Locked",
            "message": "MCQ will be available only after HR approves your application.",
        })

    if app_obj.mcq_score is not None:
        return render(request, "exam_locked.html", {
            "title": "MCQ Completed",
            "message": "You have already completed the MCQ for this application.",
        })

    request.session["app_id"] = app_obj.id
    request.session.modified = True
    return render(request, "exam_start.html", {"title": MCQ_TEST["title"]})

def exam_view(request):
    app_id = request.session.get("app_id")
    if not app_id:
        return render(request, "exam_locked.html", {
            "title": "MCQ Not Available",
            "message": "Start the MCQ from an approved application first.",
        })
    if not application.objects.filter(id=app_id, status="approved", mcq_score__isnull=True).exists():
        return render(request, "exam_locked.html", {
            "title": "MCQ Locked",
            "message": "MCQ is available only after HR approval and before submission.",
        })

    """Main exam page with randomized questions."""
    all_questions = MCQ_TEST["questions"].copy()
    random.shuffle(all_questions)
    selected = all_questions[:20]

    # Store correct answers in session
    answers = {str(q["id"]): q["answer"] for q in selected}
    request.session["answers"] = answers
    request.session["total"] = len(selected)

    # Prepare questions for template (without answer)
    questions_for_template = []
    for i, q in enumerate(selected):
        questions_for_template.append({
            "num": i + 1,
            "id": q["id"],
            "question": q["question"],
            "options": q["options"],
        })

    context = {
        "questions": json.dumps(questions_for_template),
        "duration": MCQ_TEST["duration"] * 60,
        "title": MCQ_TEST["title"],
    }
    return render(request, 'exam.html', context)

@csrf_exempt
def submit_exam(request):
    """Handle exam submission and show results."""
    if request.method == "POST":
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        user_answers = data.get("answers", {})
        time_taken = data.get("time_taken", 0)

        correct_answers = request.session.get("answers", {})
        total = request.session.get("total", 20)

        if not correct_answers:
            return JsonResponse({"error": "Session expired. Please restart the exam."}, status=400)

        score = 0
        results = []
        for qid, correct in correct_answers.items():
            user_ans = user_answers.get(qid, None)
            is_correct = user_ans == correct
            if is_correct:
                score += 1
            results.append({
                "qid": qid,
                "correct": correct,
                "user": user_ans,
                "is_correct": is_correct,
            })

        percentage = round((score / total) * 100, 1)
        passed = percentage >= 60

        app_id = request.session.get('app_id')
        if app_id:
            try:
                app = application.objects.get(id=app_id)
                app.mcq_score = percentage
                app.save()
            except application.DoesNotExist:
                print(f"Application with id {app_id} does not exist.")
        
        
        mins = time_taken // 60
        secs = time_taken % 60

        return JsonResponse({
            "score": score,
            "total": total,
            "percentage": percentage,
            "passed": passed,
            "time_taken": f"{mins}m {secs}s",
            "results": results,
        })

    return JsonResponse({"error": "Invalid request"}, status=400)



    if request.method == "POST":
        data = json.loads(request.body)
        user_answers = data.get("answers", {})
        time_taken = data.get("time_taken", 0)

        correct_answers = request.session.get("answers", {})
        total = request.session.get("total", 20)

        score = 0
        results = []
        for qid, correct in correct_answers.items():
            user_ans = user_answers.get(qid, None)
            is_correct = user_ans == correct
            if is_correct:
                score += 1
            results.append({
                "qid": qid,
                "correct": correct,
                "user": user_ans,
                "is_correct": is_correct,
            })

        percentage = round((score / total) * 100, 1)
        passed = percentage >= 60

        mins = time_taken // 60
        secs = time_taken % 60

        return JsonResponse({
            "score": score,
            "total": total,
            "percentage": percentage,
            "passed": passed,
            "time_taken": f"{mins}m {secs}s",
            "results": results,
        })

    return JsonResponse({"error": "Invalid request"}, status=400)