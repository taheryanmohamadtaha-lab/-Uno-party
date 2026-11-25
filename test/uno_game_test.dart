import 'package:flutter_test/flutter_test.dart';
import 'package:uno_party/game_engine/uno_game.dart';
import 'package:uno_party/models/uno_card.dart';
import 'package:uno_party/rules/rules_config.dart';

int _seq = 0;

UnoCard num_(CardColor c, int n) => UnoCard(
    id: '${c.name}_$n#${_seq++}', color: c, type: CardType.number, number: n);
UnoCard act(CardColor c, CardType t) =>
    UnoCard(id: '${c.name}_${t.name}#${_seq++}', color: c, type: t);
UnoCard wild() =>
    UnoCard(id: 'wild#${_seq++}', color: CardColor.wild, type: CardType.wild);
UnoCard wild4() => UnoCard(
    id: 'wild4#${_seq++}',
    color: CardColor.wild,
    type: CardType.wildDrawFour);

const R = CardColor.red;
const B = CardColor.blue;
const G = CardColor.green;
const Y = CardColor.yellow;

/// ۱۲ کارت پرکننده برای دستهٔ برداشت (از ته لیست برداشته می‌شود).
List<UnoCard> filler([int n = 12]) =>
    List.generate(n, (i) => num_(i.isEven ? G : Y, (i % 4) + 1));

/// دست سه‌کارتی بی‌خطر (آبی/سبز) که با کارت قرمز شروع سازگار نیست.
List<UnoCard> safeHand() => [num_(B, 1), num_(G, 2), num_(B, 3)];

void main() {
  group('دسته کارت', () {
    test('۱۰۸ کارت با ترکیب استاندارد', () {
      final deck = buildStandardDeck();
      expect(deck.length, 108);
      expect(deck.map((c) => c.id).toSet().length, 108);
      expect(deck.where((c) => c.type == CardType.wild).length, 4);
      expect(deck.where((c) => c.type == CardType.wildDrawFour).length, 4);
      for (final color in [R, B, G, Y]) {
        final of = deck.where((c) => c.color == color).toList();
        expect(of.length, 25);
        expect(of.where((c) => c.number == 0).length, 1);
        for (var n = 1; n <= 9; n++) {
          expect(of.where((c) => c.number == n).length, 2);
        }
        for (final t in [CardType.skip, CardType.reverse, CardType.drawTwo]) {
          expect(of.where((c) => c.type == t).length, 2);
        }
      }
    });

    test('امتیاز کارت‌ها', () {
      expect(num_(R, 7).points, 7);
      expect(act(R, CardType.skip).points, 20);
      expect(wild().points, 50);
      expect(wild4().points, 50);
    });
  });

  group('شروع بازی', () {
    for (final players in [2, 3, 4]) {
      test('توزیع کارت برای $players بازیکن', () {
        for (var i = 0; i < 50; i++) {
          final g = UnoGame.newGame(playerCount: players);
          for (final h in g.hands) {
            // اگر کارت شروع +2 باشد بازیکن اول ۲ کارت اضافه می‌گیرد
            expect(h.length == 7 || h.length == 9, isTrue);
          }
          expect(g.totalCards, 108);
          expect(g.discardPile.length, 1);
          expect(g.topCard.type == CardType.wildDrawFour, isFalse);
          expect(g.current >= 0 && g.current < players, isTrue);
        }
      });
    }

    test('تعداد کارت‌های شروع قابل تنظیم است', () {
      final g = UnoGame.newGame(
          playerCount: 3, rules: const RulesConfig(startingCards: 5));
      expect(g.totalCards, 108);
      expect(g.hands[2].length, 5);
    });
  });

  group('بازی کردن کارت', () {
    test('کارت هم‌رنگ و هم‌عدد مجاز و کارت نامرتبط غیرمجاز', () {
      final r7 = num_(R, 7);
      final b5 = num_(B, 5);
      final b9 = num_(B, 9);
      final g = UnoGame.setup(
        hands: [
          [r7, b5, b9],
          safeHand(),
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      expect(() => g.playCard(0, b9.id), throwsA(isA<IllegalMoveException>()));
      g.playCard(0, r7.id);
      expect(g.current, 1);
      expect(g.topCard, r7);
      expect(g.hands[0].length, 2);
    });

    test('کارت هم‌عدد با رنگ دیگر مجاز است', () {
      final b5 = num_(B, 5);
      final g = UnoGame.setup(
        hands: [
          [b5, num_(G, 1), num_(G, 2)],
          safeHand(),
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, b5.id);
      expect(g.activeColor, B);
    });

    test('بازی خارج از نوبت (بدون Jump-In) ممنوع است', () {
      final r1 = num_(R, 1);
      final g = UnoGame.setup(
        hands: [
          safeHand(),
          [r1, num_(B, 1), num_(B, 2)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      expect(() => g.playCard(1, r1.id), throwsA(isA<IllegalMoveException>()));
    });

    test('کارتی که در دست نیست رد می‌شود', () {
      final g = UnoGame.setup(
        hands: [safeHand(), safeHand()],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      expect(() => g.playCard(0, 'nonexistent'),
          throwsA(isA<IllegalMoveException>()));
    });
  });

  group('کارت‌های عملیاتی', () {
    test('Skip نفر بعدی را رد می‌کند', () {
      final skip = act(R, CardType.skip);
      final g = UnoGame.setup(
        hands: [
          [skip, num_(R, 1), num_(R, 2)],
          safeHand(),
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, skip.id);
      expect(g.current, 2);
    });

    test('Reverse جهت را عوض می‌کند (سه نفر)', () {
      final rev = act(R, CardType.reverse);
      final g = UnoGame.setup(
        hands: [
          [rev, num_(R, 1), num_(R, 2)],
          safeHand(),
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, rev.id);
      expect(g.direction, -1);
      expect(g.current, 2);
    });

    test('Reverse در بازی دونفره مثل Skip است', () {
      final rev = act(R, CardType.reverse);
      final g = UnoGame.setup(
        hands: [
          [rev, num_(R, 1), num_(R, 2)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, rev.id);
      expect(g.current, 0);
    });

    test('+2 حریف را ۲ کارت جریمه و نوبتش را حذف می‌کند', () {
      final d2 = act(R, CardType.drawTwo);
      final g = UnoGame.setup(
        hands: [
          [d2, num_(R, 1), num_(R, 2)],
          safeHand(),
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, d2.id);
      expect(g.hands[1].length, 5);
      expect(g.current, 2);
      expect(g.totalCards, 3 + 3 + 3 + 12 + 1);
    });

    test('+2 در بازی دونفره: بازیکن دوباره نوبت دارد', () {
      final d2 = act(R, CardType.drawTwo);
      final g = UnoGame.setup(
        hands: [
          [d2, num_(R, 1), num_(R, 2)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, d2.id);
      expect(g.hands[1].length, 5);
      expect(g.current, 0);
    });

    test('Wild رنگ می‌خواهد و رنگ فعال را عوض می‌کند', () {
      final w = wild();
      final g = UnoGame.setup(
        hands: [
          [w, num_(R, 1), num_(R, 2)],
          [num_(B, 4), num_(G, 1), num_(G, 2)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      expect(() => g.playCard(0, w.id), throwsA(isA<IllegalMoveException>()));
      g.playCard(0, w.id, chosenColor: B);
      expect(g.activeColor, B);
      expect(g.current, 1);
      expect(g.playableCards(1).length, 1); // فقط کارت آبی
    });
  });

  group('+4 و اعتراض', () {
    UnoGame withPlus4(List<UnoCard> p0, {RulesConfig? rules}) {
      return UnoGame.setup(
        hands: [p0, safeHand(), safeHand()],
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: rules ?? RulesConfig.standard,
      );
    }

    test('قبول +4: ۴ کارت و حذف نوبت', () {
      final w4 = wild4();
      final g = withPlus4([w4, num_(B, 1), num_(G, 3)]);
      g.playCard(0, w4.id, chosenColor: G);
      expect(g.phase, TurnPhase.awaitingChallengeResponse);
      expect(g.current, 1);
      // تا پاسخ ندهد کسی کارت بازی نمی‌کند
      expect(() => g.drawCard(1), throwsA(isA<IllegalMoveException>()));
      g.acceptPlusFour();
      expect(g.hands[1].length, 7);
      expect(g.current, 2);
      expect(g.activeColor, G);
      expect(g.phase, TurnPhase.awaitingPlay);
    });

    test('اعتراض موفق: بازیکن خاطی ۴ کارت می‌گیرد', () {
      final w4 = wild4();
      // بازیکن ۰ کارت قرمز دارد ولی +4 بازی می‌کند = غیرمجاز
      final g = withPlus4([w4, num_(R, 1), num_(B, 2)]);
      g.playCard(0, w4.id, chosenColor: B);
      final success = g.challengePlusFour();
      expect(success, isTrue);
      expect(g.hands[0].length, 2 + 4);
      expect(g.hands[1].length, 3);
      expect(g.current, 1);
      expect(g.phase, TurnPhase.awaitingPlay);
    });

    test('اعتراض ناموفق: معترض ۶ کارت می‌گیرد و نوبتش می‌سوزد', () {
      final w4 = wild4();
      // بازیکن ۰ هیچ کارت قرمزی ندارد = +4 مجاز
      final g = withPlus4([w4, num_(B, 1), num_(G, 2)]);
      g.playCard(0, w4.id, chosenColor: B);
      final success = g.challengePlusFour();
      expect(success, isFalse);
      expect(g.hands[1].length, 3 + 6);
      expect(g.hands[0].length, 2);
      expect(g.current, 2);
    });

    test('بدون +4 در انتظار، اعتراض ممکن نیست', () {
      final g = withPlus4([num_(R, 1), num_(B, 1), num_(G, 2)]);
      expect(() => g.challengePlusFour(), throwsA(isA<IllegalMoveException>()));
      expect(() => g.acceptPlusFour(), throwsA(isA<IllegalMoveException>()));
    });
  });

  group('کشیدن کارت', () {
    test('کارت غیرقابل‌بازی: نوبت تمام می‌شود', () {
      final drawn = num_(B, 9);
      final g = UnoGame.setup(
        hands: [safeHand(), safeHand(), safeHand()],
        drawPile: [...filler(), drawn],
        topCard: num_(R, 5),
      );
      final result = g.drawCard(0);
      expect(result.single, drawn);
      expect(g.hands[0].length, 4);
      expect(g.current, 1);
      expect(g.drawnCardId, isNull);
      expect(g.missingColors[0].contains(R), isTrue);
    });

    test('کارت قابل‌بازی: فقط همان را می‌توان بازی کرد', () {
      final drawn = num_(R, 9);
      final other = num_(B, 1);
      final g = UnoGame.setup(
        hands: [
          [other, num_(G, 2), num_(B, 3)],
          safeHand(),
          safeHand()
        ],
        drawPile: [...filler(), drawn],
        topCard: num_(R, 5),
      );
      g.drawCard(0);
      expect(g.current, 0);
      expect(g.drawnCardId, drawn.id);
      expect(() => g.playCard(0, other.id),
          throwsA(isA<IllegalMoveException>()));
      expect(() => g.drawCard(0), throwsA(isA<IllegalMoveException>()));
      g.playCard(0, drawn.id);
      expect(g.current, 1);
      expect(g.topCard, drawn);
    });

    test('بازیکن می‌تواند کارت قابل‌بازی را رد کند', () {
      final drawn = num_(R, 9);
      final g = UnoGame.setup(
        hands: [safeHand(), safeHand()],
        drawPile: [...filler(), drawn],
        topCard: num_(R, 5),
      );
      g.drawCard(0);
      g.passTurn(0);
      expect(g.current, 1);
      expect(g.hands[0].length, 4);
    });

    test('کشیدن اختیاری حتی با کارت قابل‌بازی در دست', () {
      final g = UnoGame.setup(
        hands: [
          [num_(R, 7), num_(B, 1), num_(G, 2)],
          safeHand()
        ],
        drawPile: [...filler(), num_(B, 8)],
        topCard: num_(R, 5),
      );
      g.drawCard(0);
      expect(g.hands[0].length, 4);
      expect(g.current, 1);
    });

    test('کشیدن تا پیدا شدن کارت قابل‌بازی (قانون اختیاری)', () {
      final target = num_(R, 9);
      final g = UnoGame.setup(
        hands: [
          [num_(B, 1)],
          safeHand()
        ],
        drawPile: [target, num_(G, 3), num_(B, 2)],
        topCard: num_(R, 5),
        rules: const RulesConfig(drawUntilPlayable: true),
      );
      final drawn = g.drawCard(0);
      expect(drawn.length, 3);
      expect(g.drawnCardId, target.id);
      expect(g.hands[0].length, 4);
    });

    test('وقتی دستهٔ برداشت تمام شود، دستهٔ زمین بُر می‌خورد', () {
      final g = UnoGame.setup(
        hands: [safeHand(), safeHand()],
        drawPile: [],
        discardBelow: [num_(B, 4), num_(G, 6), num_(Y, 8)],
        topCard: num_(R, 5),
      );
      final before = g.totalCards;
      g.drawCard(0);
      expect(g.hands[0].length, 4);
      expect(g.discardPile.length, 1);
      expect(g.totalCards, before);
    });
  });

  group('UNO', () {
    UnoGame twoCards() => UnoGame.setup(
          hands: [
            [num_(R, 7), num_(R, 8)],
            [num_(R, 1), num_(B, 1), num_(B, 2)],
            safeHand()
          ],
          drawPile: filler(),
          topCard: num_(R, 5),
        );

    test('فراموشی UNO: دیگران می‌توانند جریمه کنند', () {
      final g = twoCards();
      g.playCard(0, g.hands[0][0].id);
      expect(g.unoVulnerable, 0);
      expect(g.catchUno(1), isTrue);
      expect(g.hands[0].length, 3);
      expect(g.unoVulnerable, isNull);
    });

    test('اعلام UNO بعد از بازی، جریمه را خنثی می‌کند', () {
      final g = twoCards();
      g.playCard(0, g.hands[0][0].id);
      g.callUno(0);
      expect(g.catchUno(1), isFalse);
      expect(g.hands[0].length, 1);
    });

    test('اعلام UNO پیش از بازی (با ۲ کارت) هم معتبر است', () {
      final g = twoCards();
      g.callUno(0);
      g.playCard(0, g.hands[0][0].id);
      expect(g.unoVulnerable, isNull);
    });

    test('با اقدام نفر بعدی پنجرهٔ جریمه بسته می‌شود', () {
      final g = twoCards();
      g.playCard(0, g.hands[0][0].id);
      final p1card = g.hands[1].firstWhere((c) => c.color == R);
      g.playCard(1, p1card.id);
      expect(g.catchUno(2), isFalse);
      expect(g.hands[0].length, 1);
    });

    test('خود بازیکن نمی‌تواند خودش را جریمه کند', () {
      final g = twoCards();
      g.playCard(0, g.hands[0][0].id);
      expect(g.catchUno(0), isFalse);
    });

    test('با ۵ کارت نمی‌توان UNO گفت', () {
      final g = UnoGame.setup(
        hands: [
          [for (var i = 0; i < 5; i++) num_(B, i)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      expect(() => g.callUno(0), throwsA(isA<IllegalMoveException>()));
    });

    test('جریمهٔ UNO قابل تنظیم است', () {
      final g = UnoGame.setup(
        hands: [
          [num_(R, 7), num_(R, 8)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: const RulesConfig(unoPenalty: 3),
      );
      g.playCard(0, g.hands[0][0].id);
      g.catchUno(1);
      expect(g.hands[0].length, 4);
    });
  });

  group('پایان دور', () {
    test('اتمام کارت‌ها = برد و محاسبهٔ امتیاز', () {
      final last = num_(R, 7);
      final g = UnoGame.setup(
        hands: [
          [last],
          [num_(B, 5), act(R, CardType.skip)],
          [wild()]
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, last.id);
      expect(g.isFinished, isTrue);
      expect(g.winner, 0);
      expect(g.roundScore, 5 + 20 + 50);
      expect(() => g.drawCard(1), throwsA(isA<IllegalMoveException>()));
    });

    test('آخرین کارت +2: حریف جریمه را می‌کشد', () {
      final last = act(R, CardType.drawTwo);
      final g = UnoGame.setup(
        hands: [
          [last],
          safeHand(),
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      g.playCard(0, last.id);
      expect(g.winner, 0);
      expect(g.hands[1].length, 5);
    });
  });

  group('قوانین اختیاری', () {
    test('Stacking: +2 روی +2 انباشته می‌شود', () {
      final a = act(R, CardType.drawTwo);
      final b = act(B, CardType.drawTwo);
      final g = UnoGame.setup(
        hands: [
          [a, num_(R, 1), num_(R, 2)],
          [b, num_(B, 1), num_(B, 2)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: const RulesConfig(stacking: true),
      );
      g.playCard(0, a.id);
      expect(g.pendingDraw, 2);
      expect(g.current, 1);
      // کارت غیر +2 مجاز نیست
      final other = g.hands[1].firstWhere((c) => c.type == CardType.number);
      expect(() => g.playCard(1, other.id),
          throwsA(isA<IllegalMoveException>()));
      g.playCard(1, b.id);
      expect(g.pendingDraw, 4);
      expect(g.current, 2);
      g.drawCard(2);
      expect(g.hands[2].length, 3 + 4);
      expect(g.pendingDraw, 0);
      expect(g.current, 0);
    });

    test('Stacking خاموش است مگر روشن شود (استاندارد)', () {
      expect(RulesConfig.standard.stacking, isFalse);
      expect(RulesConfig.standard.sevenZero, isFalse);
      expect(RulesConfig.standard.jumpIn, isFalse);
      expect(RulesConfig.standard.drawUntilPlayable, isFalse);
      expect(RulesConfig.standard.startingCards, 7);
    });

    test('Stacking: +4 روی +4 بدون اعتراض', () {
      final a = wild4();
      final b = wild4();
      final g = UnoGame.setup(
        hands: [
          [a, num_(B, 1), num_(G, 2)],
          [b, num_(B, 1), num_(G, 2)],
          safeHand()
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: const RulesConfig(stacking: true),
      );
      g.playCard(0, a.id, chosenColor: B);
      g.acceptPlusFour();
      expect(g.pendingDraw, 4);
      expect(g.current, 1);
      g.playCard(1, b.id, chosenColor: G);
      expect(g.phase, TurnPhase.awaitingPlay);
      expect(g.pendingDraw, 8);
      g.drawCard(2);
      expect(g.hands[2].length, 3 + 8);
    });

    test('7-0: کارت ۷ تعویض دست با هدف', () {
      final seven = num_(R, 7);
      final extra = num_(B, 1);
      final target = safeHand();
      final g = UnoGame.setup(
        hands: [
          [seven, extra],
          safeHand(),
          target
        ],
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: const RulesConfig(sevenZero: true),
      );
      expect(() => g.playCard(0, seven.id),
          throwsA(isA<IllegalMoveException>()));
      g.playCard(0, seven.id, swapTarget: 2);
      expect(g.hands[0].length, 3);
      expect(g.hands[2], [extra]);
      expect(g.current, 1);
    });

    test('7-0: کارت ۰ دست‌ها را در جهت بازی می‌چرخاند', () {
      final zero = num_(R, 0);
      final h0 = [zero, num_(B, 1)];
      final h1 = [num_(B, 2), num_(B, 3), num_(G, 4)];
      final h2 = [num_(G, 5)];
      final g = UnoGame.setup(
        hands: [h0, h1, h2],
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: const RulesConfig(sevenZero: true),
      );
      final expected0 = List<UnoCard>.of(h2);
      final expected1 = [h0[1]];
      final expected2 = List<UnoCard>.of(h1);
      g.playCard(0, zero.id);
      expect(g.hands[0], expected0);
      expect(g.hands[1], expected1);
      expect(g.hands[2], expected2);
    });

    test('Jump-In: کارت کاملاً یکسان خارج از نوبت', () {
      final top = num_(R, 5);
      final twin = num_(R, 5);
      final g = UnoGame.setup(
        hands: [
          safeHand(),
          safeHand(),
          [twin, num_(B, 1), num_(B, 2)]
        ],
        drawPile: filler(),
        topCard: top,
        rules: const RulesConfig(jumpIn: true),
      );
      g.playCard(2, twin.id);
      expect(g.topCard, twin);
      expect(g.current, 0); // بعد از نفر ۲ نوبت نفر ۰ است
    });

    test('Jump-In: کارت غیریکسان یا قانون خاموش ممنوع', () {
      final r6 = num_(R, 6);
      final base = [
        safeHand(),
        safeHand(),
        [r6, num_(R, 5), num_(B, 2)]
      ];
      final on = UnoGame.setup(
        hands: base,
        drawPile: filler(),
        topCard: num_(R, 5),
        rules: const RulesConfig(jumpIn: true),
      );
      expect(() => on.playCard(2, r6.id), throwsA(isA<IllegalMoveException>()));
      final off = UnoGame.setup(
        hands: base,
        drawPile: filler(),
        topCard: num_(R, 5),
      );
      final twin = off.hands[2][1];
      expect(() => off.playCard(2, twin.id),
          throwsA(isA<IllegalMoveException>()));
    });
  });

  group('محرمانگی', () {
    test('GameView فقط دست خود بازیکن را نشان می‌دهد', () {
      final g = UnoGame.newGame(playerCount: 4);
      final v = g.viewFor(1);
      expect(v.myHand, g.hands[1]);
      expect(v.handSizes, g.hands.map((h) => h.length).toList());
      expect(v.drawPileSize, g.drawPile.length);
    });
  });

  group('ذخیره‌سازی مدل‌ها', () {
    test('کارت و قوانین به JSON و برگشت', () {
      final c = num_(R, 4);
      expect(UnoCard.fromJson(c.toJson()), c);
      const r = RulesConfig(stacking: true, startingCards: 5);
      final r2 = RulesConfig.fromJson(r.toJson());
      expect(r2.stacking, isTrue);
      expect(r2.startingCards, 5);
    });
  });
}
