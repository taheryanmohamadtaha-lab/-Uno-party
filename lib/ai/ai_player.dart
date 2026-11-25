import 'dart:math';

import '../game_engine/uno_game.dart';
import '../models/uno_card.dart';

enum AiLevel { easy, medium, hard }

/// شخصیت رقیب: تعیین‌کنندهٔ سبک رفتاری هوش مصنوعی.
class AiPersonality {
  final String id;
  final String nameFa;
  final String nameEn;
  final String descriptionFa;

  /// تمایل به استفاده از کارت‌های حمله‌ای (۰ تا ۱).
  final double aggression;

  /// احتمال به‌خاطر آوردن اعلام UNO (۰ تا ۱).
  final double unoMemory;

  /// احتمال بلوف با +4 (در سطح Medium/Hard).
  final double bluff;

  /// احتمال اعتراض به +4 در حالت پایه (۰ تا ۱).
  final double challengeTendency;

  const AiPersonality({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.descriptionFa,
    required this.aggression,
    required this.unoMemory,
    required this.bluff,
    required this.challengeTendency,
  });
}

const List<AiPersonality> kAiPersonalities = [
  AiPersonality(
      id: 'rexi',
      nameFa: 'رکسی',
      nameEn: 'Rexi',
      descriptionFa: 'دایناسور شیطون؛ عاشق کارت‌های حمله',
      aggression: 0.9,
      unoMemory: 0.85,
      bluff: 0.35,
      challengeTendency: 0.5),
  AiPersonality(
      id: 'mimi',
      nameFa: 'میمی',
      nameEn: 'Mimi',
      descriptionFa: 'گربهٔ آرام و حسابگر',
      aggression: 0.35,
      unoMemory: 0.95,
      bluff: 0.05,
      challengeTendency: 0.3),
  AiPersonality(
      id: 'pixel',
      nameFa: 'پیکسل',
      nameEn: 'Pixel',
      descriptionFa: 'ربات دقیق؛ هیچ‌وقت UNO را فراموش نمی‌کند',
      aggression: 0.5,
      unoMemory: 1.0,
      bluff: 0.0,
      challengeTendency: 0.45),
  AiPersonality(
      id: 'luna',
      nameFa: 'لونا',
      nameEn: 'Luna',
      descriptionFa: 'دختر ستاره‌ای؛ رنگ‌ها را خوب می‌شناسد',
      aggression: 0.45,
      unoMemory: 0.9,
      bluff: 0.15,
      challengeTendency: 0.35),
  AiPersonality(
      id: 'zap',
      nameFa: 'زپ',
      nameEn: 'Zap',
      descriptionFa: 'سنجاب برقی؛ سریع و بی‌قرار',
      aggression: 0.75,
      unoMemory: 0.6,
      bluff: 0.3,
      challengeTendency: 0.6),
  AiPersonality(
      id: 'bobo',
      nameFa: 'بوبو',
      nameEn: 'Bobo',
      descriptionFa: 'خرس مهربان؛ کمی حواس‌پرت',
      aggression: 0.25,
      unoMemory: 0.5,
      bluff: 0.0,
      challengeTendency: 0.15),
  AiPersonality(
      id: 'frosty',
      nameFa: 'فراستی',
      nameEn: 'Frosty',
      descriptionFa: 'آدم‌برفی خونسرد؛ صبور و مقاوم',
      aggression: 0.4,
      unoMemory: 0.9,
      bluff: 0.1,
      challengeTendency: 0.4),
  AiPersonality(
      id: 'captain',
      nameFa: 'کاپیتان کیک',
      nameEn: 'Captain Cake',
      descriptionFa: 'دزد دریایی بلوف‌زن',
      aggression: 0.6,
      unoMemory: 0.75,
      bluff: 0.5,
      challengeTendency: 0.55),
];

sealed class AiAction {
  const AiAction();
}

class AiPlay extends AiAction {
  final String cardId;
  final CardColor? color;
  final int? swapTarget;
  const AiPlay(this.cardId, {this.color, this.swapTarget});
}

class AiDraw extends AiAction {
  const AiDraw();
}

class AiPass extends AiAction {
  const AiPass();
}

/// هوش مصنوعی. فقط از GameView استفاده می‌کند، پس به دست مخفی دیگران دسترسی ندارد.
class AiPlayer {
  final AiLevel level;
  final AiPersonality personality;
  final Random random;

  AiPlayer({
    required this.level,
    required this.personality,
    Random? random,
  }) : random = random ?? Random();

  // ------------------------------------------------------------ انتخاب رنگ

  CardColor chooseColor(List<UnoCard> hand) {
    const colors = [
      CardColor.red,
      CardColor.blue,
      CardColor.green,
      CardColor.yellow,
    ];
    if (level == AiLevel.easy && random.nextBool()) {
      return colors[random.nextInt(4)];
    }
    final counts = {for (final c in colors) c: 0};
    for (final card in hand) {
      if (!card.isWild) counts[card.color] = counts[card.color]! + 1;
    }
    final best = counts.values.fold<int>(0, max);
    final top = colors.where((c) => counts[c] == best).toList();
    return top[random.nextInt(top.length)];
  }

  // ------------------------------------------------------------ تصمیم نوبت

  AiAction decideTurn(GameView v) {
    final playable = v.playable;

    if (v.drawnCardId != null) {
      // بعد از کشیدن: فقط همان کارت. اگر قابل بازی است بازی می‌کنیم.
      for (final c in playable) {
        if (c.id == v.drawnCardId) return _playAction(v, c);
      }
      return const AiPass();
    }
    if (playable.isEmpty) return const AiDraw();

    if (level == AiLevel.easy) {
      return _playAction(v, playable[random.nextInt(playable.length)]);
    }

    UnoCard best = playable.first;
    double bestScore = -1e9;
    for (final c in playable) {
      final s = _score(v, c);
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return _playAction(v, best);
  }

  double _score(GameView v, UnoCard c) {
    final hard = level == AiLevel.hard;
    var s = random.nextDouble(); // شکستن تساوی
    final next = v.nextPlayer;
    final nextSize = v.handSizes[next];
    final others = [
      for (var i = 0; i < v.playerCount; i++)
        if (i != v.me) v.handSizes[i]
    ];
    final minOpp = others.reduce(min);
    final attackNow = nextSize <= 2 || minOpp <= 2;

    if (c.isWild) {
      // کارت‌های Wild تا حد امکان نگه داشته می‌شوند.
      s -= 15;
      if (v.playable.length == 1) s += 15;
      if (v.myHand.length <= 2) s += 20;
      if (c.type == CardType.wildDrawFour) {
        final legal = !v.myHand
            .any((x) => !x.isWild && x.color == v.activeColor);
        if (!legal) {
          s -= 25 * (1 - personality.bluff);
        }
        if (attackNow) s += 12;
        s += 8 * personality.aggression;
      }
    } else {
      s += 10;
      final sameColor = v.myHand
          .where((x) => !x.isWild && x.color == c.color && x.id != c.id)
          .length;
      s += 1.5 * sameColor;
      if (c.isNumber) s += (c.number ?? 0) / 3; // کارت‌های بزرگ‌تر را زودتر بریز
      if (!c.isNumber) {
        s += 4 + 6 * personality.aggression;
        if (attackNow) s += 14;
      }
      if (hard && c.type == CardType.reverse && v.playerCount > 2) {
        // اگر نفر بعدی کم‌کارت است Reverse خطر را برمی‌گرداند.
        final prev =
            (((v.me - v.direction) % v.playerCount) + v.playerCount) %
                v.playerCount;
        if (v.handSizes[prev] > nextSize) s += 8;
      }
    }

    if (hard) {
      // کارت‌های رنگی که حریف بعدی کم دارد برای ما امن‌ترند.
      final miss = v.missingColors[next];
      if (!c.isWild && miss.contains(c.color)) s += 3;
    }

    // با Stacking: کارت هم‌نوع روی جریمه را حتماً بگذار.
    if (v.pendingDraw > 0 && c.type == v.pendingType) s += 50;
    return s;
  }

  AiAction _playAction(GameView v, UnoCard c) {
    CardColor? color;
    if (c.isWild) {
      final rest = v.myHand.where((x) => x.id != c.id).toList();
      color = chooseColor(rest);
    }
    int? target;
    if (v.rules.sevenZero && c.isNumber && c.number == 7) {
      target = _bestSwapTarget(v);
    }
    return AiPlay(c.id, color: color, swapTarget: target);
  }

  int _bestSwapTarget(GameView v) {
    var best = -1;
    var bestSize = 1 << 30;
    for (var i = 0; i < v.playerCount; i++) {
      if (i == v.me) continue;
      if (v.handSizes[i] < bestSize) {
        bestSize = v.handSizes[i];
        best = i;
      }
    }
    return best;
  }

  // ------------------------------------------------------------ اعتراض +4

  /// آیا به +4 اعتراض کنیم؟ فقط با اطلاعات عمومی تصمیم می‌گیرد.
  bool shouldChallengePlusFour(GameView v) {
    if (level == AiLevel.easy) return random.nextDouble() < 0.1;
    final player = v.challengePlayer;
    final prev = v.challengePreviousColor;
    if (player == null || prev == null) return false;

    var p = personality.challengeTendency;
    if (level == AiLevel.hard) {
      // اگر دیده‌ایم این بازیکن رنگ قبلی را نداشته، احتمالاً +4 قانونی است.
      if (v.missingColors[player].contains(prev)) {
        p = 0.04;
      } else {
        p += 0.15;
      }
      // اگر هزینهٔ شکست (۶ کارت) برایمان خیلی سنگین است محتاط‌تر باش.
      if (v.myHand.length >= 10) p -= 0.15;
      // بازیکنی که کارت کم دارد معمولاً کارت رنگی هم کم دارد.
      if (v.handSizes[player] <= 3) p -= 0.1;
    }
    return random.nextDouble() < p.clamp(0.0, 0.95);
  }

  /// آیا هوش مصنوعی به‌موقع UNO را اعلام می‌کند؟
  bool remembersUno() => random.nextDouble() < personality.unoMemory;
}

/// اجرای یک اقدام برای بازیکن هوش مصنوعی روی موتور بازی.
/// خروجی: true یعنی اقدامی انجام شد.
bool runAiStep(UnoGame game, int p, AiPlayer ai) {
  switch (game.phase) {
    case TurnPhase.finished:
      return false;
    case TurnPhase.awaitingStartColor:
      if (game.current != p) return false;
      game.chooseStartColor(ai.chooseColor(game.hands[p]));
      return true;
    case TurnPhase.awaitingChallengeResponse:
      if (game.challenge?.victim != p) return false;
      final view = game.viewFor(p);
      if (ai.shouldChallengePlusFour(view)) {
        game.challengePlusFour();
      } else {
        game.acceptPlusFour();
      }
      return true;
    case TurnPhase.awaitingPlay:
      if (game.current != p) return false;
      final action = ai.decideTurn(game.viewFor(p));
      switch (action) {
        case AiPlay a:
          game.playCard(p, a.cardId,
              chosenColor: a.color, swapTarget: a.swapTarget);
          if (!game.isFinished &&
              game.hands[p].length == 1 &&
              ai.remembersUno()) {
            game.callUno(p);
          }
        case AiDraw():
          game.drawCard(p);
        case AiPass():
          game.passTurn(p);
      }
      return true;
  }
}
