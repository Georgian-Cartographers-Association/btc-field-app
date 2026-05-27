import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Where BTK records are persisted.
enum StorageMode {
  local, // SQLite (Android) / SharedPreferences (web) — default
  cloud, // Firestore personal — requires Firebase Auth
  expedition, // Firestore shared expedition — requires Firebase Auth + expId
}

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final List<String> emails;
  final int pdfPage;
  final bool screenAwake; // keep screen on while map is open
  final StorageMode storageMode;
  final String? expeditionId; // non-null only when storageMode == expedition

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ka'),
    this.emails = const [],
    this.pdfPage = 0,
    this.screenAwake = false,
    this.storageMode = StorageMode.local,
    this.expeditionId,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    List<String>? emails,
    int? pdfPage,
    bool? screenAwake,
    StorageMode? storageMode,
    Object? expeditionId = _sentinel, // use _sentinel to distinguish null from "unset"
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        emails: emails ?? this.emails,
        pdfPage: pdfPage ?? this.pdfPage,
        screenAwake: screenAwake ?? this.screenAwake,
        storageMode: storageMode ?? this.storageMode,
        expeditionId: expeditionId == _sentinel
            ? this.expeditionId
            : expeditionId as String?,
      );
}

// Sentinel value so copyWith can distinguish "pass null" from "not provided"
const Object _sentinel = Object();

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
    final storageModeStr = prefs.getString('storage_mode') ?? 'local';
    final expeditionId = prefs.getString('expedition_id');

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
      storageMode: _parseStorageMode(storageModeStr),
      expeditionId: expeditionId,
    );
  }

  static StorageMode _parseStorageMode(String s) {
    switch (s) {
      case 'cloud': return StorageMode.cloud;
      case 'expedition': return StorageMode.expedition;
      default: return StorageMode.local;
    }
  }

  static String _storageModeStr(StorageMode m) {
    switch (m) {
      case StorageMode.cloud: return 'cloud';
      case StorageMode.expedition: return 'expedition';
      default: return 'local';
    }
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
    state = state.copyWith(
        emails: state.emails.where((e) => e != email).toList());
    await _persistEmails();
  }

  Future<void> savePdfPage(int page) async {
    state = state.copyWith(pdfPage: page);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefPdfPage, page);
  }

  Future<void> setStorageMode(StorageMode mode) async {
    state = state.copyWith(storageMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_mode', _storageModeStr(mode));
  }

  /// Enter expedition mode with a specific expedition ID.
  Future<void> joinExpedition(String expeditionId) async {
    state = state.copyWith(
      storageMode: StorageMode.expedition,
      expeditionId: expeditionId,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_mode', 'expedition');
    await prefs.setString('expedition_id', expeditionId);
  }

  /// Leave expedition and revert to cloud (personal) mode.
  Future<void> leaveExpedition() async {
    state = state.copyWith(
      storageMode: StorageMode.cloud,
      expeditionId: null,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_mode', 'cloud');
    await prefs.remove('expedition_id');
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
        (ref) => SettingsNotifier());
