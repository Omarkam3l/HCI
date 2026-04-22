import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/landing_screen.dart';
import 'screens/vision_screen.dart';
import 'screens/image_gen_screen.dart';
import 'screens/social_lounge_screen.dart';
import 'state/lounge_state.dart';
import 'widgets/glass_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.scaffold,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AiDemoApp());
}

class AiDemoApp extends StatelessWidget {
  const AiDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoungeState(),
      child: MaterialApp(
        title: 'AI Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const RootNavigator(),
      ),
    );
  }
}

// ── Root: Landing → Home transition ──────────────────────────────────────────

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  bool _showLanding = true;

  void _enter() {
    setState(() => _showLanding = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: _showLanding
          ? LandingScreen(key: const ValueKey('landing'), onEnter: _enter)
          : const HomeScreen(key: ValueKey('home')),
    );
  }
}

// ── Home (main app with nav) ──────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    VisionScreen(),
    ImageGenScreen(),
    SocialLoungeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
