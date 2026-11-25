import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_player.dart';
import '../rules/rules_config.dart';
import '../settings/settings_provider.dart';
import 'game_screen.dart';

/// انتخاب تعداد رقیب، سختی و قوانین اختیاری قبل از شروع بازی.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  int opponents = 2;
  AiLevel level = AiLevel.medium;
  int startCards = 7;
  bool stacking = false;
  bool sevenZero = false;
  bool jumpIn = false;
  bool drawUntil = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    const labelStyle = TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);

    Widget section(String key, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t(key), style: labelStyle),
              const SizedBox(height: 8),
              child,
            ],
          ),
        );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/menu_bg.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.7)),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(s.t('setup_title')),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      section(
                        'opponents',
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1')),
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                          ],
                          selected: {opponents},
                          onSelectionChanged: (v) =>
                              setState(() => opponents = v.first),
                        ),
                      ),
                      section(
                        'difficulty',
                        SegmentedButton<AiLevel>(
                          segments: [
                            ButtonSegment(
                                value: AiLevel.easy, label: Text(s.t('easy'))),
                            ButtonSegment(
                                value: AiLevel.medium,
                                label: Text(s.t('medium'))),
                            ButtonSegment(
                                value: AiLevel.hard, label: Text(s.t('hard'))),
                          ],
                          selected: {level},
                          onSelectionChanged: (v) =>
                              setState(() => level = v.first),
                        ),
                      ),
                      section(
                        'start_cards',
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 5, label: Text('5')),
                            ButtonSegment(value: 7, label: Text('7')),
                            ButtonSegment(value: 10, label: Text('10')),
                          ],
                          selected: {startCards},
                          onSelectionChanged: (v) =>
                              setState(() => startCards = v.first),
                        ),
                      ),
                      Text(s.t('optional_rules'), style: labelStyle),
                      SwitchListTile(
                        value: stacking,
                        title: Text(s.t('r_stacking')),
                        onChanged: (v) => setState(() => stacking = v),
                      ),
                      SwitchListTile(
                        value: sevenZero,
                        title: Text(s.t('r_sevenzero')),
                        onChanged: (v) => setState(() => sevenZero = v),
                      ),
                      SwitchListTile(
                        value: jumpIn,
                        title: Text(s.t('r_jumpin')),
                        onChanged: (v) => setState(() => jumpIn = v),
                      ),
                      SwitchListTile(
                        value: drawUntil,
                        title: Text(s.t('r_drawuntil')),
                        onChanged: (v) => setState(() => drawUntil = v),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GameScreen(
                              opponents: opponents,
                              level: level,
                              rules: RulesConfig(
                                stacking: stacking,
                                sevenZero: sevenZero,
                                jumpIn: jumpIn,
                                drawUntilPlayable: drawUntil,
                                startingCards: startCards,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Text(s.t('start_game'),
                          style: const TextStyle(fontSize: 18)),
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
