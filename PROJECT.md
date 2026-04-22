# AI Demo App — Project Documentation

> A dual-interface AI application combining a **Flutter Mobile App** and a **Python Gradio Backend**, built for accessibility, bilingual support, and multi-modal AI interaction.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Features](#4-features)
5. [AI Models & APIs](#5-ai-models--apis)
6. [Tech Stack](#6-tech-stack)
7. [UI/UX Design System](#7-uiux-design-system)
8. [Setup & Installation](#8-setup--installation)
9. [Running the App](#9-running-the-app)
10. [Configuration](#10-configuration)
11. [Accessibility Features](#11-accessibility-features)
12. [Bilingual Support](#12-bilingual-support)
13. [File Reference](#13-file-reference)

---

## 1. Project Overview

The **AI Demo App** is a full-stack AI application with two interfaces:

| Interface | Technology | Port | Purpose |
|---|---|---|---|
| Mobile App | Flutter (Android / iOS / Web) | 9090 | Primary user interface |
| Gradio Backend | Python + Gradio | 7862 | Desktop AI interface with Whisper STT & pyttsx3 TTS |

Both interfaces expose the same three core AI features: **Vision Assistant**, **Image Generation**, and **Social Bridge (AI Lounge)**.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Mobile App                  │
│                   (port 9090)                        │
│                                                      │
│  Landing Screen → Vision | Image Gen | Social Lounge │
│                                                      │
│  Services:                                           │
│    AiService          → Groq API (direct HTTP)       │
│    SocialBridgeService → Multi-modal orchestrator    │
│    VoiceController    → STT (speech_to_text)         │
│                         TTS (flutter_tts)            │
│    LanguageController → Arabic / English switching   │
│    BilingualHelper    → RTL/LTR detection            │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP (direct)
                   ▼
         ┌─────────────────┐
         │   Groq Cloud    │
         │  llama3-70b     │
         │  llama-4-scout  │
         └─────────────────┘

┌─────────────────────────────────────────────────────┐
│              Python Gradio Backend                   │
│                   (port 7862)                        │
│                                                      │
│  Tab 1: Vision Assistant                             │
│    Whisper STT → Groq Vision → pyttsx3 TTS           │
│                                                      │
│  Tab 2: Image Generation                             │
│    Pollinations.ai (free, no key)                    │
│                                                      │
│  Tab 3: AI Chat                                      │
│    Groq llama3-70b-8192                              │
└─────────────────────────────────────────────────────┘
```

---

## 3. Project Structure

```
HCI/
├── backend/
│   ├── demo_app_gemini.py      # Gradio UI + all AI logic
│   └── requirements.txt        # Python dependencies
│
├── mobile/
│   ├── pubspec.yaml            # Flutter dependencies
│   ├── lib/
│   │   ├── main.dart           # Entry point, theme, navigation
│   │   ├── screens/
│   │   │   ├── landing_screen.dart       # Animated landing page
│   │   │   ├── vision_screen.dart        # Image analysis (accessibility)
│   │   │   ├── image_gen_screen.dart     # Text-to-image generation
│   │   │   └── social_lounge_screen.dart # Multi-modal AI social space
│   │   ├── services/
│   │   │   ├── api_config.dart           # Central API key & endpoint config
│   │   │   ├── ai_service.dart           # Groq chat + vision HTTP calls
│   │   │   ├── social_bridge_service.dart # Multi-modal orchestrator + stream
│   │   │   ├── voice_controller.dart     # Bilingual STT + TTS
│   │   │   ├── language_controller.dart  # Arabic/English preference state
│   │   │   └── bilingual_helper.dart     # Language detection utilities
│   │   ├── state/
│   │   │   └── lounge_state.dart         # ChangeNotifier for Social Lounge
│   │   ├── theme/
│   │   │   ├── app_colors.dart           # Color palette, gradients, glows
│   │   │   └── app_theme.dart            # Material 3 dark theme config
│   │   └── widgets/
│   │       ├── glass_nav_bar.dart        # Glassmorphic bottom nav
│   │       ├── gradient_button.dart      # Reusable gradient CTA button
│   │       ├── prompt_card.dart          # Image gen prompt suggestion card
│   │       ├── smart_text.dart           # Auto RTL/LTR text widget
│   │       └── voice_language_picker.dart # EN | ع language toggle
│   ├── android/
│   │   └── app/src/main/
│   │       ├── AndroidManifest.xml       # Camera, mic, internet permissions
│   │       └── res/xml/file_paths.xml    # FileProvider for image_picker
│   └── ios/
│       └── Runner/Info.plist             # NSCamera, NSMicrophone, NSPhoto keys
│
├── frontend/                   # Flutter Web version (legacy)
│   └── lib/
│       ├── main.dart
│       ├── screens/            # vision, image_gen, chat screens
│       └── services/           # groq_service, web_speech_service
│
└── PROJECT.md                  # This file
```

---

## 4. Features

### Landing Screen
- Animated floating logo with gradient glow
- Feature preview cards (Vision, Image Gen, Lounge)
- Shimmer "Get Started" button with fade-in transition
- Background glow orbs for depth

### Vision Assistant
- Upload image from **Gallery** or **Camera**
- Images resized to 1024×1024 at 80% quality before upload
- Voice question input via **speech_to_text** (EN or AR)
- Animated **scanner beam** while analyzing
- Auto-reads response aloud via **flutter_tts**
- Example question chips for quick interaction
- Designed for **visually impaired users**

### Image Generation
- Text prompt input with clear button
- Deterministic placeholder images via `picsum.photos`
- Suggested prompt cards with left accent border
- Gradient "Generate" button with shimmer effect

### Social Bridge (AI Lounge)
- **Multi-modal orchestrator** — handles Text, Voice, and Image in one unified feed
- Voice input → STT → LLM → Emotional tag → TTS output (for Deaf users)
- Image input → Vision API → Sanrio-style story → TTS (for Blind users)
- Text input → Kindness moderation → LLM → dual visual + audio output
- Real-time message stream via `StreamController`
- Haptic heartbeat feedback on new messages (for Blind users)
- Bilingual emotional tags: `[Cheerful]` / `[نبرة سعيدة]`
- Language toggle (EN ↔ العربية) in AppBar
- AI state chip: Thinking / Listening / Speaking

---

## 5. AI Models & APIs

| Feature | Model | Provider | Key Required |
|---|---|---|---|
| Chat | `llama3-70b-8192` | Groq | Yes (`gsk_...`) |
| Vision | `llama-3.2-11b-vision-preview` | Groq | Yes (`gsk_...`) |
| Vision (backend) | `meta-llama/llama-4-scout-17b-16e-instruct` | Groq | Yes |
| Image Gen (backend) | Pollinations.ai | Free API | No |
| Image Gen (mobile) | Lorem Picsum | Free CDN | No |
| STT (mobile) | Device speech engine | OS native | No |
| STT (backend) | OpenAI Whisper `base` | Local model | No |
| TTS (mobile) | Device TTS engine | OS native | No |
| TTS (backend) | pyttsx3 (Zira voice) | Local | No |

---

## 6. Tech Stack

### Flutter Mobile
| Package | Version | Purpose |
|---|---|---|
| `http` | ^1.2.0 | API HTTP requests |
| `image_picker` | ^1.1.2 | Camera & gallery access |
| `cached_network_image` | ^3.3.1 | Image caching |
| `speech_to_text` | ^7.0.0 | Mobile STT |
| `flutter_tts` | ^4.2.0 | Mobile TTS |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `provider` | ^6.1.2 | State management |
| `google_fonts` | ^6.2.1 | Cairo (Arabic) + Poppins (English) |
| `webview_flutter` | ^4.10.0 | Embedded web views |

### Python Backend
| Package | Purpose |
|---|---|
| `gradio` | Web UI framework |
| `openai-whisper` | Local speech-to-text |
| `pyttsx3` | Local text-to-speech (Zira voice) |
| `requests` | HTTP calls to Groq & Pollinations |
| `Pillow` | Image processing & resizing |

---

## 7. UI/UX Design System

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `scaffold` | `#1A1A2E` | App background (deep navy) |
| `surface` | `#16213E` | Cards, inputs |
| `navBar` | `#0F3460` | AppBar, bottom nav |
| `primary` | `#6750A4` | Purple seed, buttons |
| `primary2` | `#845EC2` | Lighter purple accent |
| `accent` | `#E94560` | Hot pink secondary |
| Sanrio pink | `#FFD1DC` | Social Lounge accents |

### Gradients
- **Primary gradient**: `#6750A4 → #845EC2` (top-left to bottom-right)
- **Button gradient**: `#6750A4 → #E94560` (left to right)
- **User bubble gradient**: `#6750A4 → #9B59B6`

### Typography
- **Arabic text**: Google Fonts `Cairo`, `FontWeight.w500`, RTL
- **English text**: Google Fonts `Poppins`, `FontWeight.w400`, LTR
- **Letter spacing**: `0.5` globally

### Effects
- **Glassmorphism**: `BackdropFilter(blur: 20)` on nav bar and input bars
- **Glow shadows**: `BoxShadow(color: #4D6750A4, blurRadius: 20)` on cards
- **Shimmer**: Animated sweep on CTA buttons
- **Scanner beam**: Animated gradient line during image analysis

---

## 8. Setup & Installation

### Prerequisites
- Flutter SDK `>=3.3.0` ([install](https://flutter.dev/docs/get-started/install))
- Python 3.9+ ([install](https://python.org))
- A free Groq API key ([console.groq.com](https://console.groq.com))

### Python Backend Setup
```bash
cd backend
pip install gradio pyttsx3 openai-whisper requests Pillow
```

### Flutter Mobile Setup
```bash
cd mobile
flutter pub get
```

### Android Permissions
Already configured in `android/app/src/main/AndroidManifest.xml`:
- `INTERNET`
- `CAMERA`
- `RECORD_AUDIO`
- `READ_MEDIA_IMAGES`

### iOS Permissions
Already configured in `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSSpeechRecognitionUsageDescription`

---

## 9. Running the App

### Start the Python Backend
```bash
cd backend
py demo_app_gemini.py
# → http://localhost:7862
```

### Run Flutter on Chrome (Web)
```bash
cd mobile
flutter run -d chrome --web-port 9090
# → http://localhost:9090
```

### Run Flutter on Android Emulator
```bash
cd mobile
flutter run
```

### Run Flutter on Physical Android Device
1. Enable **Developer Options** on the device
2. Turn on **USB Debugging**
3. Connect via USB
4. Run `flutter devices` to confirm detection
5. Run `flutter run`

---

## 10. Configuration

### API Key
Open `mobile/lib/services/api_config.dart` and replace the placeholder:

```dart
static String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
```

Get a free key at [console.groq.com](https://console.groq.com).

Also update `backend/demo_app_gemini.py`:
```python
GROQ_API_KEY = "YOUR_GROQ_API_KEY_HERE"
```

### Backend URL (Physical Device)
If running on a physical phone, change `backendBaseUrl` in `api_config.dart` to your machine's LAN IP:
```dart
static const String backendBaseUrl = 'http://192.168.1.x:7862';
```

---

## 11. Accessibility Features

| Feature | Benefit | Implementation |
|---|---|---|
| Voice input (STT) | Blind users can speak questions | `speech_to_text` package |
| Auto TTS response | Blind users hear AI answers | `flutter_tts` auto-speaks after analysis |
| Scanner beam animation | Visual feedback during analysis | `AnimationController` on image card |
| Haptic heartbeat | Blind users feel new messages | `HapticFeedback.lightImpact()` double pulse |
| High contrast dark theme | Low vision users | Material 3 dark with `#1A1A2E` background |
| Emotional tone tags | Deaf users understand voice tone | `[Cheerful]`, `[Gentle]`, `[نبرة سعيدة]` |
| RTL layout | Arabic users | Per-bubble `Directionality` widget |

---

## 12. Bilingual Support

The app fully supports **Arabic** and **English** with automatic detection.

### Language Detection
```dart
// BilingualHelper.isArabic(text)
// Uses Unicode range U+0600–U+06FF
RegExp(r'[\u0600-\u06FF]').hasMatch(text)
```

### Auto-switching
| Component | Behavior |
|---|---|
| `SmartText` widget | Detects language → applies Cairo (AR) or Poppins (EN) |
| `Directionality` | Wraps each text block with RTL or LTR |
| `VoiceController.speak()` | Detects Arabic → sets `flutter_tts` to `ar-SA` |
| `VoiceLanguagePicker` | EN \| ع toggle in AppBar of Vision & Lounge screens |
| Emotional tags | Translated: `[Cheerful]` → `[نبرة سعيدة]` |
| Sanrio greetings | `"Hello friend"` → `"أهلاً يا صديقي"` |

### STT Locales
- English: `en-US`
- Arabic: `ar-SA` (Saudi) — switchable to `ar-EG` (Egypt)

---

## 13. File Reference

### Key Files

| File | Description |
|---|---|
| `mobile/lib/main.dart` | App entry, theme, landing→home navigation |
| `mobile/lib/services/api_config.dart` | **Edit this** — API key & backend URL |
| `mobile/lib/services/social_bridge_service.dart` | Multi-modal AI orchestrator |
| `mobile/lib/services/voice_controller.dart` | Bilingual STT + TTS |
| `mobile/lib/services/bilingual_helper.dart` | `isArabic()`, direction, emotion tag translation |
| `mobile/lib/state/lounge_state.dart` | `ChangeNotifier` for Social Lounge |
| `mobile/lib/theme/app_colors.dart` | All colors, gradients, glow shadows |
| `mobile/lib/widgets/smart_text.dart` | Auto-font, auto-direction text widget |
| `backend/demo_app_gemini.py` | Full Gradio backend — Vision, Image Gen, Chat |

### Screens

| Screen | Route | Description |
|---|---|---|
| `LandingScreen` | Initial | Animated intro with "Get Started" |
| `VisionScreen` | Tab 0 | Image analysis for accessibility |
| `ImageGenScreen` | Tab 1 | Text-to-image generation |
| `SocialLoungeScreen` | Tab 2 | Multi-modal inclusive AI social space |

---

## Repository

- **GitHub**: [Omarkam3l/HCI](https://github.com/Omarkam3l/HCI)
- **Branch**: `Reem`
- **Committed as**: Remaaa17

---

*Last updated: April 2026*
