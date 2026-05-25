import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final String defaultEmail;
  final int pdfPage;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('ka'),
    this.defaultEmail = '',
    this.pdfPage = 0,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? defaultEmail,
    int? pdfPage,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        defaultEmail: defaultEmail ?? this.defaultEmail,
        pdfPage: pdfPage ?? this.pdfPage,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(AppConstants.prefTheme) ?? 'light';
    final localeStr = prefs.getString(AppConstants.prefLocale) ?? 'ka';
    final email = prefs.getString(AppConstants.prefEmail) ?? '';
    final pdfPage = prefs.getInt(AppConstants.prefPdfPage) ?? 0;
    state = SettingsState(
      themeMode: themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(localeStr),
      defaultEmail: email,
      pdfPage: pdfPage,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefTheme, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, locale.languageCode);
  }

  Future<void> setDefaultEmail(String email) async {
    state = state.copyWith(defaultEmail: email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefEmail, email);
  }

  Future<void> savePdfPage(int page) async {
    state = state.copyWith(pdfPage: page);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefPdfPage, page);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
