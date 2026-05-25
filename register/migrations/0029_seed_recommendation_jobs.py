from datetime import date, timedelta

from django.db import migrations


def seed_recommendation_jobs(apps, schema_editor):
    Job = apps.get_model("register", "Job")
    if Job.objects.exists():
        return

    Employee = apps.get_model("register", "Employee")
    User = apps.get_model("register", "user_detail")

    hr, _ = User.objects.get_or_create(
        Email="jobs@jrsystem.local",
        defaults={
            "full_name": "JR Jobs Team",
            "phoneno": "0000000000",
            "course": "Recruitment",
            "cv_url": "",
            "profile_url": "",
            "user_pass": "jobs123",
            "role": "hr",
            "skills": "",
        },
    )

    company_names = [
        "Nexa Digital",
        "Cloudmint Labs",
        "PixelWorks Studio",
        "InsightGrid",
        "AppNest",
        "ServerCraft",
        "DesignGrid",
        "DataForge",
        "ProductLane",
        "MarketPulse",
    ]
    companies = {}
    for name in company_names:
        company, _ = Employee.objects.get_or_create(
            company_name=name,
            defaults={
                "email": f"{name.lower().replace(' ', '')}@example.com",
                "website": "",
                "location": "Kochi",
            },
        )
        companies[name] = company

    today = date.today()
    job_specs = [
        ("Flutter Developer Intern", "Nexa Digital", "Flutter", "Kochi", "Flutter, Dart, REST API", "Build production Flutter screens and integrate APIs."),
        ("Junior Flutter App Developer", "AppNest", "Flutter", "Remote", "Flutter, Dart, Firebase", "Develop app features, state management flows, and Firebase modules."),
        ("Mobile UI Engineer", "PixelWorks Studio", "Flutter", "Calicut", "Flutter, UI/UX, Firebase", "Create polished mobile experiences for product teams."),
        ("Python Developer Trainee", "Cloudmint Labs", "Python", "Calicut", "Python, Django, REST API", "Build backend APIs for recruitment automation."),
        ("Python API Intern", "ServerCraft", "Python", "Kochi", "Python, FastAPI, SQL", "Create API endpoints and maintain service integrations."),
        ("Backend Automation Associate", "Cloudmint Labs", "Python", "Remote", "Python, Flask, PostgreSQL", "Automate backend workflows and reporting tasks."),
        ("Data Analyst Trainee", "InsightGrid", "Data Science", "Kochi", "Python, SQL, Power BI, Data Analysis", "Analyze hiring data and create business dashboards."),
        ("Machine Learning Intern", "DataForge", "Data Science", "Remote", "Python, Machine Learning, Pandas, Numpy", "Train models and prepare data pipelines for product analytics."),
        ("Computer Vision Trainee", "DataForge", "Data Science", "Kochi", "Python, OpenCV, Tensorflow, Deep Learning", "Work on image-processing and model-evaluation tasks."),
        ("UI/UX Designer Intern", "DesignGrid", "UI/UX", "Calicut", "UI/UX, Figma, Wireframing", "Create product flows, wireframes, and interface mockups."),
        ("Product Design Trainee", "ProductLane", "UI/UX", "Remote", "Figma, Prototyping, User Research", "Design usable product screens and test interaction flows."),
        ("UX Research Assistant", "DesignGrid", "UI/UX", "Kochi", "UI/UX, User Research, Communication", "Run user interviews and translate findings into design improvements."),
        ("Digital Marketing Associate", "MarketPulse", "Marketing", "Remote", "SEO, Content Writing, Analytics", "Create campaign content and track performance metrics."),
        ("HR Operations Intern", "ProductLane", "Human Resources", "Thrissur", "Recruitment, Communication, MS Excel", "Support candidate screening, scheduling, and HR records."),
    ]

    jobs = []
    for index, (title, company, department, location, skills, description) in enumerate(job_specs, start=1):
        jobs.append(
            Job(
                job_title=title,
                company_id=companies[company],
                hr_id=hr,
                location=location,
                department=department,
                duration="0-1 years",
                stipend="12000/month",
                deadline=today + timedelta(days=30 + index),
                skills=skills,
                description=description,
                status="open",
            )
        )
    Job.objects.bulk_create(jobs)


def unseed_recommendation_jobs(apps, schema_editor):
    Job = apps.get_model("register", "Job")
    Job.objects.filter(hr_id__Email="jobs@jrsystem.local").delete()


class Migration(migrations.Migration):
    dependencies = [
        ("register", "0028_merge_job_department_savedjob"),
    ]

    operations = [
        migrations.RunPython(seed_recommendation_jobs, unseed_recommendation_jobs),
    ]
