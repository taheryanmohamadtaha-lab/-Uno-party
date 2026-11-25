import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_provider.dart';
import 'game_setup_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _openSetup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameSetupScreen()),
    );
  }

  void _soon() {
    final s = ref.read(stringsProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.t('coming_soon'))));
  }

  void _showText(String titleKey, String bodyKey) {
    final s = ref.read(stringsProvider);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t(titleKey)),
        content: SingleChildScrollView(child: Text(s.t(bodyKey))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final items = <(String, VoidCallback)>[
      ('new_game', _openSetup),
      ('vs_ai', _openSetup),
      ('local_mp', _soon),
      ('tournament', _soon),
      ('characters', _soon),
      ('collection', _soon),
      ('stats', _soon),
      ('settings', _soon),
      ('rules', () => _showText('rules', 'rules_body')),
      ('about', () => _showText('about', 'about_body')),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/menu_bg.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      onPressed: () {
                        final cur = ref.read(localeProvider);
                        ref.read(localeProvider.notifier).state =
                            cur.languageCode == 'fa'
                                ? const Locale('en')
                                : const Locale('fa');
                      },
                      child: Text(s.t('language')),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, -8 * _float.value),
                    child: Transform.rotate(
                      angle: (_float.value - 0.5) * 0.08,
                      child: child,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/card_back_arcane.png',
                    height: 150,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.t('title'),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 12, color: Colors.purple)],
                  ),
                ),
                Text(
                  s.t('subtitle'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MenuButton(
                      label: s.t(items[i].$1),
                      onTap: items[i].$2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuButton({required this.label, required this.onTap});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2FF7), Color(0xFFB65CFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FF7).withOpacity(_down ? 0.2 : 0.55),
                blurRadius: _down ? 4 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
