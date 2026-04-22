/// Central API configuration — single source of truth for all endpoints & keys.
abstract class ApiConfig {
  // ── Groq (direct) ─────────────────────────────────────────────────────────
  static String groqApiKey =
      'your_groq_api_key_here'; // Set via environment or app config

  static const String groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String chatModel   = 'llama-3.3-70b-versatile';
  static const String visionModel = "meta-llama/llama-4-scout-17b-16e-instruct";

  // ── Arabic TTS via Backend (gTTS - Google Text-to-Speech) ──────────────
  // Using gTTS through backend - free, reliable, high-quality
  static const String arabicTtsEndpoint = 'http://localhost:7863/api/arabic-tts';
  static bool get isArabicTtsEnabled => true; // Enabled with gTTS

  // ── Voice to Prompt (Whisper STT with translation) ──────────────────────
  static const String voiceToPromptEndpoint = 'http://localhost:7863/api/voice-to-prompt';


  // ── Python Gradio Backend ─────────────────────────────────────────────────
  /// Base URL of the local Gradio backend (port 7862).
  /// Change to your machine's LAN IP when running on a physical device,
  /// e.g. 'http://192.168.1.x:7862'
  static const String backendBaseUrl = 'http://localhost:7862';

  /// Full URL shown in the in-app WebView tab.
  static const String backendWebUrl  = '$backendBaseUrl/';

  /// Gradio REST API — predict endpoints
  static const String backendChatUrl    = '$backendBaseUrl/run/predict';
  static const String backendVisionUrl  = '$backendBaseUrl/run/predict';
  static const String backendImageUrl   = '$backendBaseUrl/run/predict';

  // ── Validation ────────────────────────────────────────────────────────────
  static bool get isKeySet =>
      groqApiKey.isNotEmpty && groqApiKey.startsWith('gsk_');

  static Map<String, String> get headers => {
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      };

  // ── Error parser ──────────────────────────────────────────────────────────
  static String parseError(int status, String body) {
    switch (status) {
      case 401:
        return 'API key is invalid or expired. Tap the key icon to update it.';
      case 429:
        return 'Rate limit reached. Please wait a moment and try again.';
      case 503:
        return 'Groq service is temporarily unavailable. Try again shortly.';
      default:
        return 'Request failed ($status). Please try again.';
    }
  }
}
