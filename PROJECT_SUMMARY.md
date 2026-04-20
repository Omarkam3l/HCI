# Flutter AI Demo App - Project Summary

## 📱 App Overview
A Flutter web app with 3 main features:
1. **Vision Assistant** - For visually impaired users (accessibility focus)
2. **Image Generation** - Text-to-image generation
3. **AI Chat** - Conversation with Qwen3-32B

## 🔑 API Keys & Services

### Groq API (Main AI Service)
- **API Key**: `YOUR_GROQ_API_KEY_HERE` (Get from console.groq.com)
- **Chat Model**: `qwen/qwen3-32b` (32.8B parameters)
- **Vision Model**: `meta-llama/llama-4-scout-17b-16e-instruct`
- **Endpoint**: `https://api.groq.com/openai/v1/chat/completions`

### HuggingFace Token (Backup)
- **Token**: `YOUR_HF_TOKEN_HERE` (Get from huggingface.co)
- **Note**: Free tier doesn't support vision/image generation models

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point with bottom navigation
├── screens/
│   ├── vision_screen.dart       # Tab 1: Vision Assistant (accessibility)
│   ├── image_gen_screen.dart    # Tab 2: Image Generation
│   └── chat_screen.dart         # Tab 3: AI Chat with Qwen3-32B
└── services/
    ├── groq_service.dart        # Groq API integration
    └── web_speech_service.dart  # Browser speech synthesis/recognition
```

## 🎯 Key Features

### Tab 1 - Vision Assistant (Accessibility)
- **Purpose**: For visually impaired users
- **Features**:
  - Upload image or use camera
  - Voice input (microphone button)
  - Auto-speaks answers using browser TTS
  - Ask questions about images
- **Model**: Llama 4 Scout 17B (vision) + Qwen3-32B (text)

### Tab 2 - Image Generation
- **Service**: Lorem Picsum (placeholder images)
- **Features**:
  - Text prompt input
  - Generates consistent placeholder images
  - No API key required
- **Note**: Real AI image generation services had API issues

### Tab 3 - AI Chat
- **Model**: Qwen3-32B (32.8 billion parameters)
- **Features**:
  - Natural conversation
  - Voice output ("Read aloud" button)
  - Clean formatting (no markdown/thinking tags)
  - Context memory

## 🔧 Technical Details

### Dependencies (pubspec.yaml)
- `flutter: sdk: flutter`
- `http: ^1.1.0` - API calls
- `image_picker: ^1.0.4` - Camera/gallery access

### Web Speech API Integration
- **Text-to-Speech**: Browser's `SpeechSynthesis`
- **Speech-to-Text**: Browser's `webkitSpeechRecognition`
- **Platform**: Web only (uses `dart:html` and `dart:js_util`)

### API Configuration
- **Temperature**: 0.7 (chat), 0.5 (vision)
- **Max Tokens**: 2048 (chat), 1024 (vision)
- **Timeout**: 30 seconds
- **Error Handling**: Detailed logging and user-friendly messages

## 🚀 How to Run

1. **Prerequisites**:
   ```bash
   flutter --version  # Ensure Flutter is installed
   ```

2. **Setup**:
   ```bash
   cd ai_demo_app
   flutter pub get
   ```

3. **Run Web App**:
   ```bash
   flutter run -d web-server --web-port=9090
   ```

4. **Access**: Open `http://localhost:9090` in Chrome/Edge

## 🔍 Debugging

### Console Logs
- Open browser console (F12) to see API request/response logs
- Look for messages starting with "Groq API"

### Common Issues
1. **Chat not responding**: Check Groq API key and model name
2. **Voice not working**: Ensure using Chrome/Edge browser
3. **Image upload fails**: Check camera/file permissions

## 📝 Important Notes

### User Requirements
- **NEVER change models without permission**
- **Qwen3-32B is the required chat model**
- **Tab 1 must be accessibility-focused for visually impaired users**
- **Voice input/output is essential**

### Model Specifications
- **Qwen3-32B**: 32.8B parameters, 131K context window, multilingual
- **Llama 4 Scout**: 17B parameters, vision capabilities
- **Both models**: Available on Groq with fast inference

## 🔄 Version History
- **v1.0**: Initial Python Gradio app
- **v2.0**: Switched to API-based models (Groq)
- **v3.0**: Added voice features and accessibility focus
- **v4.0**: Flutter web app with 3 tabs
- **v4.1**: Fixed formatting and API issues (current)

## 📞 Support
- **Groq Documentation**: https://console.groq.com/docs
- **Flutter Web**: https://docs.flutter.dev/platform-integration/web
- **Web Speech API**: https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API

---
**Last Updated**: April 20, 2026
**Status**: Production Ready ✅