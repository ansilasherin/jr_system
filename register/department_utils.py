from django.db.models import Q

from .models import Job


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


def resolve_department(value):
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


def department_filter_q(department):
    canonical = resolve_department(department)
    if not canonical:
        return Q()
    return Q(department__iexact=canonical)


def department_matches(value, job):
    canonical = resolve_department(value)
    if not canonical:
        return False
    job_department = (job.department or "").strip().lower()
    return job_department == canonical.lower()


def filter_open_jobs_by_department(department, limit=None):
    canonical = resolve_department(department)
    if not canonical:
        return []
    queryset = (
        Job.objects.filter(status="open")
        .filter(department_filter_q(canonical))
        .select_related("company_id", "hr_id")
        .order_by("-created_at")
    )
    if limit:
        return list(queryset[:limit])
    return list(queryset)


def skill_overlap_score(candidate_skills, job_skills):
    def _skill_list(skills):
        if not skills:
            return []
        if isinstance(skills, list):
            return [str(skill).strip() for skill in skills if str(skill).strip()]
        return [s.strip() for s in str(skills).split(",") if s.strip()]

    user_skills = set(s.strip().lower() for s in _skill_list(candidate_skills))
    required_skills = set(s.strip().lower() for s in _skill_list(job_skills))
    if not user_skills or not required_skills:
        return 0
    common = user_skills & required_skills
    return int((len(common) / len(required_skills)) * 100)


def match_score(candidate_skills, job_skills):
    def _skill_list(skills):
        if not skills:
            return []
        if isinstance(skills, list):
            return [str(skill).strip() for skill in skills if str(skill).strip()]
        return [s.strip() for s in str(skills).split(",") if s.strip()]

    user_skills = set(s.strip().lower() for s in _skill_list(candidate_skills))
    required_skills = set(s.strip().lower() for s in _skill_list(job_skills))
    if not required_skills:
        return 0
    common = user_skills & required_skills
    return int((len(common) / len(required_skills)) * 100)


def sort_jobs_for_candidate(jobs, department, candidate_skills):
    canonical = resolve_department(department)
    return sorted(
        jobs,
        key=lambda item: (
            1 if department_matches(canonical, item) else 0,
            skill_overlap_score(candidate_skills, item.skills),
            match_score(candidate_skills, item.skills),
        ),
        reverse=True,
    )
