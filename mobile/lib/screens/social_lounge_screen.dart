import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../state/lounge_state.dart';
import '../services/social_bridge_service.dart';
import '../services/voice_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/smart_text.dart';
import '../widgets/voice_language_picker.dart';

// ── Sanrio-inspired accent on top of the dark navy base ──────────────────────
const _pink    = Color(0xFFFFD1DC);
const _pinkDim = Color(0x33FFD1DC);
const _pinkGlow = [
  BoxShadow(color: Color(0x40FFD1DC), blurRadius: 18, spreadRadius: 1),
];

class SocialLoungeScreen extends StatefulWidget {
  const SocialLoungeScreen({super.key});

  @override
  State<SocialLoungeScreen> createState() => _SocialLoungeScreenState();
}

class _SocialLoungeScreenState extends State<SocialLoungeScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();
  bool _isRecording = false;

  // Pulsing animation for the mic button while recording
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Voice ─────────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    final state = context.read<LoungeState>();

    if (_isRecording) {
      await state.stopVoice();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      setState(() => _isRecording = false);
      return;
    }

    final perm = await Permission.microphone.request();
    if (perm.isDenied || perm.isPermanentlyDenied) {
      _snack('Microphone permission required.');
      return;
    }

    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);
    await state.startVoice();
  }

  // ── Image ─────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final perm = await Permission.photos.request();
    if (perm.isDenied || perm.isPermanentlyDenied) {
      _snack('Photo library permission required.');
      return;
    }

    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    if (!mounted) return;

    // Immediately trigger image-to-story pipeline
    await context.read<LoungeState>().sendImage(bytes);
    _scrollToBottom();
  }

  // ── Text ──────────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await context.read<LoungeState>().sendText(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildFeed()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.navBar,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _pinkDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded, color: _pink, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Social Bridge',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              Text(
                'Inclusive AI Lounge',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.45),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<LoungeState>(
          builder: (_, state, __) => _AiStateChip(aiState: state.aiState),
        ),
        // Voice language picker
        const VoiceLanguagePicker(),
        const SizedBox(width: 4),
        // Language toggle (UI direction)
        Consumer<LoungeState>(
          builder: (_, state, __) => GestureDetector(
            onTap: () => state.language.toggleLanguage(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _pinkDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _pink.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, size: 13, color: _pink),
                  const SizedBox(width: 4),
                  Text(
                    state.language.currentLanguageLabel,
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.auto_delete_outlined, size: 20),
          onPressed: () => context.read<LoungeState>().clearMessages(),
          tooltip: 'Clear lounge',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFeed() {
    return Consumer<LoungeState>(
      builder: (_, state, __) {
        if (state.messages.isEmpty) return _buildEmptyState();

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.separated(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: state.messages.length +
              (state.aiState == AiState.thinking ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            if (i == state.messages.length) return const _ThinkingBubble();
            return _LoungeBubble(message: state.messages[i]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _pinkDim,
              boxShadow: _pinkGlow,
            ),
            child: const Icon(Icons.favorite_rounded, size: 48, color: _pink),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to the Lounge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type, speak, or share an image\nto start connecting',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildAccessibilityBadges(),
        ],
      ),
    );
  }

  Widget _buildAccessibilityBadges() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AccessBadge(
          icon: Icons.hearing_rounded,
          label: 'Deaf-Friendly',
          color: AppColors.primary2,
        ),
        SizedBox(width: 12),
        _AccessBadge(
          icon: Icons.visibility_off_rounded,
          label: 'Blind-Friendly',
          color: _pink,
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navBar.withOpacity(0.85),
            border: const Border(
              top: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Voice button (left)
                _VoiceMicButton(
                  isRecording: _isRecording,
                  pulseAnim: _pulseAnim,
                  onTap: _toggleRecording,
                ),
                const SizedBox(width: 10),

                // Text field (center)
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(
                        color: Colors.white, letterSpacing: 0.5),
                    decoration: InputDecoration(
                      hintText: 'Type a kind message...',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: _pink, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 10),

                // Camera button (right)
                _IconCircleBtn(
                  icon: Icons.add_photo_alternate_rounded,
                  color: _pink,
                  onTap: _pickImage,
                ),
                const SizedBox(width: 8),

                // Send button
                _IconCircleBtn(
                  icon: Icons.send_rounded,
                  color: AppColors.primary,
                  onTap: _sendText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lounge Bubble ─────────────────────────────────────────────────────────────

class _LoungeBubble extends StatelessWidget {
  final SocialMessage message;
  const _LoungeBubble({required this.message});

  bool get _isUser => message.role == 'user';
  bool get _isSystem => message.role == 'system';

  @override
  Widget build(BuildContext context) {
    if (_isSystem) return _buildSystemBubble();

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: _isUser
                ? const LinearGradient(
                    colors: [Color(0xFF6750A4), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _isUser ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(30),
              topRight:    const Radius.circular(30),
              bottomLeft:  Radius.circular(_isUser ? 30 : 6),
              bottomRight: Radius.circular(_isUser ? 6 : 30),
            ),
            border: _isUser
                ? null
                : Border.all(color: AppColors.borderMid),
            boxShadow: _isUser
                ? AppColors.subtleGlow
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview (if any)
              if (message.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    message.imageBytes!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Emotional tag badge (voice messages)
              if (message.isVoiceOrigin && message.emotionalTag != null)
                _EmotionTag(tag: message.emotionalTag!),

              // Content
              if (message.content.isNotEmpty)
                SmartChatText(
                  ResponseCleaner.clean(message.content),
                  color: _isUser
                      ? Colors.white
                      : Colors.white.withOpacity(0.85),
                ),

              // Voice origin indicator
              if (message.isVoiceOrigin && _isUser) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq_rounded,
                        size: 13,
                        color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'Voice message',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],

              // Read aloud (assistant only)
              if (!_isUser && message.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => VoiceController.speak(
                      ResponseCleaner.clean(message.content)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded,
                          size: 13,
                          color: _pink.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        'Read aloud',
                        style: TextStyle(
                          fontSize: 10,
                          color: _pink.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemBubble() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _pinkDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pink.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, size: 13, color: _pink),
            const SizedBox(width: 6),
            Text(
              message.content,
              style: const TextStyle(
                color: _pink,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thinking Bubble ───────────────────────────────────────────────────────────

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(30),
            topRight:    Radius.circular(30),
            bottomRight: Radius.circular(30),
            bottomLeft:  Radius.circular(6),
          ),
          border: Border.all(color: AppColors.borderMid),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Opacity(
            opacity: _anim.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shutter_speed_rounded,
                    size: 18,
                    color: _pink.withOpacity(_anim.value)),
                const SizedBox(width: 8),
                const Text(
                  'Community Heart is thinking...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Emotion Tag ───────────────────────────────────────────────────────────────

class _EmotionTag extends StatelessWidget {
  final String tag;
  const _EmotionTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _pinkDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pink.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, size: 12, color: _pink),
            const SizedBox(width: 4),
            Text(
              tag,
              style: const TextStyle(
                color: _pink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI State Chip ─────────────────────────────────────────────────────────────

class _AiStateChip extends StatelessWidget {
  final AiState aiState;
  const _AiStateChip({required this.aiState});

  @override
  Widget build(BuildContext context) {
    if (aiState == AiState.idle) return const SizedBox.shrink();

    final (label, icon, color) = switch (aiState) {
      AiState.thinking  => ('Thinking',  Icons.shutter_speed_rounded,  AppColors.primary2),
      AiState.listening => ('Listening', Icons.mic_rounded,             Colors.redAccent),
      AiState.speaking  => ('Speaking',  Icons.volume_up_rounded,       _pink),
      AiState.idle      => ('',          Icons.circle,                  Colors.transparent),
    };

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Accessibility Badge ───────────────────────────────────────────────────────

class _AccessBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _AccessBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voice Mic Button ──────────────────────────────────────────────────────────

class _VoiceMicButton extends StatelessWidget {
  final bool isRecording;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  const _VoiceMicButton({
    required this.isRecording,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: isRecording ? pulseAnim.value : 1.0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? Colors.redAccent : _pinkDim,
            border: Border.all(
              color: isRecording
                  ? Colors.redAccent
                  : _pink.withOpacity(0.4),
            ),
            boxShadow: isRecording
                ? [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : _pinkGlow,
          ),
          child: Icon(
            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            color: isRecording ? Colors.white : _pink,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Icon Circle Button ────────────────────────────────────────────────────────

class _IconCircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconCircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
