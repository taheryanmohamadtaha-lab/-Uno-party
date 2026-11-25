import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_party/ai/ai_player.dart';
import 'package:uno_party/game_engine/uno_game.dart';
import 'package:uno_party/rules/rules_config.dart';

int _actor(UnoGame g) => g.phase == TurnPhase.awaitingChallengeResponse
    ? g.challenge!.victim
    : g.current;

/// یک بازی کامل هوش مصنوعی علیه هوش مصنوعی و بررسی ناوردایی‌ها.
UnoGame _playFullGame(int seed, int players, RulesConfig rules,
    List<AiLevel> levels) {
  final rnd = Random(seed);
  final game = UnoGame.newGame(
      playerCount: players, rules: rules, random: rnd);
  final ais = [
    for (var i = 0; i < players; i++)
      AiPlayer(
        level: levels[i % levels.length],
        personality: kAiPersonalities[(seed + i) % kAiPersonalities.length],
        random: rnd,
      )
  ];
  var steps = 0;
  while (!game.isFinished && steps < 20000) {
    final p = _actor(game);
    final acted = runAiStep(game, p, ais[p]);
    expect(acted, isTrue, reason: 'هوش مصنوعی باید اقدام کند (seed $seed)');
    expect(game.totalCards, 108, reason: 'تعداد کل کارت‌ها ثابت است');
    steps++;
  }
  return game;
}

void main() {
  test('۸ شخصیت اختصاصی با نام یکتا وجود دارد', () {
    expect(kAiPersonalities.length, greaterThanOrEqualTo(8));
    expect(kAiPersonalities.map((p) => p.id).toSet().length,
        kAiPersonalities.length);
  });

  for (final level in AiLevel.values) {
    test('بازی کامل با هوش مصنوعی ${level.name} تمام می‌شود', () {
      for (var seed = 0; seed < 40; seed++) {
        final players = 2 + seed % 3;
        final g = _playFullGame(
            seed, players, RulesConfig.standard, [level]);
        expect(g.isFinished, isTrue, reason: 'seed $seed');
        expect(g.winner, isNotNull);
        expect(g.hands[g.winner!], isEmpty);
      }
    });
  }

  test('بازی کامل با همهٔ قوانین اختیاری', () {
    const rules = RulesConfig(
      stacking: true,
      sevenZero: true,
      jumpIn: true,
      drawUntilPlayable: true,
      startingCards: 5,
    );
    for (var seed = 100; seed < 130; seed++) {
      final g = _playFullGame(seed, 2 + seed % 3, rules, AiLevel.values);
      expect(g.isFinished, isTrue, reason: 'seed $seed');
    }
  });

  test('هوش مصنوعی فقط اطلاعات عمومی می‌بیند', () {
    final g = UnoGame.newGame(playerCount: 4, random: Random(7));
    final v = g.viewFor(2);
    expect(v.myHand, g.hands[2]);
    // تنها اطلاعات دربارهٔ دیگران: تعداد کارت و رنگ‌هایی که ندارند
    expect(v.handSizes.length, 4);
    expect(v.missingColors.length, 4);
  });
}
