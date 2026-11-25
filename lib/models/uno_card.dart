/// مدل کارت‌های UNO (مستقل از رابط کاربری).
enum CardColor { red, blue, green, yellow, wild }

enum CardType { number, skip, reverse, drawTwo, wild, wildDrawFour }

class UnoCard {
  final String id;
  final CardColor color;
  final CardType type;

  /// فقط برای کارت‌های عددی (۰ تا ۹)، در غیر این صورت null.
  final int? number;

  const UnoCard({
    required this.id,
    required this.color,
    required this.type,
    this.number,
  });

  bool get isWild => type == CardType.wild || type == CardType.wildDrawFour;
  bool get isNumber => type == CardType.number;
  bool get isDrawCard =>
      type == CardType.drawTwo || type == CardType.wildDrawFour;

  /// امتیاز کارت برای محاسبهٔ امتیاز پایان دور.
  int get points {
    switch (type) {
      case CardType.number:
        return number ?? 0;
      case CardType.skip:
      case CardType.reverse:
      case CardType.drawTwo:
        return 20;
      case CardType.wild:
      case CardType.wildDrawFour:
        return 50;
    }
  }

  /// کارت «یکسان» (برای Jump-In): هم‌رنگ و هم‌نوع و هم‌عدد.
  bool isIdenticalTo(UnoCard other) =>
      color == other.color && type == other.type && number == other.number;

  @override
  String toString() => '${color.name}-${type.name}${number != null ? '-$number' : ''}';

  @override
  bool operator ==(Object other) => other is UnoCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.name,
        'type': type.name,
        'number': number,
      };

  factory UnoCard.fromJson(Map<String, dynamic> j) => UnoCard(
        id: j['id'] as String,
        color: CardColor.values.byName(j['color'] as String),
        type: CardType.values.byName(j['type'] as String),
        number: j['number'] as int?,
      );
}

/// ساخت دستهٔ استاندارد ۱۰۸ کارتی.
List<UnoCard> buildStandardDeck() {
  final cards = <UnoCard>[];
  const colors = [
    CardColor.red,
    CardColor.blue,
    CardColor.green,
    CardColor.yellow,
  ];
  for (final c in colors) {
    // یک کارت ۰ و دو کارت از هر عدد ۱ تا ۹
    cards.add(UnoCard(
        id: '${c.name}_n0_a', color: c, type: CardType.number, number: 0));
    for (var n = 1; n <= 9; n++) {
      for (final k in ['a', 'b']) {
        cards.add(UnoCard(
            id: '${c.name}_n${n}_$k',
            color: c,
            type: CardType.number,
            number: n));
      }
    }
    // دو کارت از هر کارت عملیاتی
    for (final t in [CardType.skip, CardType.reverse, CardType.drawTwo]) {
      for (final k in ['a', 'b']) {
        cards.add(UnoCard(id: '${c.name}_${t.name}_$k', color: c, type: t));
      }
    }
  }
  for (var i = 0; i < 4; i++) {
    cards.add(
        UnoCard(id: 'wild_$i', color: CardColor.wild, type: CardType.wild));
    cards.add(UnoCard(
        id: 'wild4_$i', color: CardColor.wild, type: CardType.wildDrawFour));
  }
  return cards;
}
