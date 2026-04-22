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
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

GROQ_API_KEY  = os.getenv("GROQ_API_KEY", "your_groq_api_key_here")
HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY", "your_huggingface_api_key_here")
GROQ_API_URL  = "https://api.groq.com/openai/v1/chat/completions"
CHAT_MODEL    = "llama3-70b-8192"
VISION_MODEL  = "meta-llama/llama-4-scout-17b-16e-instruct"
# Using a working Arabic TTS model from Hugging Face
ARABIC_TTS_URL = "https://api-inference.huggingface.co/models/facebook/mms-tts-ara"


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

def _arabic_tts(text: str) -> bytes | None:
    """
    Arabic TTS using Groq's Orpheus model.
    High-quality Saudi Arabic voice via Groq API.
    """
    if not text:
        return None
    try:
        from groq import Groq
        from pathlib import Path
        import tempfile
        
        print(f"[Orpheus TTS] Generating speech with Groq for: {text[:50]}...")
        
        # Initialize Groq client
        client = Groq(api_key=GROQ_API_KEY)
        
        # Create temporary file for audio
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
            temp_path = Path(temp_file.name)
        
        # Generate speech using Groq's Orpheus model
        response = client.audio.speech.create(
            model="canopylabs/orpheus-arabic-saudi",
            voice="abdullah",
            response_format="wav",
            input=text,
        )
        
        # Stream to file
        response.write_to_file(temp_path)
        
        # Read the audio file
        with open(temp_path, 'rb') as f:
            audio_bytes = f.read()
        
        # Clean up temp file
        temp_path.unlink()
        
        print(f"[Orpheus TTS] Speech generated successfully ({len(audio_bytes)} bytes)")
        return audio_bytes
        
    except Exception as e:
        print(f"[Orpheus TTS] Error: {e}")
        import traceback
        traceback.print_exc()
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
    Calls Hugging Face Stable Diffusion for AI image generation.
    Returns: (PIL.Image | None, status_text)
    """
    if not prompt or not prompt.strip():
        return None, "Please enter a description."
    try:
        print(f"[Image Gen] Generating with Hugging Face: {prompt.strip()}")
        
        # Use Hugging Face FLUX.2-dev for better quality
        headers = {
            "Authorization": f"Bearer {HUGGINGFACE_API_KEY}",
        }
        
        payload = {
            "inputs": prompt.strip()
        }
        
        r = requests.post(
            "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0",
            headers=headers,
            json=payload,
            timeout=90
        )
        
        print(f"[Image Gen] Response status: {r.status_code}")
        
        if r.status_code == 200:
            img = Image.open(BytesIO(r.content))
            return img, f'Generated: "{prompt.strip()}"'
        elif r.status_code == 503:
            return None, "Model is loading, please wait and try again..."
        else:
            print(f"[Image Gen] Error: {r.text}")
            return None, f"Error {r.status_code}: Please try again"
    except Exception as e:
        print(f"[Image Gen] Exception: {e}")
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
                "Powered by [Stable Diffusion XL](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) — high-quality AI image generation."
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
    from flask import Flask, request, Response
    from flask_cors import CORS
    import threading
    
    # Create Flask app for REST API
    app = Flask(__name__)
    CORS(app)  # Enable CORS for all routes
    
    @app.route('/api/generate-image', methods=['POST', 'OPTIONS'])
    def generate_image_endpoint():
        """REST API endpoint for image generation"""
        # Handle preflight request
        if request.method == 'OPTIONS':
            response = Response()
            response.headers['Access-Control-Allow-Origin'] = '*'
            response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
            response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
            return response
            
        try:
            data = request.get_json()
            prompt = data.get('prompt', '')
            if not prompt:
                return {'error': 'No prompt provided'}, 400
            
            print(f"[Image API] Generating image for: {prompt}")
            
            # Generate image using Hugging Face
            headers = {
                "Authorization": f"Bearer {HUGGINGFACE_API_KEY}",
            }
            
            payload = {
                "inputs": prompt.strip()
            }
            
            # Try working models - FLUX might not be available via API
            models = [
                "stabilityai/stable-diffusion-xl-base-1.0",
                "runwayml/stable-diffusion-v1-5",
                "CompVis/stable-diffusion-v1-4"
            ]
            
            r = None
            for model in models:
                try:
                    print(f"[Image API] Trying model: {model}")
                    r = requests.post(
                        f"https://api-inference.huggingface.co/models/{model}",
                        headers=headers,
                        json=payload,
                        timeout=90
                    )
                    if r.status_code == 200:
                        print(f"[Image API] Success with model: {model}")
                        break
                    elif r.status_code == 503:
                        print(f"[Image API] Model {model} is loading, trying next...")
                        continue
                    else:
                        print(f"[Image API] Model {model} failed with {r.status_code}: {r.text}")
                        continue
                except Exception as e:
                    print(f"[Image API] Model {model} exception: {e}")
                    continue
            
            print(f"[Image API] Response status: {r.status_code if r else 'No response'}")
            
            if r and r.status_code == 200:
                response = Response(r.content, mimetype='image/jpeg')
                response.headers['Access-Control-Allow-Origin'] = '*'
                return response
            elif r and r.status_code == 503:
                return {'error': 'All models are loading, please wait and try again...'}, 503
            else:
                # Fallback to Pollinations.ai if Hugging Face fails
                print("[Image API] Hugging Face failed, trying Pollinations.ai fallback...")
                try:
                    fallback_url = f"https://image.pollinations.ai/prompt/{urllib.parse.quote(prompt.strip())}"
                    fallback_r = requests.get(fallback_url, timeout=30)
                    if fallback_r.status_code == 200:
                        print("[Image API] Fallback successful")
                        response = Response(fallback_r.content, mimetype='image/jpeg')
                        response.headers['Access-Control-Allow-Origin'] = '*'
                        return response
                except Exception as fallback_e:
                    print(f"[Image API] Fallback also failed: {fallback_e}")
                
                error_text = r.text if r else 'No models available'
                print(f"[Image API] Error response: {error_text}")
                return {'error': f'Generation failed: {r.status_code if r else "No response"}'}, 500
                
        except Exception as e:
            print(f"[Image API Error] {e}")
            import traceback
            traceback.print_exc()
            return {'error': str(e)}, 500
    
    @app.route('/api/arabic-tts', methods=['POST', 'OPTIONS'])
    def arabic_tts_endpoint():
        """REST API endpoint for Arabic TTS"""
        # Handle preflight request
        if request.method == 'OPTIONS':
            response = Response()
            response.headers['Access-Control-Allow-Origin'] = '*'
            response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
            response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
            return response
            
        try:
            data = request.get_json()
            text = data.get('text', '')
            if not text:
                return {'error': 'No text provided'}, 400
            
            audio_bytes = _arabic_tts(text)
            if audio_bytes:
                response = Response(audio_bytes, mimetype='audio/wav')
                response.headers['Access-Control-Allow-Origin'] = '*'
                return response
            else:
                return {'error': 'Failed to generate speech'}, 500
        except Exception as e:
            print(f"[API Error] {e}")
            return {'error': str(e)}, 500
    
    # Run Flask in a separate thread
    def run_flask():
        app.run(host='0.0.0.0', port=7863, debug=False)
    
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()
    
    print("=" * 50)
    print("AI Demo App — Gradio Backend")
    print("Gradio UI: http://localhost:7862")
    print("Arabic TTS API: http://localhost:7863/api/arabic-tts")
    print("=" * 50)
    demo.launch(server_name="0.0.0.0", server_port=7862, show_error=True, theme=gr.themes.Soft())
