"""
AI Vision & Chat Demo
Tab 1: Vision Assistant (Llama 4 Scout via Groq) - for visually impaired
Tab 2: Image Generation (Pollinations.ai - free)
Tab 3: AI Chat (Qwen3-32B via Groq)
"""
import gradio as gr
import pyttsx3
import whisper
import requests
from PIL import Image
from io import BytesIO
import base64

GROQ_API_KEY = "YOUR_GROQ_API_KEY_HERE"  # Replace with your actual Groq API key
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "qwen/qwen3-32b"
VISION_MODEL = "meta-llama/llama-4-scout-17b-16e-instruct"

whisper_model = None

def load_whisper():
    global whisper_model
    if whisper_model is None:
        print("Loading Whisper...")
        whisper_model = whisper.load_model("base")
        print("Whisper ready.")
    return whisper_model

def tts(text):
    try:
        path = "temp_audio.wav"
        engine = pyttsx3.init()
        engine.setProperty('rate', 150)
        engine.setProperty('volume', 1.0)
        for v in engine.getProperty('voices'):
            if 'zira' in v.name.lower() or 'female' in v.name.lower():
                engine.setProperty('voice', v.id)
                break
        engine.save_to_file(text, path)
        engine.runAndWait()
        return path
    except Exception as e:
        print(f"TTS error: {e}")
        return None

def transcribe(audio_path):
    if not audio_path:
        return ""
    try:
        result = load_whisper().transcribe(audio_path)
        return result["text"].strip()
    except Exception as e:
        print(f"Transcribe error: {e}")
        return ""

def groq_chat(messages, max_tokens=2048):
    try:
        r = requests.post(
            GROQ_API_URL,
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={"model": GROQ_MODEL, "messages": messages, "temperature": 0.7, "max_tokens": max_tokens},
            timeout=30
        )
        if r.status_code != 200:
            return f"Error {r.status_code}: {r.text}"
        return r.json()["choices"][0]["message"]["content"]
    except Exception as e:
        return f"Error: {e}"

def clean_text(text):
    for ch in ["**", "*", "###", "##", "#"]:
        text = text.replace(ch, "")
    return text.strip()

# ── Tab 1: Vision Assistant ──────────────────────────────────────────────────
def analyze_image(image, voice_q, text_q):
    if image is None:
        return "Please upload an image or take a photo first.", None

    question = transcribe(voice_q) if voice_q else ""
    if not question:
        question = text_q or "Describe everything in this image in rich detail for someone who cannot see."

    try:
        img = image.convert("RGB")
        img.thumbnail((768, 768))
        buf = BytesIO()
        img.save(buf, format="JPEG", quality=80)
        b64 = base64.b64encode(buf.getvalue()).decode()

        r = requests.post(
            GROQ_API_URL,
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={
                "model": VISION_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": (
                            "You are an accessibility assistant for blind and visually impaired people. "
                            "Describe images in rich, clear detail covering colors, shapes, objects, people, "
                            "text, emotions, and spatial layout. Write in plain sentences without any markdown."
                        )
                    },
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": question},
                            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}"}}
                        ]
                    }
                ],
                "max_tokens": 1024,
                "temperature": 0.5
            },
            timeout=30
        )

        if r.status_code != 200:
            return f"Error {r.status_code}: {r.text}", None

        answer = clean_text(r.json()["choices"][0]["message"]["content"])
        return answer, tts(answer)

    except Exception as e:
        return f"Error: {e}", None

# ── Tab 2: Image Generation ──────────────────────────────────────────────────
def generate_image(prompt):
    if not prompt:
        return None, "Please enter a description."
    try:
        import urllib.parse
        url = f"https://image.pollinations.ai/prompt/{urllib.parse.quote(prompt)}"
        r = requests.get(url, timeout=60)
        if r.status_code == 200:
            return Image.open(BytesIO(r.content)), f"Done. Prompt: {prompt}"
        return None, f"Error {r.status_code}"
    except Exception as e:
        return None, f"Error: {e}"

# ── Tab 3: Chat ──────────────────────────────────────────────────────────────
def chat_respond(message, history):
    if not message.strip():
        return "", history
    api_msgs = [{"role": "system", "content": "You are a helpful AI assistant. Be friendly and conversational. No markdown formatting."}]
    for h in history:
        api_msgs.append({"role": h["role"], "content": h["content"]})
    api_msgs.append({"role": "user", "content": message})
    reply = clean_text(groq_chat(api_msgs))
    history = history + [{"role": "user", "content": message}, {"role": "assistant", "content": reply}]
    return "", history

def clear_chat():
    return []

# ── UI ───────────────────────────────────────────────────────────────────────
with gr.Blocks(title="AI Demo") as demo:
    gr.Markdown("# AI Demo\nVision Assistant | Image Generation | AI Chat")

    with gr.Tabs():

        # ── Tab 1 ──
        with gr.Tab("Vision Assistant"):
            gr.Markdown("### For visually impaired users\nUpload or capture an image, ask by voice or text, get a spoken description.")
            with gr.Row():
                with gr.Column(scale=1):
                    v_image = gr.Image(sources=["upload", "webcam"], type="pil", label="Image")
                    v_voice = gr.Audio(sources=["microphone"], type="filepath", label="Ask by Voice")
                    v_text  = gr.Textbox(placeholder="Or type your question here...", label="Question", lines=2)
                    v_btn   = gr.Button("Analyze Image", variant="primary")
                with gr.Column(scale=1):
                    v_out   = gr.Textbox(label="Description", lines=14)
                    v_audio = gr.Audio(label="Voice Answer", autoplay=True)
            v_btn.click(fn=analyze_image, inputs=[v_image, v_voice, v_text], outputs=[v_out, v_audio])

        # ── Tab 2 ──
        with gr.Tab("Image Generation"):
            gr.Markdown("### Generate images from text (free, no API key needed)")
            with gr.Row():
                with gr.Column(scale=1):
                    ig_prompt = gr.Textbox(placeholder="A cat wearing a crown...", label="Description", lines=3)
                    ig_btn    = gr.Button("Generate", variant="primary")
                with gr.Column(scale=1):
                    ig_image  = gr.Image(label="Generated Image", type="pil")
                    ig_status = gr.Textbox(label="Status", lines=2)
            ig_btn.click(fn=generate_image, inputs=[ig_prompt], outputs=[ig_image, ig_status])

        # ── Tab 3 ──
        with gr.Tab("AI Chat"):
            gr.Markdown("### Chat with Qwen3-32B")
            chatbot  = gr.Chatbot(height=450, type="messages")
            chat_msg = gr.Textbox(placeholder="Type a message...", label="Message", lines=2)
            with gr.Row():
                send_btn  = gr.Button("Send", variant="primary")
                clear_btn = gr.Button("Clear")
            chat_msg.submit(chat_respond, [chat_msg, chatbot], [chat_msg, chatbot])
            send_btn.click(chat_respond,  [chat_msg, chatbot], [chat_msg, chatbot])
            clear_btn.click(clear_chat, outputs=[chatbot])

if __name__ == "__main__":
    print("Starting on http://localhost:7862")
    demo.launch(server_name="0.0.0.0", server_port=7862, show_error=True)
