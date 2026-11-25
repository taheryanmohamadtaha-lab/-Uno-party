import 'package:flutter/material.dart';

import '../models/uno_card.dart';

const double kCardAspect = 1.45;

Color unoColorOf(CardColor c) {
  switch (c) {
    case CardColor.red:
      return const Color(0xFFE53935);
    case CardColor.blue:
      return const Color(0xFF1E88E5);
    case CardColor.green:
      return const Color(0xFF43A047);
    case CardColor.yellow:
      return const Color(0xFFFDD835);
    case CardColor.wild:
      return const Color(0xFF37474F);
  }
}

/// دایرهٔ چهاررنگ (نماد Wild).
class WildDot extends StatelessWidget {
  final double size;
  const WildDot({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Column(
          children: [
            Expanded(
              child: Row(children: [
                Expanded(child: ColoredBox(color: unoColorOf(CardColor.red))),
                Expanded(child: ColoredBox(color: unoColorOf(CardColor.blue))),
              ]),
            ),
            Expanded(
              child: Row(children: [
                Expanded(child: ColoredBox(color: unoColorOf(CardColor.yellow))),
                Expanded(child: ColoredBox(color: unoColorOf(CardColor.green))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

Widget cardSymbol(UnoCard card, double size, Color color) {
  TextStyle style() => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1,
      );
  switch (card.type) {
    case CardType.number:
      return Text('${card.number}', style: style());
    case CardType.drawTwo:
      return Text('+2', style: style());
    case CardType.wildDrawFour:
      return Text('+4', style: style());
    case CardType.skip:
      return Icon(Icons.block, size: size, color: color);
    case CardType.reverse:
      return Icon(Icons.sync, size: size, color: color);
    case CardType.wild:
      return WildDot(size: size);
  }
}

/// روی کارت: گوشه‌های گرد، ضخامت، سایه، بیضی مرکزی و نماد.
class UnoCardFace extends StatelessWidget {
  final UnoCard card;
  final double width;
  final bool dimmed;

  const UnoCardFace({
    super.key,
    required this.card,
    required this.width,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * kCardAspect;
    final base = unoColorOf(card.color);
    final radius = BorderRadius.circular(width * 0.14);
    final edge = width * 0.045; // ضخامت کارت
    final symbolColor = card.color == CardColor.yellow
        ? const Color(0xFFB8860B)
        : (card.isWild ? Colors.black87 : base);

    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        children: [
          // ضخامت (لبهٔ تیره زیر کارت)
          Positioned(
            left: 0,
            right: 0,
            top: edge,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(base, Colors.black, 0.6),
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: width * 0.12,
                    offset: Offset(0, width * 0.06),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: edge,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Colors.white, width: width * 0.045),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(base, Colors.white, 0.28)!,
                    base,
                  ],
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                color: dimmed ? Colors.black.withOpacity(0.38) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.5,
                    child: Container(
                      width: width * 0.8,
                      height: h * 0.56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(width * 0.4, h * 0.28),
                        ),
                      ),
                    ),
                  ),
                  cardSymbol(card, width * 0.42, symbolColor),
                  Positioned(
                    left: width * 0.08,
                    top: width * 0.05,
                    child: cardSymbol(card, width * 0.17, Colors.white),
                  ),
                  Positioned(
                    right: width * 0.08,
                    bottom: width * 0.05,
                    child: Transform.rotate(
                      angle: 3.14159,
                      child: cardSymbol(card, width * 0.17, Colors.white),
                    ),
                  ),
                  // بازتاب نور
                  Positioned(
                    left: width * 0.06,
                    top: h * 0.02,
                    right: width * 0.06,
                    height: h * 0.18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// پشت کارت (تصویر ارائه‌شده توسط کاربر).
class UnoCardBack extends StatelessWidget {
  final double width;
  const UnoCardBack({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final h = width * kCardAspect;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: width * 0.14,
            offset: Offset(0, width * 0.07),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.14),
        child: Image.asset(
          'assets/images/card_back_arcane.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
