/// تنظیمات قوانین. مقادیر پیش‌فرض = قوانین استاندارد (همهٔ قوانین اختیاری خاموش).
class RulesConfig {
  /// ۱) Stacking: روی +2 فقط +2 و روی +4 فقط +4 قابل انباشتن است.
  final bool stacking;

  /// ۲) قانون 7-0: بازی کارت ۰ = چرخش دست‌ها در جهت بازی؛ کارت ۷ = تعویض دست با بازیکن دلخواه.
  final bool sevenZero;

  /// ۳) Jump-In: کارت کاملاً یکسان (رنگ و عدد/نماد) را می‌توان خارج از نوبت بازی کرد.
  final bool jumpIn;

  /// ۴) کشیدن تا پیدا شدن کارت قابل بازی.
  final bool drawUntilPlayable;

  /// ۵) تعداد کارت‌های شروع (۳ تا ۱۰).
  final int startingCards;

  /// جریمهٔ فراموشی UNO (استاندارد: ۲ کارت).
  final int unoPenalty;

  const RulesConfig({
    this.stacking = false,
    this.sevenZero = false,
    this.jumpIn = false,
    this.drawUntilPlayable = false,
    this.startingCards = 7,
    this.unoPenalty = 2,
  }) : assert(startingCards >= 3 && startingCards <= 10);

  static const RulesConfig standard = RulesConfig();

  RulesConfig copyWith({
    bool? stacking,
    bool? sevenZero,
    bool? jumpIn,
    bool? drawUntilPlayable,
    int? startingCards,
    int? unoPenalty,
  }) =>
      RulesConfig(
        stacking: stacking ?? this.stacking,
        sevenZero: sevenZero ?? this.sevenZero,
        jumpIn: jumpIn ?? this.jumpIn,
        drawUntilPlayable: drawUntilPlayable ?? this.drawUntilPlayable,
        startingCards: startingCards ?? this.startingCards,
        unoPenalty: unoPenalty ?? this.unoPenalty,
      );

  Map<String, dynamic> toJson() => {
        'stacking': stacking,
        'sevenZero': sevenZero,
        'jumpIn': jumpIn,
        'drawUntilPlayable': drawUntilPlayable,
        'startingCards': startingCards,
        'unoPenalty': unoPenalty,
      };

  factory RulesConfig.fromJson(Map<String, dynamic> j) => RulesConfig(
        stacking: j['stacking'] as bool? ?? false,
        sevenZero: j['sevenZero'] as bool? ?? false,
        jumpIn: j['jumpIn'] as bool? ?? false,
        drawUntilPlayable: j['drawUntilPlayable'] as bool? ?? false,
        startingCards: j['startingCards'] as int? ?? 7,
        unoPenalty: j['unoPenalty'] as int? ?? 2,
      );
}
