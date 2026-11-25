import 'dart:math';

import 'package:flutter/material.dart';

enum AvatarMood { neutral, happy, sad, surprised }

class _Look {
  final Color face;
  final Color accent;
  final String kind;
  const _Look(this.face, this.accent, this.kind);
}

const Map<String, _Look> _looks = {
  'you': _Look(Color(0xFFF8BBD0), Color(0xFFAD1457), 'human'),
  'rexi': _Look(Color(0xFF81C784), Color(0xFF2E7D32), 'dino'),
  'mimi': _Look(Color(0xFFFFCC80), Color(0xFFEF6C00), 'cat'),
  'pixel': _Look(Color(0xFFB0BEC5), Color(0xFF37474F), 'robot'),
  'luna': _Look(Color(0xFFCE93D8), Color(0xFF6A1B9A), 'star'),
  'zap': _Look(Color(0xFFFFE082), Color(0xFFF9A825), 'squirrel'),
  'bobo': _Look(Color(0xFFBCAAA4), Color(0xFF5D4037), 'bear'),
  'frosty': _Look(Color(0xFFE1F5FE), Color(0xFF0288D1), 'snowman'),
  'captain': _Look(Color(0xFFFFCCBC), Color(0xFFB71C1C), 'pirate'),
};

/// آواتار کارتونی که با کد کشیده می‌شود (بدون نیاز به فایل تصویر).
class CartoonAvatar extends StatelessWidget {
  final String id;
  final double size;
  final AvatarMood mood;

  const CartoonAvatar({
    super.key,
    required this.id,
    this.size = 56,
    this.mood = AvatarMood.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final look = _looks[id] ?? _looks['you']!;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AvatarPainter(look, mood)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final _Look look;
  final AvatarMood mood;
  _AvatarPainter(this.look, this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, size.height * 0.56);
    final r = w * 0.34;
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..color = Colors.black87;

    // پس‌زمینهٔ دایره‌ای
    fill.color = look.accent.withOpacity(0.35);
    canvas.drawCircle(Offset(w / 2, size.height / 2), w / 2, fill);

    // آیتم‌های بالای سر (گوش، شاخک، کلاه...)
    fill.color = look.accent;
    switch (look.kind) {
      case 'cat':
      case 'squirrel':
        for (final s in [-1.0, 1.0]) {
          final p = Path()
            ..moveTo(c.dx + s * r * 0.95, c.dy - r * 0.35)
            ..lineTo(c.dx + s * r * 0.75, c.dy - r * 1.35)
            ..lineTo(c.dx + s * r * 0.15, c.dy - r * 0.9)
            ..close();
          canvas.drawPath(p, fill);
        }
        break;
      case 'bear':
        for (final s in [-1.0, 1.0]) {
          canvas.drawCircle(
              Offset(c.dx + s * r * 0.8, c.dy - r * 0.85), r * 0.3, fill);
        }
        break;
      case 'dino':
        for (var i = -1; i <= 1; i++) {
          final x = c.dx + i * r * 0.5;
          final p = Path()
            ..moveTo(x - r * 0.2, c.dy - r * 0.9)
            ..lineTo(x, c.dy - r * 1.4)
            ..lineTo(x + r * 0.2, c.dy - r * 0.9)
            ..close();
          canvas.drawPath(p, fill);
        }
        break;
      case 'robot':
        canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy - r * 1.4),
            line..color = look.accent);
        canvas.drawCircle(Offset(c.dx, c.dy - r * 1.45), r * 0.15, fill);
        line.color = Colors.black87;
        break;
      case 'star':
        final starPath = Path();
        final cx = c.dx, cy = c.dy - r * 1.2;
        for (var i = 0; i < 10; i++) {
          final rad = (i.isEven ? r * 0.38 : r * 0.16);
          final a = -pi / 2 + i * pi / 5;
          final pt = Offset(cx + rad * cos(a), cy + rad * sin(a));
          if (i == 0) {
            starPath.moveTo(pt.dx, pt.dy);
          } else {
            starPath.lineTo(pt.dx, pt.dy);
          }
        }
        starPath.close();
        fill.color = const Color(0xFFFFD54F);
        canvas.drawPath(starPath, fill);
        break;
      case 'snowman':
        fill.color = Colors.black87;
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(c.dx, c.dy - r * 1.0),
                width: r * 1.5,
                height: r * 0.18),
            fill);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(c.dx, c.dy - r * 1.3),
                width: r * 0.9,
                height: r * 0.6),
            fill);
        break;
      case 'pirate':
        fill.color = look.accent;
        final hat = Path()
          ..moveTo(c.dx - r * 1.05, c.dy - r * 0.45)
          ..quadraticBezierTo(c.dx, c.dy - r * 1.7, c.dx + r * 1.05, c.dy - r * 0.45)
          ..close();
        canvas.drawPath(hat, fill);
        break;
      case 'human':
        fill.color = const Color(0xFF6D4C41);
        canvas.drawArc(
            Rect.fromCircle(center: c, radius: r * 1.08),
            pi,
            pi,
            true,
            fill);
        break;
    }

    // صورت
    fill.color = look.face;
    canvas.drawCircle(c, r, fill);

    // گونه‌ها
    fill.color = const Color(0xFFFF8A80).withOpacity(0.45);
    canvas.drawCircle(Offset(c.dx - r * 0.55, c.dy + r * 0.28), r * 0.17, fill);
    canvas.drawCircle(Offset(c.dx + r * 0.55, c.dy + r * 0.28), r * 0.17, fill);

    // چشم‌ها
    final eyeY = c.dy - r * 0.12;
    final eyeR = mood == AvatarMood.surprised ? r * 0.2 : r * 0.15;
    for (final s in [-1.0, 1.0]) {
      final e = Offset(c.dx + s * r * 0.4, eyeY);
      fill.color = Colors.white;
      canvas.drawCircle(e, eyeR * 1.35, fill);
      fill.color = Colors.black87;
      canvas.drawCircle(e, eyeR * 0.8, fill);
    }
    if (mood == AvatarMood.sad) {
      for (final s in [-1.0, 1.0]) {
        canvas.drawLine(
            Offset(c.dx + s * r * 0.7, eyeY - r * 0.42),
            Offset(c.dx + s * r * 0.2, eyeY - r * 0.28),
            line);
      }
    }

    // دهان
    final my = c.dy + r * 0.45;
    switch (mood) {
      case AvatarMood.happy:
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(c.dx, my - r * 0.1),
                width: r * 0.9,
                height: r * 0.6),
            0.1,
            pi - 0.2,
            false,
            line);
        break;
      case AvatarMood.sad:
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(c.dx, my + r * 0.2),
                width: r * 0.7,
                height: r * 0.45),
            pi + 0.2,
            pi - 0.4,
            false,
            line);
        break;
      case AvatarMood.surprised:
        fill.color = Colors.black87;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(c.dx, my + r * 0.05),
                width: r * 0.3,
                height: r * 0.4),
            fill);
        break;
      case AvatarMood.neutral:
        canvas.drawLine(Offset(c.dx - r * 0.25, my), Offset(c.dx + r * 0.25, my), line);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) =>
      old.mood != mood || old.look != look;
}
