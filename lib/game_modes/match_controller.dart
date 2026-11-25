import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../ai/ai_player.dart';
import '../game_engine/uno_game.dart';
import '../models/uno_card.dart';
import '../rules/rules_config.dart';
import '../widgets/avatar_widget.dart';

class MatchPlayer {
  final String id;
  final String nameFa;
  final String nameEn;
  final AiPlayer? ai;
  const MatchPlayer({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    this.ai,
  });
  bool get isHuman => ai == null;
}

/// پیام ساختاریافتهٔ آخرین رویداد (متن نهایی در رابط کاربری و بر اساس زبان ساخته می‌شود).
class MatchMessage {
  final String key;
  final int? p;
  final int? target;
  final int? count;
  const MatchMessage(this.key, {this.p, this.target, this.count});
}

/// بازی انسان (بازیکن ۰) در برابر ۱ تا ۳ رقیب کامپیوتری.
class MatchController extends ChangeNotifier {
  final RulesConfig rules;
  final AiLevel level;
  final Random _rnd;
  late final List<MatchPlayer> players;
  late final UnoGame game;
  late final List<AvatarMood> moods;

  MatchMessage? lastMessage;
  String? error;
  int errorCounter = 0;
  int lastPlayer = -1;
  int playCounter = 0;

  int _cursor = 0;
  Timer? _timer;
  bool _disposed = false;

  MatchController({
    required int opponents,
    required this.level,
    this.rules = RulesConfig.standard,
    Random? random,
  }) : _rnd = random ?? Random() {
    final pool = List<AiPersonality>.of(kAiPersonalities)..shuffle(_rnd);
    players = [
      const MatchPlayer(id: 'you', nameFa: 'شما', nameEn: 'You'),
      for (var i = 0; i < opponents; i++)
        MatchPlayer(
          id: pool[i].id,
          nameFa: pool[i].nameFa,
          nameEn: pool[i].nameEn,
          ai: AiPlayer(level: level, personality: pool[i], random: _rnd),
        ),
    ];
    game = UnoGame.newGame(
        playerCount: players.length, rules: rules, random: _rnd);
    moods = List<AvatarMood>.filled(players.length, AvatarMood.neutral);
  }

  int get actor => game.phase == TurnPhase.awaitingChallengeResponse
      ? (game.challenge?.victim ?? game.current)
      : game.current;

  bool get humanTurn => !game.isFinished && actor == 0;

  void start() {
    _processEvents();
    notifyListeners();
    _scheduleAi();
  }

  // ------------------------------------------------------------ هوش مصنوعی

  void _scheduleAi() {
    _timer?.cancel();
    if (_disposed || game.isFinished) return;
    if (actor == 0) return;
    _timer = Timer(Duration(milliseconds: 1000 + _rnd.nextInt(600)), _aiStep);
  }

  void _aiStep() {
    if (_disposed || game.isFinished) return;
    final a = actor;
    if (a == 0) return;
    final ai = players[a].ai!;

    // اگر انسان UNO نگفته باشد، رقیب‌ها ممکن است او را بگیرند.
    if (game.unoVulnerable == 0) {
      final chance = level == AiLevel.easy
          ? 0.2
          : (level == AiLevel.medium ? 0.5 : 0.85);
      if (_rnd.nextDouble() < chance) {
        game.catchUno(a);
      }
    }
    try {
      runAiStep(game, a, ai);
    } on IllegalMoveException {
      // راه‌حل امن: اگر تصمیم نامعتبر بود، کارت بکش یا رد کن.
      try {
        game.drawCard(a);
      } on IllegalMoveException {
        try {
          game.passTurn(a);
        } on IllegalMoveException {
          // هیچ اقدام دیگری ممکن نیست.
        }
      }
    }
    _afterMove();
  }

  // ------------------------------------------------------------ اقدام‌های انسان

  bool _human(void Function() action) {
    if (game.isFinished) return false;
    try {
      action();
    } on IllegalMoveException catch (e) {
      error = e.message;
      errorCounter++;
      notifyListeners();
      return false;
    }
    error = null;
    _afterMove();
    return true;
  }

  bool humanPlay(UnoCard card, {CardColor? color, int? swapTarget}) => _human(
      () => game.playCard(0, card.id, chosenColor: color, swapTarget: swapTarget));

  bool humanDraw() => _human(() => game.drawCard(0));
  bool humanPass() => _human(() => game.passTurn(0));
  bool humanUno() => _human(() => game.callUno(0));
  bool humanChallenge(bool challenge) => _human(() {
        if (challenge) {
          game.challengePlusFour();
        } else {
          game.acceptPlusFour();
        }
      });
  bool humanStartColor(CardColor c) => _human(() => game.chooseStartColor(c));
  bool humanCatch() => _human(() {
        if (!game.catchUno(0)) {
          throw const IllegalMoveException('کسی برای گرفتن نیست');
        }
      });

  void _afterMove() {
    _processEvents();
    notifyListeners();
    _scheduleAi();
  }

  // ------------------------------------------------------------ رویدادها

  void _processEvents() {
    for (var i = 0; i < moods.length; i++) {
      moods[i] = AvatarMood.neutral;
    }
    for (; _cursor < game.events.length; _cursor++) {
      final e = game.events[_cursor];
      switch (e.kind) {
        case 'play':
          lastPlayer = e.player;
          playCounter++;
          moods[e.player] = AvatarMood.happy;
          lastMessage = MatchMessage('msg_play', p: e.player);
          break;
        case 'skip':
          if (e.target != null) moods[e.target!] = AvatarMood.surprised;
          lastMessage = MatchMessage('msg_skip', target: e.target);
          break;
        case 'reverse':
          lastMessage = const MatchMessage('msg_reverse');
          break;
        case 'draw':
          moods[e.player] = AvatarMood.sad;
          lastMessage =
              MatchMessage('msg_draw', p: e.player, count: e.count ?? 1);
          break;
        case 'challenge':
          final ok = (e.count ?? 0) == 1;
          if (ok) {
            if (e.target != null) moods[e.target!] = AvatarMood.sad;
            lastMessage = MatchMessage('msg_challenge_ok', target: e.target);
          } else {
            moods[e.player] = AvatarMood.sad;
            lastMessage = MatchMessage('msg_challenge_fail', p: e.player);
          }
          break;
        case 'uno':
          moods[e.player] = AvatarMood.surprised;
          lastMessage = MatchMessage('msg_uno', p: e.player);
          break;
        case 'uno_penalty':
          moods[e.player] = AvatarMood.sad;
          lastMessage = MatchMessage('msg_uno_penalty', p: e.player);
          break;
        case 'swap':
          lastMessage = MatchMessage('msg_swap', p: e.player, target: e.target);
          break;
        case 'rotate':
          lastMessage = const MatchMessage('msg_rotate');
          break;
        case 'win':
          for (var i = 0; i < moods.length; i++) {
            moods[i] = i == e.player ? AvatarMood.happy : AvatarMood.sad;
          }
          break;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
