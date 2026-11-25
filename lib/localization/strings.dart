import 'dart:ui';

/// متن‌های برنامه (فارسی و انگلیسی). تغییر زبان بدون نصب مجدد.
class Strings {
  final Locale locale;
  const Strings(this.locale);

  bool get isFa => locale.languageCode == 'fa';

  /// جایگزینی {p} {t} {n} {c} در قالب پیام.
  String f(String key, {String? p, String? t, int? n, String? c}) {
    var out = this.t(key);
    if (p != null) out = out.replaceAll('{p}', p);
    if (t != null) out = out.replaceAll('{t}', t);
    if (n != null) out = out.replaceAll('{n}', '$n');
    if (c != null) out = out.replaceAll('{c}', c);
    return out;
  }

  String t(String key) => (_data[locale.languageCode] ?? _data['fa']!)[key] ??
      _data['fa']![key] ??
      key;

  static const Map<String, Map<String, String>> _data = {
    'fa': {
      'title': 'یونو پارتی',
      'subtitle': 'بازی کارتی سه‌بعدی کارتونی',
      'new_game': 'بازی جدید',
      'vs_ai': 'بازی با کامپیوتر',
      'local_mp': 'چندنفره محلی',
      'tournament': 'تورنمنت',
      'characters': 'شخصیت‌ها',
      'collection': 'کلکسیون کارت‌ها',
      'stats': 'آمار',
      'settings': 'تنظیمات',
      'rules': 'قوانین',
      'about': 'درباره',
      'coming_soon': 'این بخش در فاز بعدی ساخته می‌شود',
      'language': 'English',
      'close': 'بستن',
      'setup_title': 'بازی با کامپیوتر',
      'opponents': 'تعداد رقیب‌ها',
      'difficulty': 'سختی',
      'easy': 'آسان',
      'medium': 'متوسط',
      'hard': 'سخت',
      'start_cards': 'تعداد کارت شروع',
      'optional_rules': 'قوانین اختیاری',
      'r_stacking': 'Stacking (+2 روی +2، +4 روی +4)',
      'r_sevenzero': 'قانون 7-0',
      'r_jumpin': 'Jump-In (کارت یکسان خارج از نوبت)',
      'r_drawuntil': 'کشیدن تا کارت قابل بازی',
      'start_game': 'شروع بازی',
      'you': 'شما',
      'your_turn': 'نوبت شماست',
      'thinking': '{p} در حال فکر کردن…',
      'choose_color': 'رنگ را انتخاب کن',
      'choose_target': 'با چه کسی دست عوض کنی؟',
      'challenge_title': 'کارت +4',
      'challenge_body': '{p} کارت +4 بازی کرد و رنگ {c} را انتخاب کرد.',
      'accept_draw': 'قبول (۴ کارت می‌کشم)',
      'challenge_btn': 'اعتراض!',
      'uno_btn': 'UNO!',
      'catch_btn': 'گرفتنش!',
      'pass_btn': 'رد کردن نوبت',
      'draw_hint': 'کشیدن',
      'you_won': 'شما بردید! 🎉',
      'player_won': '{p} برنده شد',
      'score': 'امتیاز دور: {n}',
      'play_again': 'بازی دوباره',
      'to_menu': 'منو',
      'c_red': 'قرمز',
      'c_blue': 'آبی',
      'c_green': 'سبز',
      'c_yellow': 'زرد',
      'msg_play': '{p} کارت بازی کرد',
      'msg_skip': '{t} رد شد',
      'msg_reverse': 'جهت بازی عوض شد',
      'msg_draw': '{p} {n} کارت کشید',
      'msg_challenge_ok': 'اعتراض موفق بود! {t} جریمه شد',
      'msg_challenge_fail': 'اعتراض ناموفق بود؛ {p} ۶ کارت کشید',
      'msg_uno': '{p}: UNO!',
      'msg_uno_penalty': '{p} UNO نگفت و جریمه شد',
      'msg_swap': '{p} و {t} دست عوض کردند',
      'msg_rotate': 'دست‌ها چرخید',
      'rules_body':
          'هر بازیکن ۷ کارت می‌گیرد. کارتی بازی کن که هم‌رنگ، هم‌عدد یا هم‌نماد با کارت روی زمین باشد.\n\n'
              '• Skip: نوبت نفر بعدی می‌سوزد\n'
              '• Reverse: جهت بازی عوض می‌شود (در بازی دونفره مثل Skip)\n'
              '• +2: نفر بعدی ۲ کارت می‌کشد و نوبتش می‌سوزد\n'
              '• Wild: رنگ را عوض می‌کنی\n'
              '• +4: رنگ را عوض می‌کنی و نفر بعدی ۴ کارت می‌کشد؛ فقط وقتی کارت هم‌رنگ نداری مجاز است و می‌شود به آن اعتراض کرد\n'
              '• اگر اعتراض موفق باشد خاطی ۴ کارت می‌کشد، وگرنه معترض ۶ کارت\n'
              '• با یک کارت باقی‌مانده باید UNO بگویی، وگرنه ۲ کارت جریمه می‌شوی\n'
              '• اولین نفری که کارت‌هایش تمام شود برنده است',
      'about_body':
          'یونو پارتی نسخهٔ ۱.۰ (فاز ۱: موتور قوانین، هوش مصنوعی و ساختار پروژه)\n'
              'کاملاً آفلاین. تصویر پشت کارت و آیکون از تصویر ارائه‌شده توسط کاربر ساخته شده است.',
    },
    'en': {
      'title': 'UNO Party',
      'subtitle': '3D cartoon card game',
      'new_game': 'New Game',
      'vs_ai': 'Play Against AI',
      'local_mp': 'Local Multiplayer',
      'tournament': 'Tournament',
      'characters': 'Characters',
      'collection': 'Card Collection',
      'stats': 'Statistics',
      'settings': 'Settings',
      'rules': 'Rules',
      'about': 'About',
      'coming_soon': 'This section will be built in the next phase',
      'language': 'فارسی',
      'close': 'Close',
      'setup_title': 'Play Against AI',
      'opponents': 'Opponents',
      'difficulty': 'Difficulty',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'start_cards': 'Starting cards',
      'optional_rules': 'Optional rules',
      'r_stacking': 'Stacking (+2 on +2, +4 on +4)',
      'r_sevenzero': '7-0 rule',
      'r_jumpin': 'Jump-In (identical card out of turn)',
      'r_drawuntil': 'Draw until playable',
      'start_game': 'Start Game',
      'you': 'You',
      'your_turn': 'Your turn',
      'thinking': '{p} is thinking…',
      'choose_color': 'Choose a color',
      'choose_target': 'Swap hands with whom?',
      'challenge_title': 'Wild Draw Four',
      'challenge_body': '{p} played +4 and chose {c}.',
      'accept_draw': 'Accept (draw 4)',
      'challenge_btn': 'Challenge!',
      'uno_btn': 'UNO!',
      'catch_btn': 'Catch!',
      'pass_btn': 'Keep & pass',
      'draw_hint': 'Draw',
      'you_won': 'You won! 🎉',
      'player_won': '{p} won',
      'score': 'Round score: {n}',
      'play_again': 'Play again',
      'to_menu': 'Menu',
      'c_red': 'Red',
      'c_blue': 'Blue',
      'c_green': 'Green',
      'c_yellow': 'Yellow',
      'msg_play': '{p} played a card',
      'msg_skip': '{t} was skipped',
      'msg_reverse': 'Direction reversed',
      'msg_draw': '{p} drew {n} card(s)',
      'msg_challenge_ok': 'Challenge succeeded! {t} is penalized',
      'msg_challenge_fail': 'Challenge failed; {p} draws 6',
      'msg_uno': '{p}: UNO!',
      'msg_uno_penalty': '{p} forgot UNO and is penalized',
      'msg_swap': '{p} and {t} swapped hands',
      'msg_rotate': 'Hands rotated',
      'rules_body':
          'Each player gets 7 cards. Play a card matching the top card by color, number or symbol.\n\n'
              '• Skip: next player loses their turn\n'
              '• Reverse: direction flips (acts like Skip with 2 players)\n'
              '• +2: next player draws 2 and loses their turn\n'
              '• Wild: choose a color\n'
              '• +4: choose a color, next player draws 4; legal only if you hold no card of the active color, and it can be challenged\n'
              '• Successful challenge: offender draws 4; failed challenge: challenger draws 6\n'
              '• With one card left you must call UNO or draw 2 if caught\n'
              '• First player to empty their hand wins',
      'about_body':
          'UNO Party v1.0 (Phase 1: rules engine, AI and project structure)\n'
              'Fully offline. Card back and icon are derived from the image supplied by the user.',
    },
  };
}
