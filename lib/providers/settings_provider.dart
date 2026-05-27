import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Where BTK records are persisted.
enum StorageMode {
  local, // SQLite (Android) / SharedPreferences (web) — default
  cloud, // Firestore — requires Firebase Auth
}

/// When / whether to sync photos to Firebase Storage.
enum PhotoSyncMode {
  none,     // photos stay local only
  wifiOnly, // upload (compressed) when on WiFi
  always,   // upload (compressed) on any connection
}

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final List<String> emails;
  final int pdfPage;
  final bool screenAwake; // keep screen on while map is open
  final StorageMode storageMode;
  final PhotoSyncMode photoSyncMode;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ka'),
    this.emails = const [],
    this.pdfPage = 0,
    this.screenAwake = false,
    this.storageMode = StorageMode.local,
    this.photoSyncMode = PhotoSyncMode.none,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    List<String>? emails,
    int? pdfPage,
    bool? screenAwake,
    StorageMode? storageMode,
    PhotoSyncMode? photoSyncMode,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        emails: emails ?? this.emails,
        pdfPage: pdfPage ?? this.pdfPage,
        screenAwake: screenAwake ?? this.screenAwake,
        storageMode: storageMode ?? this.storageMode,
        photoSyncMode: photoSyncMode ?? this.photoSyncMode,
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
    final storageModeStr = prefs.getString('storage_mode') ?? 'local';
    final photoSyncStr = prefs.getString('photo_sync_mode') ?? 'none';

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
      storageMode:
          storageModeStr == 'cloud' ? StorageMode.cloud : StorageMode.local,
      photoSyncMode: _parsePhotoSync(photoSyncStr),
    );
  }

  static PhotoSyncMode _parsePhotoSync(String s) {
    switch (s) {
      case 'wifi': return PhotoSyncMode.wifiOnly;
      case 'always': return PhotoSyncMode.always;
      default: return PhotoSyncMode.none;
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
    state = state.copyWith(emails: state.emails.where((e) => e != email).toList());
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
    await prefs.setString(
        'storage_mode', mode == StorageMode.cloud ? 'cloud' : 'local');
  }

  Future<void> setPhotoSyncMode(PhotoSyncMode mode) async {
    state = state.copyWith(photoSyncMode: mode);
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      PhotoSyncMode.wifiOnly => 'wifi',
      PhotoSyncMode.always => 'always',
      PhotoSyncMode.none => 'none',
    };
    await prefs.setString('photo_sync_mode', str);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
