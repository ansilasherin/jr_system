import json
import base64
import tempfile
import os
from channels.generic.websocket import AsyncWebsocketConsumer
from django.conf import settings


class InterviewConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        self.job_role = self.scope['url_route']['kwargs']['job_role']
        from groq import AsyncGroq
        self.client = AsyncGroq(api_key=settings.GROQ_API_KEY)
        self.audio_chunks = []
        self.conversation_history = []
        self.system_prompt = f"""You are a professional interviewer for a {self.job_role} position.
Greet the candidate warmly and ask your first interview question.
Ask one question at a time. Keep responses concise — this is a spoken conversation.
After 5-6 questions give a final performance summary."""
        await self.accept()
        await self.send(json.dumps({"type": "session.created"}))
        # Send opening greeting
        await self.get_ai_response("Hello, please start the interview.")
        print("[WS] Client connected")

    async def receive(self, text_data=None, bytes_data=None):
        data = json.loads(text_data)
        if data.get('type') == 'audio_chunk':
            self.audio_chunks.append(data['audio'])
        elif data.get('type') == 'speech_end':
            if self.audio_chunks:
                await self.transcribe_and_respond()
                self.audio_chunks = []

    async def transcribe_and_respond(self):
        try:
            audio_data = b''.join(base64.b64decode(c) for c in self.audio_chunks)
            print(f"[Audio] {len(audio_data)} bytes")

            with tempfile.NamedTemporaryFile(suffix='.webm', delete=False) as f:
                f.write(audio_data)
                temp_path = f.name

            with open(temp_path, 'rb') as f:
                transcription = await self.client.audio.transcriptions.create(
                    file=(os.path.basename(temp_path), f, 'audio/webm'),
                    model="whisper-large-v3",
                    language="en",
                )
            os.unlink(temp_path)

            user_text = transcription.text.strip()
            print(f"[User] {user_text}")

            if not user_text or user_text in ['.', '..', '...']:
                return

            await self.send(json.dumps({"type": "user_transcript", "text": user_text}))
            await self.get_ai_response(user_text)

        except Exception as e:
            print(f"[ERROR] {type(e).__name__}: {e}")
            await self.send(json.dumps({"type": "error", "message": str(e)}))

    async def get_ai_response(self, user_text):
        try:
            self.conversation_history.append({"role": "user", "content": user_text})
            await self.send(json.dumps({"type": "response.created"}))

            # Stream response word by word
            stream = await self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    *self.conversation_history
                ],
                max_tokens=150,
                stream=True,
            )

            full_text = ""
            sentence = ""
            sentence_endings = {'.', '!', '?'}

            async for chunk in stream:
                delta = chunk.choices[0].delta.content
                if delta:
                    full_text += delta
                    sentence += delta
                    # Send each complete sentence immediately for faster TTS
                    if any(sentence.rstrip().endswith(e) for e in sentence_endings):
                        await self.send(json.dumps({
                            "type": "ai_chunk",
                            "text": sentence.strip()
                        }))
                        sentence = ""

            # Send any remaining text
            if sentence.strip():
                await self.send(json.dumps({
                    "type": "ai_chunk",
                    "text": sentence.strip()
                }))

            # Save full response to history
            self.conversation_history.append({
                "role": "assistant",
                "content": full_text
            })

            await self.send(json.dumps({
                "type": "ai_response",
                "text": full_text
            }))
            await self.send(json.dumps({"type": "response.done"}))
            print(f"[AI] {full_text}")

        except Exception as e:
            print(f"[ERROR] {type(e).__name__}: {e}")
            await self.send(json.dumps({"type": "error", "message": str(e)}))

    async def disconnect(self, close_code):
        print("[WS] Disconnected")
