import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';
import '../providers/settings_provider.dart';

class PhotoSyncService {
  /// Try to upload [photo] to Firebase Storage.
  ///
  /// Returns the public download URL on success, or null if:
  ///  - mode is [PhotoSyncMode.none]
  ///  - mode is [PhotoSyncMode.wifiOnly] and device is not on WiFi
  ///  - upload fails for any reason
  static Future<String?> upload({
    required Photo photo,
    required String uid,
    required PhotoSyncMode mode,
  }) async {
    if (mode == PhotoSyncMode.none) return null;

    // WiFi check
    if (mode == PhotoSyncMode.wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) return null;
    }

    try {
      // ── Compress ──────────────────────────────────────────────────
      final compressed = await _compress(photo.filePath);
      if (compressed == null) return null;

      // ── Upload ───────────────────────────────────────────────────
      final ref = FirebaseStorage.instance
          .ref('users/$uid/photos/${photo.recordId}/${photo.id}.jpg');

      await ref.putFile(
        File(compressed),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();

      // Clean up temp compressed file
      try { await File(compressed).delete(); } catch (_) {}

      return url;
    } catch (_) {
      return null;
    }
  }

  /// Delete a photo from Firebase Storage (called when photo is deleted locally).
  static Future<void> delete({
    required Photo photo,
    required String uid,
  }) async {
    try {
      await FirebaseStorage.instance
          .ref('users/$uid/photos/${photo.recordId}/${photo.id}.jpg')
          .delete();
    } catch (_) {}
  }

  // ── Compression ────────────────────────────────────────────────────────────

  /// Compress image to max 1280px, JPEG quality 80.
  /// Returns path to the compressed file (in temp directory), or null on error.
  static Future<String?> _compress(String sourcePath) async {
    try {
      final tmp = await getTemporaryDirectory();
      final dest = '${tmp.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        dest,
        quality: 80,
        minWidth: 1280,
        minHeight: 960,
        format: CompressFormat.jpeg,
      );

      return result?.path;
    } catch (_) {
      return null;
    }
  }
}
