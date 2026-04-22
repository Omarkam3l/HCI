"""
AI Demo App — Python Gradio Backend
Port: 7862
Tabs: Vision Assistant | Image Generation | AI Chat
APIs: Groq (Llama-4-Scout vision, Llama3-70b chat) + Pollinations.ai (image gen)
STT:  OpenAI Whisper (base model, local)
TTS:  pyttsx3 (Zira/female voice, 150 wpm)
"""

import gradio as gr
import pyttsx3
import whisper
import requests
import urllib.parse
import base64
from PIL import Image
from io import BytesIO

# ── API Configuration ────────────────────────────────────────────────────────
GROQ_API_KEY  = "YOUR_GROQ_API_KEY_HERE"   # https://console.groq.com (free)
GROQ_API_URL  = "https://api.groq.com/openai/v1/chat/completions"
CHAT_MODEL    = "llama3-70b-8192"
VISION_MODEL  = "meta-llama/llama-4-scout-17b-16e-instruct"


# ── Whisper (lazy-loaded on first use) ───────────────────────────────────────
_whisper_model = None

def _load_whisper():
    global _whisper_model
    if _whisper_model is None:
        print("Loading Whisper base model (first-time, may take a moment)...")
        _whisper_model = whisper.load_model("base")
        print("Whisper ready.")
    return _whisper_model

# ── Helpers ──────────────────────────────────────────────────────────────────
def _transcribe(audio_path: str) -> str:
    """Whisper STT: audio file → text."""
    if not audio_path:
        return ""
    try:
        result = _load_whisper().transcribe(audio_path)
        return result["text"].strip()
    except Exception as e:
        print(f"[Whisper] Error: {e}")
        return ""

def _tts(text: str) -> str | None:
    """pyttsx3 TTS: text → WAV file path (Zira/female voice, 150 wpm)."""
    if not text:
        return None
    try:
        path = "tts_output.wav"
        engine = pyttsx3.init()
        engine.setProperty("rate", 150)
        engine.setProperty("volume", 1.0)
        for voice in engine.getProperty("voices"):
            if "zira" in voice.name.lower() or "female" in voice.name.lower():
                engine.setProperty("voice", voice.id)
                break
        engine.save_to_file(text, path)
        engine.runAndWait()
        return path
    except Exception as e:
        print(f"[TTS] Error: {e}")
        return None

def _clean(text: str) -> str:
    """Strip markdown formatting from AI responses."""
    import re
    text = re.sub(r"<think>.*?</think>", "", text, flags=re.DOTALL)
    for token in ["**", "*", "###", "##", "#"]:
        text = text.replace(token, "")
    return text.strip()

def _groq_chat(messages: list, max_tokens: int = 2048) -> str:
    """POST to Groq chat completions endpoint."""
    try:
        r = requests.post(
            GROQ_API_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": CHAT_MODEL,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": max_tokens,
            },
            timeout=30,
        )
        if r.status_code != 200:
            return f"Error {r.status_code}: {r.text}"
        return r.json()["choices"][0]["message"]["content"]
    except Exception as e:
        return f"Error: {e}"

# ── Tab 1: Vision Assistant ──────────────────────────────────────────────────
def analyze_image(image, voice_question, text_question):
    """
    Pipeline: voice → Whisper → Groq vision (Llama-4-Scout) → pyttsx3 TTS
    Returns: (description_text, audio_file_path)
    """
    if image is None:
        return "Please upload an image or take a photo first.", None

    # Resolve question: voice > text > default
    question = _transcribe(voice_question) if voice_question else ""
    if not question:
        question = (text_question or "").strip()
    if not question:
        question = "Describe everything in this image in rich detail for someone who cannot see."

    try:
        # Resize to max 768×768 and encode as base64 JPEG
        img = image.convert("RGB")
        img.thumbnail((768, 768))
        buf = BytesIO()
        img.save(buf, format="JPEG", quality=80)
        b64 = base64.b64encode(buf.getvalue()).decode()

        r = requests.post(
            GROQ_API_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": VISION_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": (
                            "You are an accessibility assistant for blind and visually impaired people. "
                            "Describe images in rich, clear detail covering colors, shapes, objects, people, "
                            "text, emotions, and spatial layout. Write in plain sentences without any markdown."
                        ),
                    },
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": question},
                            {
                                "type": "image_url",
                                "image_url": {"url": f"data:image/jpeg;base64,{b64}"},
                            },
                        ],
                    },
                ],
                "max_tokens": 1024,
                "temperature": 0.5,
            },
            timeout=30,
        )

        if r.status_code != 200:
            return f"Error {r.status_code}: {r.text}", None

        answer = _clean(r.json()["choices"][0]["message"]["content"])
        return answer, _tts(answer)

    except Exception as e:
        return f"Error: {e}", None

# ── Tab 2: Image Generation ──────────────────────────────────────────────────
def generate_image(prompt: str):
    """
    Calls Pollinations.ai (free, no API key) to generate an image from a prompt.
    Returns: (PIL.Image | None, status_text)
    """
    if not prompt or not prompt.strip():
        return None, "Please enter a description."
    try:
        url = f"https://image.pollinations.ai/prompt/{urllib.parse.quote(prompt.strip())}"
        r = requests.get(url, timeout=60)
        if r.status_code == 200:
            img = Image.open(BytesIO(r.content))
            return img, f'Generated: "{prompt.strip()}"'
        return None, f"Error {r.status_code}: {r.text}"
    except Exception as e:
        return None, f"Error: {e}"

# ── Tab 3: AI Chat ───────────────────────────────────────────────────────────
def chat_respond(message: str, history: list):
    """
    Multi-turn chat with Groq Llama3-70b.
    gr.ChatInterface passes history as [{"role": ..., "content": ...}, ...]
    Returns the assistant reply string only (ChatInterface handles appending).
    """
    if not message or not message.strip():
        return ""

    api_messages = [
        {
            "role": "system",
            "content": (
                "You are a helpful AI assistant. Be friendly and conversational. "
                "Respond directly without showing your thinking process. "
                "Do not use markdown formatting."
            ),
        }
    ]

    for entry in (history or []):
        if isinstance(entry, dict):
            api_messages.append({"role": entry["role"], "content": entry["content"]})
        elif isinstance(entry, (list, tuple)) and len(entry) == 2:
            human, assistant = entry
            if human:
                api_messages.append({"role": "user", "content": str(human)})
            if assistant:
                api_messages.append({"role": "assistant", "content": str(assistant)})

    api_messages.append({"role": "user", "content": message.strip()})
    return _clean(_groq_chat(api_messages))

# ── Gradio UI ────────────────────────────────────────────────────────────────
with gr.Blocks(title="AI Demo App") as demo:
    gr.Markdown("# 🤖 AI Demo App\n**Vision Assistant** | **Image Generation** | **AI Chat**")

    with gr.Tabs():

        # ── Tab 1: Vision Assistant ──
        with gr.Tab("👁️ Vision Assistant"):
            gr.Markdown(
                "### Accessibility tool for visually impaired users\n"
                "Upload or capture an image, ask by voice or text, and receive a spoken description."
            )
            with gr.Row():
                with gr.Column(scale=1):
                    v_image = gr.Image(
                        sources=["upload", "webcam"],
                        type="pil",
                        label="Image (upload or webcam)",
                    )
                    v_voice = gr.Audio(
                        sources=["microphone"],
                        type="filepath",
                        label="Ask by Voice (Whisper STT)",
                    )
                    v_text = gr.Textbox(
                        placeholder="Or type your question here...",
                        label="Question (text fallback)",
                        lines=2,
                    )
                    v_btn = gr.Button("🔍 Analyze Image", variant="primary")
                with gr.Column(scale=1):
                    v_out = gr.Textbox(label="Description", lines=14)
                    v_audio = gr.Audio(
                        label="Voice Answer (pyttsx3 TTS)",
                        autoplay=True,
                    )
            v_btn.click(
                fn=analyze_image,
                inputs=[v_image, v_voice, v_text],
                outputs=[v_out, v_audio],
            )

        # ── Tab 2: Image Generation ──
        with gr.Tab("🎨 Image Generation"):
            gr.Markdown(
                "### Generate images from text\n"
                "Powered by [Pollinations.ai](https://pollinations.ai) — free, no API key required."
            )
            with gr.Row():
                with gr.Column(scale=1):
                    ig_prompt = gr.Textbox(
                        placeholder="A cat wearing a crown on a golden throne...",
                        label="Image Description",
                        lines=3,
                    )
                    ig_btn = gr.Button("✨ Generate Image", variant="primary")
                with gr.Column(scale=1):
                    ig_image = gr.Image(label="Generated Image", type="pil")
                    ig_status = gr.Textbox(label="Status", lines=2)
            ig_btn.click(
                fn=generate_image,
                inputs=[ig_prompt],
                outputs=[ig_image, ig_status],
            )

        # ── Tab 3: AI Chat ──
        with gr.Tab("💬 AI Chat"):
            gr.Markdown(
                "### Conversational AI\n"
                "Powered by Groq `llama3-70b-8192` — fast inference, multi-turn memory."
            )
            gr.ChatInterface(
                fn=chat_respond,
                chatbot=gr.Chatbot(height=450, label="Conversation"),
                textbox=gr.Textbox(
                    placeholder="Type a message...",
                    label="Your Message",
                    lines=2,
                ),
            )

# ── Entry Point ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("AI Demo App — Gradio Backend")
    print("URL: http://localhost:7862")
    print("=" * 50)
    demo.launch(server_name="0.0.0.0", server_port=7862, show_error=True, theme=gr.themes.Soft())
