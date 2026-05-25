from django.db import migrations


DEPARTMENT_ALIASES = {
    "flutter": "Flutter",
    "flutter development": "Flutter",
    "mobile development": "Flutter",
    "python": "Python",
    "python development": "Python",
    "backend": "Python",
    "django": "Python",
    "ui/ux": "UI/UX",
    "ui ux": "UI/UX",
    "ux": "UI/UX",
    "ui": "UI/UX",
    "design": "UI/UX",
    "data science": "Data Science",
    "data analytics": "Data Science",
    "machine learning": "Data Science",
    "marketing": "Marketing",
    "digital marketing": "Marketing",
    "human resources": "Human Resources",
    "hr": "Human Resources",
    "recruitment": "Human Resources",
}


def _resolve_department(value):
    raw = (value or "").strip()
    if not raw:
        return ""
    lowered = raw.lower()
    if lowered in DEPARTMENT_ALIASES:
        return DEPARTMENT_ALIASES[lowered]
    for canonical in DEPARTMENT_ALIASES.values():
        if lowered == canonical.lower():
            return canonical
    for alias, canonical in DEPARTMENT_ALIASES.items():
        if alias in lowered or lowered in alias:
            return canonical
    return raw


def normalize_candidate_departments(apps, schema_editor):
    User = apps.get_model("register", "user_detail")
    for user in User.objects.filter(role="user").exclude(course=""):
        resolved = _resolve_department(user.course)
        if resolved and resolved != user.course:
            user.course = resolved
            user.save(update_fields=["course"])


class Migration(migrations.Migration):
    dependencies = [
        ("register", "0031_cleanup_generated_cv_names"),
    ]

    operations = [
        migrations.RunPython(normalize_candidate_departments, migrations.RunPython.noop),
    ]
