import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_party/ai/ai_player.dart';
import 'package:uno_party/game_modes/match_controller.dart';
import 'package:uno_party/rules/rules_config.dart';

void main() {
  test('کنترلر مسابقه: بازیکنان و رقیب‌های یکتا ساخته می‌شوند', () {
    final c = MatchController(
      opponents: 3,
      level: AiLevel.medium,
      rules: RulesConfig.standard,
      random: Random(3),
    );
    expect(c.players.length, 4);
    expect(c.players.first.isHuman, isTrue);
    expect(c.players.map((p) => p.id).toSet().length, 4);
    expect(c.game.totalCards, 108);
    c.dispose();
  });

  test('اقدام نامعتبر انسان خطا ثبت می‌کند و بازی را خراب نمی‌کند', () {
    final c = MatchController(
      opponents: 2,
      level: AiLevel.easy,
      random: Random(11),
    );
    // نوبت انسان نیست یا کارت نامعتبر است؛ در هر دو حالت یکی از این دو خطا می‌دهد.
    final ok = c.game.current == 0 ? c.humanPass() : c.humanDraw();
    expect(ok, isFalse);
    expect(c.errorCounter, 1);
    expect(c.error, isNotNull);
    expect(c.game.totalCards, 108);
    c.dispose();
  });
}
