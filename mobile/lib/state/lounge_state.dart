import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/social_bridge_service.dart';
import '../services/voice_controller.dart';
import '../services/language_controller.dart';

/// AI operational state — drives UI indicators.
enum AiState { idle, thinking, listening, speaking }

/// Central ChangeNotifier for the Social Lounge screen.
class LoungeState extends ChangeNotifier {
  // ── Messages ──────────────────────────────────────────────────────────────
  final List<SocialMessage> messages = [];

  // ── AI State ──────────────────────────────────────────────────────────────
  AiState _aiState = AiState.idle;
  AiState get aiState => _aiState;

  // ── Language ──────────────────────────────────────────────────────────────
  final LanguageController language = LanguageController();

  // ── Voice transcript (live partial) ───────────────────────────────────────
  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  // ── Stream subscription ───────────────────────────────────────────────────
  StreamSubscription<SocialMessage>? _sub;

  LoungeState() {
    _sub = SocialBridgeService.messageStream.listen(_onNewMessage);
    VoiceController.initStt();
    VoiceController.initTts();
    // Forward language changes to our own listeners
    language.addListener(notifyListeners);
  }

  // ── Stream handler ────────────────────────────────────────────────────────

  void _onNewMessage(SocialMessage msg) {
    messages.add(msg);
    _aiState = AiState.idle;
    _liveTranscript = '';
    notifyListeners();
    _hapticHeartbeat();
  }

  // ── Input: Text ───────────────────────────────────────────────────────────

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(SocialMessage(
      role: 'user',
      content: text,
      type: MessageType.textToText,
    ));
    _aiState = AiState.thinking;
    notifyListeners();

    await SocialBridgeService.processTextInput(text);

    _aiState = AiState.speaking;
    notifyListeners();
  }

  // ── Input: Voice ──────────────────────────────────────────────────────────

  Future<void> startVoice() async {
    _aiState = AiState.listening;
    _liveTranscript = '';
    notifyListeners();

    HapticFeedback.mediumImpact();

    messages.add(SocialMessage(
      role: 'user',
      content: '',
      type: MessageType.voiceToText,
    ));
    notifyListeners();

    await SocialBridgeService.processVoiceInput(
      langCtrl: language,
      onTranscript: (transcript) {
        if (messages.isNotEmpty && messages.last.role == 'user') {
          messages[messages.length - 1] = SocialMessage(
            role: 'user',
            content: transcript,
            type: MessageType.voiceToText,
          );
        }
        _liveTranscript = transcript;
        _aiState = AiState.listening;
        notifyListeners();
      },
      onError: (error) {
        _aiState = AiState.idle;
        notifyListeners();
      },
    );

    _aiState = AiState.thinking;
    notifyListeners();
  }

  Future<void> stopVoice() async {
    await VoiceController.stopListening();
    HapticFeedback.lightImpact();
    _aiState = AiState.thinking;
    notifyListeners();
  }

  // ── Input: Image ──────────────────────────────────────────────────────────

  Future<void> sendImage(List<int> imageBytes, {String? caption}) async {
    messages.add(SocialMessage(
      role: 'user',
      content: caption ?? (language.preferArabic ? 'شارك صورة' : 'Shared an image'),
      type: MessageType.imageToStory,
      imageBytes: imageBytes as dynamic,
    ));
    _aiState = AiState.thinking;
    notifyListeners();

    await SocialBridgeService.processImageInput(
      imageBytes: imageBytes as dynamic,
      userCaption: caption,
    );

    _aiState = AiState.speaking;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearMessages() {
    messages.clear();
    notifyListeners();
  }

  Future<void> _hapticHeartbeat() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _sub?.cancel();
    language.removeListener(notifyListeners);
    language.dispose();
    super.dispose();
  }
}
