import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../services/ai_service.dart';
import '../services/voice_controller.dart';
import '../widgets/voice_language_picker.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen>
    with SingleTickerProviderStateMixin {
  final _picker       = ImagePicker();
  final _questionCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String _answer  = '';
  bool _loading   = false;
  bool _listening = false;
  bool _speaking  = false;

  // Scanner beam animation
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  static const _examples = [
    'Describe everything in detail',
    'What objects are here?',
    'Is there any text?',
    'What colors are present?',
    'Who is in this image?',
  ];

  @override
  void initState() {
    super.initState();
    VoiceController.initStt();
    VoiceController.initTts();
    
    // Print available voices for debugging
    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 500), () {
        VoiceController.printAvailableVoices();
      });
    }

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scanCtrl.dispose();
    VoiceController.stop();
    super.dispose();
  }

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    // Skip permission check on web - not supported
    if (!kIsWeb) {
      final perm = source == ImageSource.camera
          ? await Permission.camera.request()
          : await Permission.photos.request();
      if (perm.isDenied || perm.isPermanentlyDenied) {
        _snack('Permission denied. Enable it in Settings.');
        return;
      }
    }
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _imageBytes = bytes; _answer = ''; });
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _SheetTile(
              icon: Icons.image_search_rounded,
              label: 'Choose from Gallery',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            _SheetTile(
              icon: Icons.linked_camera_rounded,
              label: 'Take a Photo',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Voice ─────────────────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (_listening) {
      await VoiceController.stopListening();
      setState(() => _listening = false);
      return;
    }
    final perm = await Permission.microphone.request();
    if (perm.isDenied || perm.isPermanentlyDenied) {
      _snack('Microphone permission denied.');
      return;
    }
    setState(() => _listening = true);
    await VoiceController.startListening(
      onResult: (text, isFinal) {
        setState(() => _questionCtrl.text = text);
        if (isFinal) setState(() => _listening = false);
      },
    );
  }

  Future<void> _toggleSpeaking() async {
    if (_speaking) {
      await VoiceController.stop();
      setState(() => _speaking = false);
      return;
    }
    
    if (_answer.isEmpty) {
      _snack('No text to read');
      return;
    }
    
    setState(() => _speaking = true);
    try {
      await VoiceController.speak(_answer, onComplete: () {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (e) {
      debugPrint('[Vision] TTS Error: $e');
      _snack('Voice reading failed. Check browser permissions.');
      setState(() => _speaking = false);
    }
  }

  // ── Analyze ───────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_imageBytes == null) { _snack('Please select an image first.'); return; }
    final question = _questionCtrl.text.trim().isEmpty
        ? 'Describe everything in this image in rich detail for someone who cannot see.'
        : _questionCtrl.text.trim();

    setState(() { _loading = true; _answer = ''; });
    _scanCtrl.repeat(reverse: true);

    final raw    = await AiService.analyzeImage(imageBytes: _imageBytes!, question: question);
    final result = AiService.cleanResponse(raw);

    _scanCtrl.stop();
    _scanCtrl.reset();
    setState(() { _answer = result; _loading = false; });

    if (result.isNotEmpty && !result.startsWith('Error')) _toggleSpeaking();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageCard(),
            const SizedBox(height: 12),
            _buildSourceButtons(),
            const SizedBox(height: 16),
            _buildQuestionRow(),
            if (_listening) _buildListeningBadge(),
            const SizedBox(height: 16),
            _buildAnalyzeButton(),
            if (_answer.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildAnswerCard(),
            ],
            const SizedBox(height: 24),
            _buildExampleChips(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vision Assistant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          Text('For visually impaired users',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.5)),
        ],
      ),
      actions: const [
        VoiceLanguagePicker(),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageCard() {
    return GestureDetector(
      onTap: _showSourceSheet,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderMid),
          boxShadow: AppColors.primaryGlow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or placeholder
              if (_imageBytes != null)
                Image.memory(_imageBytes!, fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_center_focus_rounded,
                        size: 64, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to add an image',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

              // Scanner beam — only while analyzing
              if (_loading && _imageBytes != null)
                AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, __) => Positioned(
                    top: _scanAnim.value * 220,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // "Analyzing" overlay
              if (_loading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: Text(
                      'Analyzing...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButtons() {
    return Row(
      children: [
        Expanded(
          child: _OutlineBtn(
            icon: Icons.image_search_rounded,
            label: 'Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OutlineBtn(
            icon: Icons.linked_camera_rounded,
            label: 'Camera',
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _questionCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, letterSpacing: 0.5),
            decoration: const InputDecoration(
              hintText: 'Ask a question or tap the mic...',
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MicButton(listening: _listening, onTap: _toggleListening),
      ],
    );
  }

  Widget _buildListeningBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text('Listening...',
              style: TextStyle(color: Colors.redAccent, fontSize: 12,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _loading ? null : _analyze,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: _loading ? null : AppColors.buttonGradient,
          color: _loading ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading ? null : AppColors.subtleGlow,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70),
              )
            else
              const Icon(Icons.document_scanner_rounded,
                  size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              _loading ? 'Analyzing...' : 'Analyze Image',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMid),
        boxShadow: AppColors.primaryGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded,
                  size: 16, color: AppColors.primary2),
              const SizedBox(width: 8),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSpeaking,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _speaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    size: 18,
                    color: AppColors.primary2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white70,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Example questions',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map((q) => ActionChip(
                    label: Text(q),
                    onPressed: () => setState(() => _questionCtrl.text = q),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Local helper widgets ──────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary2, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(letterSpacing: 0.5, fontSize: 14)),
      onTap: onTap,
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderMid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white54),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;
  const _MicButton({required this.listening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: listening
              ? Colors.redAccent
              : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (listening ? Colors.redAccent : AppColors.primary)
                  .withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
