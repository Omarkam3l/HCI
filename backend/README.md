# AI Demo App Backend

Python backend with Gradio UI and Flask API for AI-powered vision, image generation, and chat.

## Features

- **Vision Assistant**: Image analysis with Llama-4-Scout vision model
- **Image Generation**: AI image generation with Stable Diffusion XL + Pollinations.ai fallback
- **AI Chat**: Conversational AI with Llama3-70b
- **Arabic TTS**: High-quality Arabic text-to-speech using Groq's Orpheus model
- **Speech-to-Text**: OpenAI Whisper for voice input

## Setup

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure API Keys**
   ```bash
   cp .env.example .env
   # Edit .env and add your actual API keys
   ```

3. **Get API Keys**
   - **Groq API**: https://console.groq.com/
   - **Hugging Face**: https://huggingface.co/settings/tokens

4. **Run the Server**
   ```bash
   python demo_app_gemini.py
   ```

## Endpoints

- **Gradio UI**: http://localhost:7862
- **Arabic TTS API**: http://localhost:7863/api/arabic-tts
- **Image Generation API**: http://localhost:7863/api/generate-image

## Models Used

- **Vision**: meta-llama/llama-4-scout-17b-16e-instruct
- **Chat**: llama3-70b-8192
- **Arabic TTS**: canopylabs/orpheus-arabic-saudi (abdullah voice)
- **Image Generation**: stabilityai/stable-diffusion-xl-base-1.0
- **Speech-to-Text**: OpenAI Whisper (base model)