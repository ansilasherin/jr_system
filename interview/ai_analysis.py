import os
import json
from dotenv import load_dotenv

load_dotenv()

whisper_model = None
GROQ_API_KEY = os.getenv('GROQ_API_KEY')
groq_client = None


def get_whisper_model():
    global whisper_model
    if whisper_model is None:
        from faster_whisper import WhisperModel
        whisper_model = WhisperModel("base", device="cpu", compute_type="int8")
    return whisper_model


def get_groq_client():
    global groq_client
    if not GROQ_API_KEY:
        return None
    if groq_client is None:
        from groq import Groq
        groq_client = Groq(api_key=GROQ_API_KEY)
    return groq_client

def transcribe_audio(audio_file_path):
    """Transcribe audio locally using faster-whisper (free)"""
    print(f"[AI] Transcribing: {audio_file_path}")
    segments, info = get_whisper_model().transcribe(audio_file_path)
    transcript = " ".join(segment.text for segment in segments)
    print(f"[AI] Transcript done: {transcript[:200]}")
    return transcript


def analyze_interview(transcript, job_title):
    """Analyze transcript using Groq (free)"""
    print(f"[AI] Analyzing interview for: {job_title}")

    prompt = f"""
You are an expert HR analyst. Analyze this interview transcript for a {job_title} position.

TRANSCRIPT:
{transcript}

Return a JSON object with exactly this structure:
{{
  "overall_score": <number 1-10>,
  "summary": "<2-3 sentence overall summary>",
  "strengths": ["<strength 1>", "<strength 2>", "<strength 3>"],
  "weaknesses": ["<weakness 1>", "<weakness 2>"],
  "communication_score": <number 1-10>,
  "technical_score": <number 1-10>,
  "confidence_score": <number 1-10>,
  "recommendation": "strongly_recommended" | "recommended" | "neutral" | "not_recommended",
  "key_quotes": ["<notable quote 1>", "<notable quote 2>"],
  "hiring_notes": "<detailed paragraph for hiring manager>"
}}

Return ONLY the JSON. No explanation. No markdown. No backticks.
"""

    client = get_groq_client()
    if not client:
        print("[AI] GROQ_API_KEY not configured. Returning fallback analysis.")
        return {
            "overall_score": 0,
            "summary": "Groq API key not configured. Analysis unavailable.",
            "strengths": [],
            "weaknesses": [],
            "communication_score": 0,
            "technical_score": 0,
            "confidence_score": 0,
            "recommendation": "neutral",
            "key_quotes": [],
            "hiring_notes": "AI interview analysis could not be generated because GROQ_API_KEY is missing.",
        }

    response = client.chat.completions.create(
        model = 'llama-3.3-70b-versatile',
        messages    = [{'role': 'user', 'content': prompt}],
        temperature = 0.3,
    )

    raw = response.choices[0].message.content.strip()
    print(f"[AI] Raw response: {raw[:300]}")

    # Strip markdown if model adds it
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    raw = raw.strip()

    result = json.loads(raw)
    print("[AI] Analysis done")
    return result
