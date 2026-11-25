import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/strings.dart';

/// زبان برنامه؛ پیش‌فرض فارسی.
final localeProvider = StateProvider<Locale>((ref) => const Locale('fa'));

final stringsProvider =
    Provider<Strings>((ref) => Strings(ref.watch(localeProvider)));
