import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_player.dart';
import '../game_engine/uno_game.dart';
import '../game_modes/match_controller.dart';
import '../localization/strings.dart';
import '../models/uno_card.dart';
import '../rules/rules_config.dart';
import '../settings/settings_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/uno_card_widget.dart';

enum _Seat { bottom, left, top, right }

class GameScreen extends ConsumerStatefulWidget {
  final int opponents;
  final AiLevel level;
  final RulesConfig rules;

  const GameScreen({
    super.key,
    required this.opponents,
    required this.level,
    required this.rules,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late MatchController c;
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  bool _dialogOpen = false;
  bool _resultShown = false;
  int _lastErrorCount = 0;

  @override
  void initState() {
    super.initState();
    _newMatch();
  }

  void _newMatch() {
    c = MatchController(
      opponents: widget.opponents,
      level: widget.level,
      rules: widget.rules,
    );
    _lastErrorCount = 0;
    _resultShown = false;
    c.start();
    c.addListener(_onChange);
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    c.dispose();
    _spin.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ واکنش به تغییرات

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (c.errorCounter != _lastErrorCount) {
      _lastErrorCount = c.errorCounter;
      _shake.forward(from: 0);
      final msg = c.error;
      if (msg != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(msg),
            duration: const Duration(milliseconds: 1600),
            behavior: SnackBarBehavior.floating,
          ));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeDialogs());
  }

  void _maybeDialogs() {
    if (!mounted || _dialogOpen) return;
    final g = c.game;
    if (g.phase == TurnPhase.awaitingStartColor && g.current == 0) {
      _dialogOpen = true;
      _askColor().then((col) {
        _dialogOpen = false;
        c.humanStartColor(col ?? CardColor.red);
      });
    } else if (g.phase == TurnPhase.awaitingChallengeResponse &&
        g.challenge?.victim == 0) {
      _dialogOpen = true;
      _askChallenge().then((ch) {
        _dialogOpen = false;
        c.humanChallenge(ch ?? false);
      });
    } else if (g.isFinished && !_resultShown) {
      _resultShown = true;
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) _showResult();
      });
    }
  }

  // ------------------------------------------------------------ نام‌ها و متن‌ها

  String _name(Strings s, int i) {
    final p = c.players[i];
    if (p.isHuman) return s.t('you');
    return s.isFa ? p.nameFa : p.nameEn;
  }

  String _colorName(Strings s, CardColor col) {
    switch (col) {
      case CardColor.red:
        return s.t('c_red');
      case CardColor.blue:
        return s.t('c_blue');
      case CardColor.green:
        return s.t('c_green');
      case CardColor.yellow:
        return s.t('c_yellow');
      case CardColor.wild:
        return '';
    }
  }

  String _statusText(Strings s) {
    final g = c.game;
    if (g.isFinished) return '';
    if (c.humanTurn) return s.t('your_turn');
    return s.f('thinking', p: _name(s, c.actor));
  }

  String _lastText(Strings s) {
    final m = c.lastMessage;
    if (m == null) return '';
    return s.f(
      m.key,
      p: m.p == null ? null : _name(s, m.p!),
      t: m.target == null ? null : _name(s, m.target!),
      n: m.count,
    );
  }

  // ------------------------------------------------------------ گفتگوها

  Future<CardColor?> _askColor() {
    final s = ref.read(stringsProvider);
    return showDialog<CardColor>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1450), Color(0xFF14082B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(color: Colors.purple, blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.t('choose_color'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (final col in const [
                    CardColor.red,
                    CardColor.blue,
                    CardColor.green,
                    CardColor.yellow,
                  ])
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(col),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: unoColorOf(col),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: unoColorOf(col).withOpacity(0.8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _askTarget() {
    final s = ref.read(stringsProvider);
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('choose_target')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i < c.players.length; i++)
              ListTile(
                leading: CartoonAvatar(id: c.players[i].id, size: 40),
                title: Text(_name(s, i)),
                subtitle: Text('${c.game.hands[i].length}'),
                onTap: () => Navigator.of(ctx).pop(i),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _askChallenge() {
    final s = ref.read(stringsProvider);
    final g = c.game;
    final who = _name(s, g.challenge?.player ?? 1);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('challenge_title')),
        content: Text(s.f('challenge_body',
            p: who, c: _colorName(s, g.activeColor))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.t('accept_draw')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.t('challenge_btn')),
          ),
        ],
      ),
    );
  }

  void _showResult() {
    final s = ref.read(stringsProvider);
    final g = c.game;
    final w = g.winner ?? 0;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          w == 0 ? s.t('you_won') : s.f('player_won', p: _name(s, w)),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartoonAvatar(
              id: c.players[w].id,
              size: 90,
              mood: AvatarMood.happy,
            ),
            const SizedBox(height: 12),
            Text(s.f('score', n: g.roundScore)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(s.t('to_menu')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              c.removeListener(_onChange);
              c.dispose();
              setState(_newMatch);
            },
            child: Text(s.t('play_again')),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ اقدام‌های بازیکن

  Future<void> _onCardTap(UnoCard card) async {
    final g = c.game;
    if (g.isFinished || _dialogOpen) return;
    CardColor? color;
    int? target;
    if (g.canPlay(0, card)) {
      if (card.isWild) {
        _dialogOpen = true;
        color = await _askColor();
        _dialogOpen = false;
        if (color == null) return;
      }
      if (g.rules.sevenZero && card.isNumber && card.number == 7) {
        _dialogOpen = true;
        target = await _askTarget();
        _dialogOpen = false;
        if (target == null) return;
      }
    } else if (card.isWild) {
      color = CardColor.red; // فقط برای دریافت پیام خطای موتور
    }
    c.humanPlay(card, color: color, swapTarget: target);
  }

  // ------------------------------------------------------------ ساخت صفحه

  _Seat _seatOf(int playerIndex) {
    if (playerIndex == 0) return _Seat.bottom;
    final n = c.players.length - 1;
    if (n == 1) return _Seat.top;
    if (n == 2) return playerIndex == 1 ? _Seat.left : _Seat.right;
    switch (playerIndex) {
      case 1:
        return _Seat.left;
      case 2:
        return _Seat.top;
      default:
        return _Seat.right;
    }
  }

  Offset _fromOffset(int player) {
    if (player < 0) return Offset.zero;
    switch (_seatOf(player)) {
      case _Seat.bottom:
        return const Offset(0, 260);
      case _Seat.left:
        return const Offset(-230, 0);
      case _Seat.top:
        return const Offset(0, -230);
      case _Seat.right:
        return const Offset(230, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final g = c.game;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/menu_bg.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.55)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => _buildBoard(context, box, s),
            ),
          ),
          if (g.winner == 0) const IgnorePointer(child: _Confetti()),
        ],
      ),
    );
  }

  Widget _buildBoard(BuildContext context, BoxConstraints box, Strings s) {
    final g = c.game;
    final w = box.maxWidth;
    final h = box.maxHeight;
    final cardW = (w / 6.0).clamp(54.0, 84.0).toDouble();
    final handH = cardW * kCardAspect + 40;
    const topBar = 64.0;
    final regionH = h - topBar - handH;
    final tableD = min(w * 0.96, max(regionH, 120.0) / 0.62).toDouble();
    final pileW = (cardW * 0.95).clamp(50.0, 80.0).toDouble();

    return Stack(
      children: [
        // ----- نوار بالا
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: topBar,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _statusText(s),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      _lastText(s),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unoColorOf(g.activeColor),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: unoColorOf(g.activeColor).withOpacity(0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ----- ناحیهٔ میز
        Positioned(
          left: 0,
          right: 0,
          top: topBar,
          bottom: handH,
          child: Stack(
            children: [
              Center(child: _buildTable(tableD)),
              Center(child: _buildPiles(pileW)),
              for (var i = 1; i < c.players.length; i++) _buildSeat(i, s),
            ],
          ),
        ),

        // ----- آواتار و دکمه‌های بازیکن
        Positioned(
          left: 8,
          bottom: handH - 6,
          child: Row(
            children: [
              _avatarWithBadge(0, 52),
              const SizedBox(width: 6),
              Text(_name(s, 0),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Positioned(
          right: 8,
          bottom: handH + 4,
          child: _buildActions(s),
        ),

        // ----- دست بازیکن
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: handH,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                  sin(_shake.value * pi * 6) * 9 * (1 - _shake.value), 0),
              child: child,
            ),
            child: _buildHand(w, cardW, handH),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ میز سه‌بعدی

  Widget _buildTable(double d) {
    final g = c.game;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0011)
        ..rotateX(0.85),
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ضخامت میز
            Positioned(
              left: 0,
              right: 0,
              top: d * 0.035,
              bottom: -d * 0.035,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2B1608),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black87, blurRadius: 30, spreadRadius: 4),
                  ],
                ),
              ),
            ),
            // سطح میز + لبهٔ چوبی
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6D4220), width: d * 0.04),
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF5B3FD0),
                    Color(0xFF2A1B7A),
                    Color(0xFF140B3F),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // حلقهٔ نور رنگ فعال
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: d * 0.62,
              height: d * 0.62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: unoColorOf(g.activeColor).withOpacity(0.75),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: unoColorOf(g.activeColor).withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // فلش جهت چرخش
            AnimatedBuilder(
              animation: _spin,
              builder: (_, __) => Transform.rotate(
                angle: _spin.value * 2 * pi * g.direction,
                child: Icon(
                  g.direction == 1 ? Icons.rotate_right : Icons.rotate_left,
                  size: d * 0.8,
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
            ),
            // بازتاب نور
            Positioned(
              top: d * 0.06,
              left: d * 0.2,
              right: d * 0.2,
              height: d * 0.16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(d),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.14),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiles(double pileW) {
    final g = c.game;
    final top = g.topCard;
    final canDraw = c.humanTurn && g.drawnCardId == null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // دستهٔ برداشت
        GestureDetector(
          onTap: c.humanDraw,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: pileW + 8,
                height: pileW * kCardAspect + 8,
                child: Stack(
                  children: [
                    for (var i = 2; i >= 0; i--)
                      Positioned(
                        left: i * 2.0,
                        top: (2 - i) * 2.0,
                        child: UnoCardBack(width: pileW),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${g.drawPile.length}',
                style: TextStyle(
                  color: canDraw ? Colors.amber : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        // کارت روی زمین با انیمیشن پرتاب
        TweenAnimationBuilder<double>(
          key: ValueKey('${top.id}_${c.playCounter}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) {
            final from = _fromOffset(c.lastPlayer);
            return Transform.translate(
              offset: Offset(from.dx * (1 - t), from.dy * (1 - t)),
              child: Transform.rotate(
                angle: (1 - t) * 1.2 + 0.06,
                child: Transform.scale(scale: 1 + 0.45 * (1 - t), child: child),
              ),
            );
          },
          child: UnoCardFace(card: top, width: pileW * 1.1),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ رقیب‌ها

  Widget _avatarWithBadge(int i, double size) {
    final g = c.game;
    final active = !g.isFinished && c.actor == i;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: active
                ? const [
                    BoxShadow(
                        color: Colors.amber, blurRadius: 18, spreadRadius: 3)
                  ]
                : const [],
          ),
          child: CartoonAvatar(
            id: c.players[i].id,
            size: size,
            mood: c.moods[i],
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${g.hands[i].length}',
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeat(int i, Strings s) {
    final count = c.game.hands[i].length;
    final shown = min(count, 8);
    const cw = 22.0;
    const step = 9.0;
    final fan = shown == 0
        ? const SizedBox(height: cw * kCardAspect)
        : SizedBox(
            width: cw + step * (shown - 1),
            height: cw * kCardAspect,
            child: Stack(
              children: [
                for (var k = 0; k < shown; k++)
                  Positioned(left: k * step, child: UnoCardBack(width: cw)),
              ],
            ),
          );
    final seatWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _avatarWithBadge(i, 54),
        const SizedBox(height: 2),
        Text(
          _name(s, i),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        fan,
      ],
    );
    switch (_seatOf(i)) {
      case _Seat.left:
        return Align(
          alignment: const Alignment(-0.98, -0.25),
          child: seatWidget,
        );
      case _Seat.right:
        return Align(
          alignment: const Alignment(0.98, -0.25),
          child: seatWidget,
        );
      default:
        return Align(
          alignment: const Alignment(0, -1),
          child: seatWidget,
        );
    }
  }

  // ------------------------------------------------------------ دکمه‌ها

  Widget _buildActions(Strings s) {
    final g = c.game;
    final myCount = g.hands[0].length;
    final unoReady = !g.isFinished && (myCount <= 2 || g.unoVulnerable == 0);
    final canPass = c.humanTurn && g.drawnCardId != null;
    final canCatch = g.unoVulnerable != null && g.unoVulnerable != 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canCatch)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              onPressed: c.humanCatch,
              child: Text(s.t('catch_btn')),
            ),
          ),
        if (canPass)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              onPressed: c.humanPass,
              child: Text(s.t('pass_btn')),
            ),
          ),
        GestureDetector(
          onTap: unoReady ? c.humanUno : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: unoReady
                    ? const [Color(0xFFFF5252), Color(0xFFFFC107)]
                    : const [Color(0xFF616161), Color(0xFF424242)],
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: unoReady
                      ? Colors.redAccent.withOpacity(0.8)
                      : Colors.black54,
                  blurRadius: unoReady ? 18 : 6,
                ),
              ],
            ),
            child: Text(
              s.t('uno_btn'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ دست بازیکن

  Widget _buildHand(double w, double cardW, double handH) {
    final g = c.game;
    final hand = g.hands[0];
    final n = hand.length;
    if (n == 0) return const SizedBox.shrink();
    final avail = w - cardW - 24;
    final step = n <= 1 ? 0.0 : min(cardW * 0.78, avail / (n - 1)).toDouble();
    final total = cardW + step * (n - 1);
    final left0 = (w - total) / 2;
    final mid = (n - 1) / 2;
    final angleStep = min(0.06, 0.5 / max(n, 1)).toDouble();
    final myTurn = c.humanTurn;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < n; i++)
          Positioned(
            key: ValueKey(hand[i].id),
            left: left0 + step * i,
            top: 28 + pow((i - mid).abs(), 2).toDouble() * 1.2,
            child: _HandCard(
              card: hand[i],
              width: cardW,
              angle: (i - mid) * angleStep,
              playable: g.canPlay(0, hand[i]),
              dimmed: myTurn && !g.canPlay(0, hand[i]),
              onTap: () => _onCardTap(hand[i]),
            ),
          ),
      ],
    );
  }
}

class _HandCard extends StatelessWidget {
  final UnoCard card;
  final double width;
  final double angle;
  final bool playable;
  final bool dimmed;
  final VoidCallback onTap;

  const _HandCard({
    required this.card,
    required this.width,
    required this.angle,
    required this.playable,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, -150 * (1 - t)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transformAlignment: Alignment.bottomCenter,
          transform: Matrix4.translationValues(0, playable && !dimmed ? -14 : 0, 0)
            ..rotateZ(angle),
          child: UnoCardFace(card: card, width: width, dimmed: dimmed),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- جلوهٔ برد

class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_ctrl.value),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static final List<List<double>> _parts = () {
    final r = Random(5);
    return List.generate(
        70,
        (_) => [
              r.nextDouble(), // x
              0.4 + r.nextDouble() * 0.9, // سرعت
              r.nextDouble(), // فاز
              4 + r.nextDouble() * 6, // اندازه
              r.nextInt(4).toDouble(), // رنگ
            ]);
  }();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFFDD835),
    ];
    final paint = Paint();
    for (final p in _parts) {
      final y = ((t * p[1] + p[2]) % 1.0) * (size.height + 20) - 10;
      final x = p[0] * size.width + sin((t * 6 + p[2] * 10)) * 14;
      paint.color = colors[p[4].toInt()];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + p[2] * 6);
      canvas.drawRect(Rect.fromLTWH(0, 0, p[3], p[3] * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
