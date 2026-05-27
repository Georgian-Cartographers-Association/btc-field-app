import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final List<String> emails;
  final int pdfPage;
  final bool screenAwake; // keep screen on while map is open

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ka'),
    this.emails = const [],
    this.pdfPage = 0,
    this.screenAwake = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    List<String>? emails,
    int? pdfPage,
    bool? screenAwake,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        emails: emails ?? this.emails,
        pdfPage: pdfPage ?? this.pdfPage,
        screenAwake: screenAwake ?? this.screenAwake,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(AppConstants.prefTheme) ?? 'system';
    final localeStr = prefs.getString(AppConstants.prefLocale) ?? 'ka';
    final pdfPage = prefs.getInt(AppConstants.prefPdfPage) ?? 0;
    final screenAwake = prefs.getBool('screen_awake') ?? false;

    // Migrate: old single-email string → new list
    List<String> emails = [];
    final emailsJson = prefs.getString(AppConstants.prefEmails);
    if (emailsJson != null) {
      emails = List<String>.from(jsonDecode(emailsJson) as List);
    } else {
      // migrate from old single-email key
      final old = prefs.getString(AppConstants.prefEmail) ?? '';
      if (old.isNotEmpty) emails = [old];
    }

    state = SettingsState(
      themeMode: _parseTheme(themeStr),
      locale: Locale(localeStr),
      emails: emails,
      pdfPage: pdfPage,
      screenAwake: screenAwake,
    );
  }

  Future<void> _persistEmails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefEmails, jsonEncode(state.emails));
  }

  static ThemeMode _parseTheme(String s) {
    switch (s) {
      case 'dark': return ThemeMode.dark;
      case 'system': return ThemeMode.system;
      default: return ThemeMode.light;
    }
  }

  static String _themeStr(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
      default: return 'light';
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefTheme, _themeStr(mode));
  }

  Future<void> setScreenAwake(bool value) async {
    state = state.copyWith(screenAwake: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screen_awake', value);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, locale.languageCode);
  }

  Future<void> addEmail(String email) async {
    final e = email.trim();
    if (e.isEmpty || state.emails.contains(e)) return;
    state = state.copyWith(emails: [...state.emails, e]);
    await _persistEmails();
  }

  Future<void> removeEmail(String email) async {
    state = state.copyWith(emails: state.emails.where((e) => e != email).toList());
    await _persistEmails();
  }

  Future<void> savePdfPage(int page) async {
    state = state.copyWith(pdfPage: page);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefPdfPage, page);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
