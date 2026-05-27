import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../database/btk_database.dart';
import '../models/photo.dart';
import '../providers/settings_provider.dart';
import '../services/photo_sync_service.dart';
import 'auth_provider.dart';

class PhotoNotifier extends StateNotifier<List<Photo>> {
  PhotoNotifier(this.recordId, this._ref) : super([]) {
    _load();
  }

  final String recordId;
  final Ref _ref;

  Future<void> _load() async {
    state = await BtkDatabase.getPhotos(recordId);
  }

  Future<void> addFromSource(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (file == null) return;

    // Copy to app documents so it survives app updates
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos/$recordId');
    await dir.create(recursive: true);

    final ext = file.path.split('.').last.toLowerCase();
    final id = const Uuid().v4().substring(0, 8);
    final dest = '${dir.path}/$id.$ext';
    await File(file.path).copy(dest);

    final photo = Photo(
      id: id,
      recordId: recordId,
      filePath: dest,
      sortOrder: state.length,
      createdAt: DateTime.now(),
    );
    await BtkDatabase.insertPhoto(photo);
    state = [...state, photo];

    // ── Try cloud upload ───────────────────────────────────────────
    _tryUpload(photo);
  }

  /// Manually trigger upload for a specific photo (e.g. from the UI button).
  Future<void> uploadPhoto(Photo photo) async {
    await _tryUpload(photo);
  }

  Future<void> _tryUpload(Photo photo) async {
    final settings = _ref.read(settingsProvider);
    if (settings.storageMode != StorageMode.cloud) return;
    if (settings.photoSyncMode == PhotoSyncMode.none) return;

    final user = _ref.read(authProvider).valueOrNull;
    if (user == null) return;

    final url = await PhotoSyncService.upload(
      photo: photo,
      uid: user.uid,
      mode: settings.photoSyncMode,
    );

    if (url != null) {
      await BtkDatabase.updatePhotoCloudUrl(photo.id, url);
      // Update state
      state = [
        for (final p in state)
          if (p.id == photo.id) p.copyWith(cloudUrl: url) else p
      ];
    }
  }

  Future<void> delete(Photo photo) async {
    await BtkDatabase.deletePhoto(photo.id);
    try { await File(photo.filePath).delete(); } catch (_) {}

    // Delete from cloud if uploaded
    if (photo.cloudUrl != null) {
      final user = _ref.read(authProvider).valueOrNull;
      if (user != null) {
        await PhotoSyncService.delete(photo: photo, uid: user.uid);
      }
    }

    state = state.where((p) => p.id != photo.id).toList();
  }
}

/// Family provider — one notifier per record ID.
final photoProvider =
    StateNotifierProvider.family<PhotoNotifier, List<Photo>, String>(
  (ref, recordId) => PhotoNotifier(recordId, ref),
);
