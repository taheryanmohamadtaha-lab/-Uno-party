import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/menu_screen.dart';
import 'settings/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: UnoPartyApp()));
}

class UnoPartyApp extends ConsumerWidget {
  const UnoPartyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = ref.watch(stringsProvider);
    return MaterialApp(
      title: s.t('title'),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E44FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const MenuScreen(),
    );
  }
}
