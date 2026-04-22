# 🤖 AI Demo App - Flutter Web Application

A powerful Flutter web application featuring AI-powered vision assistance, image generation, and intelligent chat capabilities. Built with accessibility in mind, especially for visually impaired users.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![AI](https://img.shields.io/badge/AI-Powered-brightgreen?style=for-the-badge)
![Accessibility](https://img.shields.io/badge/Accessibility-Focused-blue?style=for-the-badge)

## 🌟 Features

### 👁️ Vision Assistant (Accessibility Focus)
- **Camera & Gallery Support**: Upload images or take photos directly
- **Voice Input**: Speak your questions using the microphone button
- **Auto Voice Output**: Responses are automatically spoken aloud
- **Rich Descriptions**: Detailed image analysis for visually impaired users
- **AI Model**: Llama 4 Scout 17B for vision + Qwen3-32B for text analysis

### 🎨 Image Generation
- **Text-to-Image**: Generate images from text descriptions
- **Instant Results**: Fast placeholder image generation
- **Example Prompts**: Pre-built creative suggestions
- **No API Keys Required**: Uses reliable free services

### 💬 AI Chat
- **Qwen3-32B Model**: 32.8 billion parameter language model
- **Natural Conversations**: Context-aware dialogue
- **Voice Output**: Click "Read aloud" on any response
- **Clean Formatting**: No markdown or technical artifacts
- **Fast Responses**: Powered by Groq's ultra-fast inference

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0 or higher)
- Chrome or Edge browser (for Web Speech API support)
- Groq API key (free at [console.groq.com](https://console.groq.com))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ai-demo-app.git
   cd ai-demo-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Key**
   
   Edit `lib/services/groq_service.dart` and replace the API key:
   ```dart
   static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
   ```

4. **Run the application**
   ```bash
   flutter run -d web-server --web-port=9090
   ```

5. **Open in browser**
   
   Navigate to `http://localhost:9090`

## 🔧 Configuration

### API Keys Setup

#### Groq API (Required)
1. Visit [console.groq.com](https://console.groq.com)
2. Create a free account
3. Generate an API key
4. Replace the key in `lib/services/groq_service.dart`

```dart
static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE_API_KEY_HERE';
```

### Models Used
- **Chat**: `qwen/qwen3-32b` (32.8B parameters)
- **Vision**: `meta-llama/llama-4-scout-17b-16e-instruct`
- **Image Generation**: Lorem Picsum (placeholder service)

## 📱 Usage Guide

### Vision Assistant Tab
1. **Upload Image**: Click the image area or use Gallery/Camera buttons
2. **Ask Questions**: 
   - Type your question in the text field, OR
   - Click the microphone button and speak your question
3. **Get Answers**: The AI will analyze the image and speak the response automatically
4. **Example Questions**:
   - "Describe everything in this image"
   - "What objects are here?"
   - "Is there any text?"
   - "What colors are present?"

### Image Generation Tab
1. **Enter Prompt**: Describe the image you want to generate
2. **Click Generate**: Wait for the image to be created
3. **Try Examples**: Click on any example prompt to use it
4. **Note**: Currently uses placeholder images for demonstration

### AI Chat Tab
1. **Start Conversation**: Type a message or click an example
2. **Voice Output**: Click "Read aloud" on any AI response
3. **Clear Chat**: Use the trash icon to start fresh
4. **Context Memory**: The AI remembers your conversation history

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point with navigation
├── screens/
│   ├── vision_screen.dart       # Vision Assistant (Tab 1)
│   ├── image_gen_screen.dart    # Image Generation (Tab 2)
│   └── chat_screen.dart         # AI Chat (Tab 3)
└── services/
    ├── groq_service.dart        # Groq API integration
    └── web_speech_service.dart  # Browser speech APIs
```

## 🔍 Technical Details

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0           # API requests
  image_picker: ^1.0.4   # Camera/gallery access
```

### Web Speech API
- **Text-to-Speech**: Uses browser's `SpeechSynthesis`
- **Speech-to-Text**: Uses `webkitSpeechRecognition`
- **Browser Support**: Chrome, Edge (recommended)

### API Specifications
- **Base URL**: `https://api.groq.com/openai/v1/chat/completions`
- **Timeout**: 30 seconds
- **Max Tokens**: 2048 (chat), 1024 (vision)
- **Temperature**: 0.7 (chat), 0.5 (vision)

## 🎯 Accessibility Features

This app is designed with accessibility in mind:

- **Voice Input**: Speak questions instead of typing
- **Auto Voice Output**: Responses are automatically read aloud
- **High Contrast**: Dark theme with clear visual hierarchy
- **Large Touch Targets**: Easy-to-tap buttons and controls
- **Screen Reader Friendly**: Semantic HTML and proper ARIA labels
- **Keyboard Navigation**: Full keyboard support

## 🐛 Troubleshooting

### Common Issues

**Chat not responding**
- Check your Groq API key is valid
- Verify internet connection
- Open browser console (F12) for error details

**Voice features not working**
- Use Chrome or Edge browser
- Allow microphone permissions
- Check browser console for Web Speech API errors

**Image upload fails**
- Allow camera/file permissions
- Try different image formats (JPG, PNG)
- Check file size (recommended < 5MB)

### Debug Mode
Open browser console (F12) to see detailed API logs:
- `Groq API Response Status: 200` = Success
- `Groq API Error: 401` = Invalid API key
- `Groq API Exception` = Network/timeout issues

## 🚀 Deployment

### GitHub Pages
1. Build for web:
   ```bash
   flutter build web
   ```

2. Deploy the `build/web` folder to GitHub Pages

### Other Platforms
- **Netlify**: Drag and drop `build/web` folder
- **Vercel**: Connect GitHub repository
- **Firebase Hosting**: Use `firebase deploy`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Test on multiple browsers
- Ensure accessibility compliance
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Groq**: Ultra-fast AI inference platform
- **Qwen Team**: Qwen3-32B language model
- **Meta**: Llama 4 Scout vision model
- **Flutter Team**: Amazing cross-platform framework
- **Web Speech API**: Browser-native speech capabilities

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ai-demo-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ai-demo-app/discussions)
- **Documentation**: [Flutter Docs](https://docs.flutter.dev)
- **Groq API**: [console.groq.com/docs](https://console.groq.com/docs)

## 🔮 Future Enhancements

- [ ] Real AI image generation (DALL-E, Midjourney)
- [ ] Multi-language support
- [ ] Mobile app versions (iOS/Android)
- [ ] User authentication and chat history
- [ ] Custom voice settings
- [ ] Offline mode capabilities
- [ ] Advanced accessibility features

---

**Made with ❤️ for accessibility and AI innovation**

⭐ **Star this repo if you found it helpful!**"# HCI" 
"# HCI" 
"# HCI" 
"# HCI" 
