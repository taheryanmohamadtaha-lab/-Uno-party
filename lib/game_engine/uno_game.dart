import 'dart:math';

import '../models/uno_card.dart';
import '../rules/rules_config.dart';

/// خطای حرکت غیرمجاز (پیام فارسی برای نمایش به کاربر).
class IllegalMoveException implements Exception {
  final String message;
  const IllegalMoveException(this.message);
  @override
  String toString() => 'IllegalMoveException: $message';
}

enum TurnPhase {
  awaitingPlay,
  awaitingStartColor,
  awaitingChallengeResponse,
  finished,
}

/// اطلاعات اعتراض +4. فیلد wasIllegal مخفی است و فقط موتور از آن استفاده می‌کند.
class ChallengeInfo {
  final int player;
  final int victim;
  final CardColor previousColor;
  final bool wasIllegal;
  const ChallengeInfo({
    required this.player,
    required this.victim,
    required this.previousColor,
    required this.wasIllegal,
  });
}

/// رویدادهای بازی برای انیمیشن و صدا در رابط کاربری.
class GameEvent {
  final String kind;
  final int player;
  final int? target;
  final int? count;
  const GameEvent(this.kind, this.player, {this.target, this.count});
  @override
  String toString() => 'GameEvent($kind, p$player, t$target, n$count)';
}

/// موتور قوانین UNO. کاملاً مستقل از رابط کاربری.
///
/// قراردادهای مهم:
/// - سر دستهٔ برداشت = آخرین عضو لیست drawPile، سر دستهٔ زمین = آخرین عضو discardPile.
/// - کارت شروع: عددی/Skip/Reverse/+2 اثر خود را می‌گذارد؛ Wild را بازیکن اول رنگ‌گذاری می‌کند؛
///   +4 به ته دسته برمی‌گردد و کارت دیگری رو می‌شود.
/// - Reverse در بازی دونفره مثل Skip است.
/// - اگر آخرین کارت بازیکن +2/+4 باشد، حریف آن را می‌کشد و اعتراض +4 رد می‌شود.
class UnoGame {
  final RulesConfig rules;
  final Random _random;
  final int playerCount;

  final List<List<UnoCard>> hands;
  final List<UnoCard> drawPile;
  final List<UnoCard> discardPile;

  int current = 0;
  int direction = 1; // 1 = رو به جلو، -1 = معکوس
  CardColor activeColor = CardColor.red;
  int pendingDraw = 0;
  CardType? pendingType;
  TurnPhase phase = TurnPhase.awaitingPlay;
  String? drawnCardId;
  ChallengeInfo? challenge;
  int? unoVulnerable;
  int? winner;
  late final List<bool> unoCalled;
  late final List<Set<CardColor>> missingColors;
  final List<GameEvent> events = [];

  UnoGame._(
    this.rules,
    this._random,
    this.playerCount,
    this.hands,
    this.drawPile,
    this.discardPile,
  ) {
    unoCalled = List<bool>.filled(playerCount, false);
    missingColors = List.generate(playerCount, (_) => <CardColor>{});
  }

  /// شروع بازی جدید با دستهٔ استاندارد.
  factory UnoGame.newGame({
    required int playerCount,
    RulesConfig rules = RulesConfig.standard,
    Random? random,
  }) {
    if (playerCount < 2 || playerCount > 10) {
      throw ArgumentError('تعداد بازیکنان باید بین ۲ تا ۱۰ باشد');
    }
    final rnd = random ?? Random();
    final deck = buildStandardDeck()..shuffle(rnd);
    final hands = List.generate(playerCount, (_) => <UnoCard>[]);
    for (var r = 0; r < rules.startingCards; r++) {
      for (var p = 0; p < playerCount; p++) {
        hands[p].add(deck.removeLast());
      }
    }
    // کارت شروع: +4 مجاز نیست و به ته دسته برمی‌گردد.
    UnoCard start = deck.removeLast();
    while (start.type == CardType.wildDrawFour) {
      deck.insert(0, start);
      start = deck.removeLast();
    }
    final game = UnoGame._(rules, rnd, playerCount, hands, deck, [start]);
    game._applyStartCard(start);
    return game;
  }

  /// ساخت وضعیت دلخواه (برای تست و بارگذاری بازی ذخیره‌شده).
  factory UnoGame.setup({
    required List<List<UnoCard>> hands,
    required List<UnoCard> drawPile,
    required UnoCard topCard,
    List<UnoCard> discardBelow = const [],
    CardColor? activeColor,
    int current = 0,
    int direction = 1,
    RulesConfig rules = RulesConfig.standard,
    Random? random,
  }) {
    final game = UnoGame._(
      rules,
      random ?? Random(1),
      hands.length,
      hands.map((h) => List<UnoCard>.of(h)).toList(),
      List<UnoCard>.of(drawPile),
      [...discardBelow, topCard],
    );
    game.current = current;
    game.direction = direction;
    game.activeColor = activeColor ?? topCard.color;
    return game;
  }

  // ---------------------------------------------------------------- شروع

  void _applyStartCard(UnoCard start) {
    final n = playerCount;
    current = 0;
    direction = 1;
    switch (start.type) {
      case CardType.number:
        activeColor = start.color;
        break;
      case CardType.wild:
        activeColor = CardColor.wild;
        phase = TurnPhase.awaitingStartColor;
        break;
      case CardType.skip:
        activeColor = start.color;
        current = 1 % n; // بازیکن اول رد می‌شود
        break;
      case CardType.reverse:
        activeColor = start.color;
        direction = -1;
        current = n - 1; // دیلر (آخرین نفر) شروع می‌کند
        break;
      case CardType.drawTwo:
        activeColor = start.color;
        _draw(0, 2);
        current = 1 % n;
        break;
      case CardType.wildDrawFour:
        throw StateError('کارت شروع نباید +4 باشد');
    }
  }

  /// بازیکن اول وقتی کارت شروع Wild است رنگ را انتخاب می‌کند.
  void chooseStartColor(CardColor color) {
    if (phase != TurnPhase.awaitingStartColor) {
      throw const IllegalMoveException('الان انتخاب رنگ شروع معنی ندارد');
    }
    if (color == CardColor.wild) {
      throw const IllegalMoveException('رنگ معتبر انتخاب کنید');
    }
    activeColor = color;
    phase = TurnPhase.awaitingPlay;
  }

  // ---------------------------------------------------------------- کمکی‌ها

  UnoCard get topCard => discardPile.last;
  bool get isFinished => phase == TurnPhase.finished;

  int _next(int from, [int steps = 1]) =>
      (((from + direction * steps) % playerCount) + playerCount) % playerCount;

  int nextPlayerIndex([int? from]) => _next(from ?? current);

  void _checkIndex(int p) {
    if (p < 0 || p >= playerCount) {
      throw const IllegalMoveException('بازیکن نامعتبر');
    }
  }

  bool _matchesTop(UnoCard card) {
    if (card.isWild) return true;
    if (card.color == activeColor) return true;
    final top = topCard;
    if (!top.isWild && card.type == top.type) {
      if (card.type == CardType.number) return card.number == top.number;
      return true;
    }
    return false;
  }

  /// آیا بازیکن p کارتی هم‌رنگ رنگ فعال دارد (برای مجاز بودن +4).
  bool hasActiveColorCard(int p, [CardColor? color]) {
    final c = color ?? activeColor;
    return hands[p].any((x) => !x.isWild && x.color == c);
  }

  String? _cardPlayError(int p, UnoCard card) {
    if (phase != TurnPhase.awaitingPlay) {
      return 'الان نمی‌توان کارت بازی کرد';
    }
    if (!hands[p].contains(card)) return 'این کارت در دست شما نیست';
    if (p != current) {
      if (!rules.jumpIn) return 'نوبت شما نیست';
      if (pendingDraw > 0 || drawnCardId != null) {
        return 'الان Jump-In ممکن نیست';
      }
      final top = topCard;
      if (top.isWild || !card.isIdenticalTo(top)) {
        return 'برای Jump-In کارت باید کاملاً یکسان باشد';
      }
      return null;
    }
    if (drawnCardId != null && card.id != drawnCardId) {
      return 'فقط می‌توانید همان کارت تازه‌کشیده را بازی کنید';
    }
    if (pendingDraw > 0) {
      if (rules.stacking && card.type == pendingType) return null;
      return 'باید کارت جریمه را بکشید';
    }
    if (!_matchesTop(card)) return 'این کارت با کارت روی زمین سازگار نیست';
    return null;
  }

  /// آیا بازیکن p همین الان می‌تواند این کارت را بازی کند؟
  bool canPlay(int p, UnoCard card) {
    _checkIndex(p);
    return _cardPlayError(p, card) == null;
  }

  List<UnoCard> playableCards(int p) =>
      hands[p].where((c) => canPlay(p, c)).toList();

  UnoCard _findInHand(int p, String cardId) {
    for (final c in hands[p]) {
      if (c.id == cardId) return c;
    }
    throw const IllegalMoveException('این کارت در دست شما نیست');
  }

  void _closeUnoWindow(int actor) {
    if (unoVulnerable != null && unoVulnerable != actor) unoVulnerable = null;
  }

  void _reshuffle() {
    if (discardPile.length <= 1) return;
    final top = discardPile.removeLast();
    drawPile.addAll(discardPile);
    discardPile
      ..clear()
      ..add(top);
    drawPile.shuffle(_random);
  }

  UnoCard? _drawOne(int p) {
    if (drawPile.isEmpty) _reshuffle();
    if (drawPile.isEmpty) return null;
    final c = drawPile.removeLast();
    hands[p].add(c);
    if (hands[p].length > 1) unoCalled[p] = false;
    if (unoVulnerable == p) unoVulnerable = null;
    return c;
  }

  List<UnoCard> _draw(int p, int count) {
    final drawn = <UnoCard>[];
    for (var i = 0; i < count; i++) {
      final c = _drawOne(p);
      if (c == null) break;
      drawn.add(c);
    }
    if (drawn.isNotEmpty) {
      events.add(GameEvent('draw', p, count: drawn.length));
    }
    return drawn;
  }

  // ---------------------------------------------------------------- بازی کردن

  /// بازی کردن کارت. برای Wild، chosenColor الزامی است؛
  /// برای کارت ۷ در قانون 7-0، swapTarget الزامی است.
  void playCard(
    int p,
    String cardId, {
    CardColor? chosenColor,
    int? swapTarget,
  }) {
    _checkIndex(p);
    final card = _findInHand(p, cardId);
    final err = _cardPlayError(p, card);
    if (err != null) throw IllegalMoveException(err);

    if (card.isWild && (chosenColor == null || chosenColor == CardColor.wild)) {
      throw const IllegalMoveException('برای کارت Wild باید رنگ انتخاب کنید');
    }
    final isSeven = rules.sevenZero && card.isNumber && card.number == 7;
    if (isSeven) {
      if (swapTarget == null ||
          swapTarget == p ||
          swapTarget < 0 ||
          swapTarget >= playerCount) {
        throw const IllegalMoveException('برای کارت ۷ باید بازیکن دیگری را انتخاب کنید');
      }
    }

    _closeUnoWindow(p);
    final previousColor = activeColor;
    final hadColorCard = hasActiveColorCard(p, previousColor);

    hands[p].remove(card);
    discardPile.add(card);
    activeColor = card.isWild ? chosenColor! : card.color;
    missingColors[p].remove(card.color);
    current = p; // مهم برای Jump-In
    drawnCardId = null;
    events.add(GameEvent('play', p));

    final victim = _next(p);

    // برد: اگر آخرین کارت +2/+4 بود، حریف ابتدا جریمه را می‌کشد.
    if (hands[p].isEmpty) {
      var total = pendingDraw;
      if (card.type == CardType.drawTwo) total += 2;
      if (card.type == CardType.wildDrawFour) total += 4;
      if (total > 0) _draw(victim, total);
      pendingDraw = 0;
      pendingType = null;
      winner = p;
      phase = TurnPhase.finished;
      events.add(GameEvent('win', p));
      return;
    }

    var handsChanged = false;
    switch (card.type) {
      case CardType.number:
        if (rules.sevenZero && card.number == 0) {
          _rotateHands();
          handsChanged = true;
        } else if (isSeven) {
          _swapHands(p, swapTarget!);
          handsChanged = true;
        }
        current = _next(p);
        break;
      case CardType.skip:
        current = _next(p, 2);
        events.add(GameEvent('skip', p, target: victim));
        break;
      case CardType.reverse:
        direction = -direction;
        current = playerCount == 2 ? p : _next(p);
        events.add(GameEvent('reverse', p));
        break;
      case CardType.drawTwo:
        if (rules.stacking) {
          pendingDraw += 2;
          pendingType = CardType.drawTwo;
          current = victim;
        } else {
          _draw(victim, 2);
          current = _next(p, 2);
        }
        break;
      case CardType.wild:
        current = victim;
        break;
      case CardType.wildDrawFour:
        if (rules.stacking && pendingDraw > 0) {
          pendingDraw += 4;
          pendingType = CardType.wildDrawFour;
          current = victim;
        } else {
          challenge = ChallengeInfo(
            player: p,
            victim: victim,
            previousColor: previousColor,
            wasIllegal: hadColorCard,
          );
          phase = TurnPhase.awaitingChallengeResponse;
          current = victim;
        }
        break;
    }

    // بعد از چرخش/تعویض دست، تعداد کارت‌ها از بازی کردن نیامده؛ جریمهٔ UNO معنی ندارد.
    if (!handsChanged) _updateUnoStatus(p);
  }

  void _rotateHands() {
    final old = hands.map((h) => List<UnoCard>.of(h)).toList();
    for (var i = 0; i < playerCount; i++) {
      final to = _next(i);
      hands[to]
        ..clear()
        ..addAll(old[i]);
    }
    for (var i = 0; i < playerCount; i++) {
      unoCalled[i] = false;
    }
    unoVulnerable = null;
    events.add(const GameEvent('rotate', 0));
  }

  void _swapHands(int a, int b) {
    final tmp = List<UnoCard>.of(hands[a]);
    hands[a]
      ..clear()
      ..addAll(hands[b]);
    hands[b]
      ..clear()
      ..addAll(tmp);
    unoCalled[a] = false;
    unoCalled[b] = false;
    unoVulnerable = null;
    events.add(GameEvent('swap', a, target: b));
  }

  void _updateUnoStatus(int p) {
    if (hands[p].length == 1) {
      if (!unoCalled[p]) unoVulnerable = p;
    } else {
      unoCalled[p] = false;
    }
  }

  // ---------------------------------------------------------------- اعتراض +4

  void _requireChallenge() {
    if (phase != TurnPhase.awaitingChallengeResponse || challenge == null) {
      throw const IllegalMoveException('الان +4 برای پاسخ وجود ندارد');
    }
  }

  /// قبول +4: حریف ۴ کارت می‌کشد و نوبتش می‌سوزد
  /// (با Stacking: جریمه روی حریف می‌ماند و می‌تواند +4 دیگری روی آن بگذارد).
  void acceptPlusFour() {
    _requireChallenge();
    final ch = challenge!;
    _closeUnoWindow(ch.victim);
    if (rules.stacking) {
      pendingDraw = 4;
      pendingType = CardType.wildDrawFour;
      current = ch.victim;
    } else {
      _draw(ch.victim, 4);
      current = _next(ch.victim);
    }
    challenge = null;
    phase = TurnPhase.awaitingPlay;
  }

  /// اعتراض به +4. اگر غیرمجاز بود بازیکن خاطی ۴ کارت می‌کشد و حریف عادی بازی می‌کند؛
  /// اگر مجاز بود معترض ۶ کارت می‌کشد و نوبتش می‌سوزد.
  /// خروجی: true یعنی اعتراض موفق بود.
  bool challengePlusFour() {
    _requireChallenge();
    final ch = challenge!;
    _closeUnoWindow(ch.victim);
    bool success;
    if (ch.wasIllegal) {
      _draw(ch.player, 4);
      current = ch.victim;
      success = true;
    } else {
      _draw(ch.victim, 6);
      current = _next(ch.victim);
      success = false;
    }
    events.add(GameEvent('challenge', ch.victim,
        target: ch.player, count: success ? 1 : 0));
    challenge = null;
    phase = TurnPhase.awaitingPlay;
    return success;
  }

  // ---------------------------------------------------------------- کشیدن / رد کردن

  /// کشیدن کارت. با جریمهٔ معلق (Stacking) همه را می‌کشد و نوبتش می‌سوزد.
  List<UnoCard> drawCard(int p) {
    _checkIndex(p);
    if (phase != TurnPhase.awaitingPlay) {
      throw const IllegalMoveException('الان نمی‌توان کارت کشید');
    }
    if (p != current) throw const IllegalMoveException('نوبت شما نیست');
    if (drawnCardId != null) {
      throw const IllegalMoveException('در این نوبت یک بار کارت کشیده‌اید');
    }
    _closeUnoWindow(p);

    if (pendingDraw > 0) {
      final drawn = _draw(p, pendingDraw);
      pendingDraw = 0;
      pendingType = null;
      current = _next(p);
      return drawn;
    }

    if (rules.drawUntilPlayable) {
      final drawn = <UnoCard>[];
      while (true) {
        final c = _drawOne(p);
        if (c == null) break;
        drawn.add(c);
        if (_matchesTop(c)) {
          drawnCardId = c.id;
          break;
        }
      }
      if (drawn.isNotEmpty) {
        events.add(GameEvent('draw', p, count: drawn.length));
      }
      if (drawnCardId == null) {
        _markMissing(p);
        current = _next(p);
      }
      return drawn;
    }

    final c = _drawOne(p);
    if (c == null) {
      current = _next(p);
      return [];
    }
    events.add(GameEvent('draw', p, count: 1));
    if (_matchesTop(c)) {
      drawnCardId = c.id; // فقط همین کارت قابل بازی است
    } else {
      _markMissing(p);
      current = _next(p);
    }
    return [c];
  }

  void _markMissing(int p) {
    if (activeColor != CardColor.wild) missingColors[p].add(activeColor);
  }

  /// پایان نوبت بعد از کشیدن کارت قابل‌بازی (بازیکن نمی‌خواهد آن را بازی کند).
  void passTurn(int p) {
    _checkIndex(p);
    if (phase != TurnPhase.awaitingPlay ||
        p != current ||
        drawnCardId == null) {
      throw const IllegalMoveException('الان نمی‌توان نوبت را رد کرد');
    }
    drawnCardId = null;
    current = _next(p);
  }

  // ---------------------------------------------------------------- UNO

  /// اعلام UNO: پیش از بازی کارت (با ۲ کارت) یا بلافاصله بعد از آن (قبل از اقدام نفر بعد).
  void callUno(int p) {
    _checkIndex(p);
    if (unoVulnerable == p) {
      unoVulnerable = null;
      unoCalled[p] = true;
      events.add(GameEvent('uno', p));
      return;
    }
    if (hands[p].length <= 2 && phase != TurnPhase.finished) {
      unoCalled[p] = true;
      events.add(GameEvent('uno', p));
      return;
    }
    throw const IllegalMoveException('الان نمی‌توانید UNO بگویید');
  }

  /// گرفتن بازیکنی که UNO نگفته. اگر موفق باشد خاطی جریمه می‌شود.
  bool catchUno(int accuser) {
    _checkIndex(accuser);
    final v = unoVulnerable;
    if (v == null || v == accuser) return false;
    _draw(v, rules.unoPenalty);
    unoVulnerable = null;
    events.add(GameEvent('uno_penalty', v, target: accuser));
    return true;
  }

  // ---------------------------------------------------------------- امتیاز

  /// امتیاز دور برای برنده: مجموع امتیاز کارت‌های باقی‌مانده حریفان.
  int get roundScore {
    if (winner == null) return 0;
    var sum = 0;
    for (var i = 0; i < playerCount; i++) {
      if (i == winner) continue;
      for (final c in hands[i]) {
        sum += c.points;
      }
    }
    return sum;
  }

  /// مجموع تمام کارت‌ها در بازی (باید همیشه ۱۰۸ باشد، مگر در setup سفارشی).
  int get totalCards =>
      hands.fold<int>(0, (a, h) => a + h.length) +
      drawPile.length +
      discardPile.length;

  // ---------------------------------------------------------------- دید عمومی

  /// فقط اطلاعاتی که بازیکن p طبق قوانین می‌بیند (برای هوش مصنوعی و بازی محلی).
  GameView viewFor(int p) {
    _checkIndex(p);
    final ch = challenge;
    return GameView(
      me: p,
      myHand: List<UnoCard>.unmodifiable(hands[p]),
      playable: List<UnoCard>.unmodifiable(
          phase == TurnPhase.awaitingPlay ? playableCards(p) : <UnoCard>[]),
      topCard: topCard,
      activeColor: activeColor,
      handSizes: List<int>.unmodifiable(hands.map((h) => h.length)),
      current: current,
      direction: direction,
      pendingDraw: pendingDraw,
      pendingType: pendingType,
      phase: phase,
      drawnCardId: drawnCardId,
      challengePlayer: ch?.player,
      challengeVictim: ch?.victim,
      challengePreviousColor: ch?.previousColor,
      missingColors:
          missingColors.map((s) => Set<CardColor>.unmodifiable(s)).toList(),
      drawPileSize: drawPile.length,
      unoVulnerable: unoVulnerable,
      rules: rules,
    );
  }
}

/// دید عمومی بازیکن؛ شامل هیچ اطلاعات مخفی از دست‌های دیگران نیست.
class GameView {
  final int me;
  final List<UnoCard> myHand;
  final List<UnoCard> playable;
  final UnoCard topCard;
  final CardColor activeColor;
  final List<int> handSizes;
  final int current;
  final int direction;
  final int pendingDraw;
  final CardType? pendingType;
  final TurnPhase phase;
  final String? drawnCardId;
  final int? challengePlayer;
  final int? challengeVictim;
  final CardColor? challengePreviousColor;
  final List<Set<CardColor>> missingColors;
  final int drawPileSize;
  final int? unoVulnerable;
  final RulesConfig rules;

  const GameView({
    required this.me,
    required this.myHand,
    required this.playable,
    required this.topCard,
    required this.activeColor,
    required this.handSizes,
    required this.current,
    required this.direction,
    required this.pendingDraw,
    required this.pendingType,
    required this.phase,
    required this.drawnCardId,
    required this.challengePlayer,
    required this.challengeVictim,
    required this.challengePreviousColor,
    required this.missingColors,
    required this.drawPileSize,
    required this.unoVulnerable,
    required this.rules,
  });

  int get playerCount => handSizes.length;
  int get nextPlayer =>
      (((me + direction) % playerCount) + playerCount) % playerCount;
}
