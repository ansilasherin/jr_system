import json
import re
import zipfile
from io import BytesIO
from xml.etree import ElementTree

import requests
from django.conf import settings

from .department_utils import resolve_department


SKILLS_LIST = [
    'python', 'java', 'javascript', 'c++', 'c#', 'php', 'ruby', 'swift',
    'kotlin', 'typescript', 'golang', 'rust', 'scala', 'r',
    'html', 'css', 'react', 'angular', 'vue', 'django', 'flask',
    'node.js', 'express', 'bootstrap', 'tailwind', 'rest api', 'graphql',
    'machine learning', 'deep learning', 'tensorflow', 'pytorch', 'keras',
    'pandas', 'numpy', 'scikit-learn', 'matplotlib', 'data analysis',
    'natural language processing', 'nlp', 'computer vision', 'opencv',
    'sql', 'mysql', 'postgresql', 'mongodb', 'sqlite', 'redis', 'firebase',
    'aws', 'azure', 'google cloud', 'docker', 'kubernetes', 'git', 'github',
    'linux', 'ci/cd', 'jenkins', 'excel', 'powerpoint', 'figma', 'photoshop',
    'tableau', 'power bi', 'agile', 'scrum', 'jira', 'communication', 'leadership',
    'teamwork',
]

TECHNOLOGY_SKILLS = {
    'python', 'java', 'javascript', 'c++', 'c#', 'php', 'ruby', 'swift',
    'kotlin', 'typescript', 'golang', 'rust', 'scala', 'r', 'html', 'css',
    'react', 'angular', 'vue', 'django', 'flask', 'node.js', 'express',
    'bootstrap', 'tailwind', 'rest api', 'graphql', 'machine learning',
    'deep learning', 'tensorflow', 'pytorch', 'keras', 'pandas', 'numpy',
    'scikit-learn', 'matplotlib', 'data analysis', 'nlp', 'computer vision',
    'opencv', 'sql', 'mysql', 'postgresql', 'mongodb', 'sqlite', 'redis',
    'firebase', 'aws', 'azure', 'google cloud', 'docker', 'kubernetes',
    'git', 'github', 'linux', 'ci/cd', 'jenkins', 'figma', 'photoshop',
    'tableau', 'power bi',
}

DEPARTMENT_KEYWORDS = {
    "Flutter": [
        "flutter", "dart", "firebase", "android", "ios", "mobile app",
        "mobile development",
    ],
    "Python": [
        "python", "django", "flask", "fastapi", "backend", "api",
        "rest api", "postgresql", "mysql",
    ],
    "UI/UX": [
        "ui/ux", "ui ux", "figma", "wireframe", "prototype",
        "user research", "photoshop", "illustrator",
    ],
    "Data Science": [
        "machine learning", "deep learning", "data science",
        "data analysis", "pandas", "numpy", "tensorflow", "pytorch",
        "nlp", "computer vision", "power bi", "tableau",
    ],
    "Marketing": [
        "seo", "sem", "digital marketing", "social media", "campaign",
        "google ads", "content marketing",
    ],
    "Human Resources": [
        "human resources", "hr", "recruitment", "talent acquisition",
        "employee engagement",
    ],
}

SKILL_NORMALIZATIONS = {
    "js": "JavaScript",
    "javascript": "JavaScript",
    "html5": "HTML",
    "html": "HTML",
    "css3": "CSS",
    "css": "CSS",
    "node": "Node.js",
    "nodejs": "Node.js",
    "node.js": "Node.js",
    "rest": "REST API",
    "rest api": "REST API",
    "api": "API",
    "nlp": "NLP",
    "natural language processing": "NLP",
    "opencv": "OpenCV",
    "sql": "SQL",
    "mysql": "MySQL",
    "postgresql": "PostgreSQL",
    "mongodb": "MongoDB",
    "sqlite": "SQLite",
    "aws": "AWS",
    "azure": "Azure",
    "google cloud": "Google Cloud",
    "ci/cd": "CI/CD",
    "github": "GitHub",
    "power bi": "Power BI",
    "c++": "C++",
    "c#": "C#",
    "r": "R",
}

SKILL_EXTRACTION_PROMPT = """You are a recruitment skill extraction assistant.

Task:
Analyze the candidate CV text and extract only job-relevant technical and professional skills.

Rules:
- Return only valid JSON.
- Do not include explanations.
- Extract skills explicitly mentioned or strongly implied by projects, education, tools, certifications, or experience.
- Normalize similar skills to common names. Example: "js" -> "JavaScript", "html5" -> "HTML".
- Avoid soft/generic words unless clearly useful for hiring. Example: avoid "hardworking", "punctual".
- Remove duplicates.
- Keep each skill short, maximum 3 words.
- If no skills are found, return an empty skills array.

Return format:
{"skills": ["Flutter", "Dart", "Firebase", "REST API"], "department": "Flutter", "experience": "1 year"}
"""


def _extract_text_from_cv(cv_file):
    cv_bytes = cv_file.read()
    cv_file.seek(0)
    name = (getattr(cv_file, "name", "") or "").lower()

    if name.endswith(".docx"):
        return _extract_text_from_docx(cv_bytes)

    if name.endswith(".txt"):
        return cv_bytes.decode("utf-8", errors="ignore")

    if name.endswith(".pdf") or not name.endswith(".doc"):
        import fitz

        doc = fitz.open(stream=cv_bytes, filetype="pdf")
        try:
            return "\n".join(page.get_text() for page in doc)
        finally:
            doc.close()

    return cv_bytes.decode("utf-8", errors="ignore")


def _extract_text_from_docx(docx_bytes):
    try:
        with zipfile.ZipFile(BytesIO(docx_bytes)) as archive:
            xml = archive.read("word/document.xml")
    except Exception:
        return ""

    root = ElementTree.fromstring(xml)
    texts = []
    for node in root.iter():
        if node.tag.endswith("}t") and node.text:
            texts.append(node.text)
    return " ".join(texts)


def _normalize_skill(skill):
    cleaned = re.sub(r"\s+", " ", str(skill or "").strip())
    cleaned = cleaned.strip(".,;:|/-")
    if not cleaned:
        return ""

    if len(cleaned.split()) > 3:
        return ""

    return SKILL_NORMALIZATIONS.get(cleaned.lower(), cleaned.title())


def _dedupe_skills(skills):
    unique = []
    seen = set()
    for skill in skills:
        normalized = _normalize_skill(skill)
        if not normalized:
            continue
        key = normalized.lower()
        if key not in seen:
            seen.add(key)
            unique.append(normalized)
    return unique


def _fallback_extract_skills(cv_text):
    normalized_text = " ".join(cv_text.lower().replace("\n", " ").split())
    found_skills = []

    for skill in SKILLS_LIST:
        pattern = r"(?<![\w+#.])" + re.escape(skill.lower()) + r"(?![\w+#.])"
        if re.search(pattern, normalized_text):
            found_skills.append(skill)

    return _dedupe_skills(found_skills)


def _skills_from_ai_response(raw_text):
    if not raw_text:
        return []

    raw_text = raw_text.strip()
    if raw_text.startswith("```"):
        raw_text = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw_text, flags=re.IGNORECASE)

    try:
        payload = json.loads(raw_text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", raw_text, flags=re.DOTALL)
        if not match:
            return []
        try:
            payload = json.loads(match.group(0))
        except json.JSONDecodeError:
            return []

    skills = payload.get("skills", []) if isinstance(payload, dict) else []
    return _dedupe_skills(skills if isinstance(skills, list) else [])


def _analysis_from_ai_response(raw_text):
    skills = _skills_from_ai_response(raw_text)
    department = ""
    experience = ""

    if raw_text:
        cleaned = raw_text.strip()
        if cleaned.startswith("```"):
            cleaned = re.sub(r"^```(?:json)?\s*|\s*```$", "", cleaned, flags=re.IGNORECASE)
        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", cleaned, flags=re.DOTALL)
            try:
                payload = json.loads(match.group(0)) if match else {}
            except json.JSONDecodeError:
                payload = {}
        if isinstance(payload, dict):
            department = resolve_department(payload.get("department")) or ""
            experience = str(payload.get("experience") or "").strip()

    return {
        "skills": skills,
        "technologies": _technology_list(skills),
        "department": department,
        "experience": experience,
    }


def _extract_skills_with_openai(cv_text):
    api_key = getattr(settings, "OPENAI_API_KEY", "")
    if not api_key:
        return []

    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "model": getattr(settings, "CV_SKILL_OPENAI_MODEL", "gpt-4o-mini"),
            "messages": [
                {"role": "system", "content": SKILL_EXTRACTION_PROMPT},
                {"role": "user", "content": f'CV text:\n"""\n{cv_text[:12000]}\n"""'},
            ],
            "temperature": 0,
            "response_format": {"type": "json_object"},
        },
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    content = data["choices"][0]["message"]["content"]
    return _analysis_from_ai_response(content)


def _extract_skills_with_groq(cv_text):
    api_key = getattr(settings, "GROQ_API_KEY", "")
    if not api_key:
        return []

    response = requests.post(
        "https://api.groq.com/openai/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "model": getattr(settings, "CV_SKILL_GROQ_MODEL", "llama-3.3-70b-versatile"),
            "messages": [
                {"role": "system", "content": SKILL_EXTRACTION_PROMPT},
                {"role": "user", "content": f'CV text:\n"""\n{cv_text[:12000]}\n"""'},
            ],
            "temperature": 0,
            "response_format": {"type": "json_object"},
        },
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    content = data["choices"][0]["message"]["content"]
    return _analysis_from_ai_response(content)


def _extract_skills_with_ai(cv_text):
    provider = getattr(settings, "CV_SKILL_AI_PROVIDER", "auto").lower()
    providers = ["openai", "groq"] if provider == "auto" else [provider]

    for selected_provider in providers:
        try:
            if selected_provider == "openai":
                analysis = _extract_skills_with_openai(cv_text)
            elif selected_provider == "groq":
                analysis = _extract_skills_with_groq(cv_text)
            else:
                analysis = {}
            if analysis.get("skills"):
                return analysis
        except Exception as exc:
            print(f"AI skill extraction error ({selected_provider}): {exc}")
    return {}


def _technology_list(skills):
    technologies = []
    seen = set()
    for skill in skills:
        key = str(skill).strip().lower()
        if key in TECHNOLOGY_SKILLS and key not in seen:
            seen.add(key)
            technologies.append(skill)
    return technologies


def _infer_department(cv_text, skills):
    text = " ".join(cv_text.lower().replace("\n", " ").split())
    skill_text = " ".join(str(skill).lower() for skill in skills)
    haystack = f"{text} {skill_text}"
    best_department = ""
    best_score = 0

    for department, keywords in DEPARTMENT_KEYWORDS.items():
        score = sum(1 for keyword in keywords if keyword in haystack)
        if score > best_score:
            best_score = score
            best_department = department

    return best_department


def _infer_experience(cv_text):
    patterns = [
        r"(\d+(?:\.\d+)?)\+?\s*(?:years|year|yrs|yr)\s+(?:of\s+)?experience",
        r"experience\s*(?:of|:)?\s*(\d+(?:\.\d+)?)\+?\s*(?:years|year|yrs|yr)",
    ]
    for pattern in patterns:
        match = re.search(pattern, cv_text, flags=re.IGNORECASE)
        if match:
            value = match.group(1)
            suffix = "year" if value == "1" else "years"
            return f"{value} {suffix}"
    return ""


def analyze_cv(cv_file):
    try:
        full_text = _extract_text_from_cv(cv_file)
        ai_analysis = _extract_skills_with_ai(full_text)
        skills = ai_analysis.get("skills") or _fallback_extract_skills(full_text)
        department = (
            resolve_department(ai_analysis.get("department"))
            or _infer_department(full_text, skills)
        )
        experience = ai_analysis.get("experience") or _infer_experience(full_text)
        technologies = ai_analysis.get("technologies") or _technology_list(skills)
        return {
            "skills": skills,
            "technologies": technologies,
            "department": department,
            "experience": experience,
        }
    except Exception as e:
        print(f"CV analysis error: {e}")
        return {
            "skills": [],
            "technologies": [],
            "department": "",
            "experience": "",
        }


def extract_skills_from_cv(cv_file):
    return ", ".join(analyze_cv(cv_file)["skills"])
