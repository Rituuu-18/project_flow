import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_errors.dart';

/// Uploads review cover images and workspace evidence to Supabase Storage.
class SupabaseStorage {
  SupabaseStorage(this._client);

  final SupabaseClient _client;
  static const imagesBucket = 'images';
  static const attachmentsBucket = 'attachments';
  static const attachmentRefPrefix = 'storage:attachments:';

  /// Storage path: `design_review/{reviewId}/{uuid}.{ext}`
  Future<String> uploadReviewImage({
    required String reviewId,
    required Uint8List bytes,
    String? mimeType,
    String? fileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final ext = _extensionFor(
      mimeType: mimeType ?? 'image/jpeg',
      fileName: fileName,
    );
    final objectPath = 'design_review/$reviewId/${const Uuid().v4()}.$ext';
    final contentType = mimeType ?? _mimeForExt(ext);

    await supabaseCall(() async {
      await _client.storage.from(imagesBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
    }, operation: 'uploadReviewImage');

    return _client.storage.from(imagesBucket).getPublicUrl(objectPath);
  }

  /// Best-effort delete of a previous cover image from a public URL.
  Future<void> deleteReviewImageIfOwned(String? imageUrl) async {
    final path = objectPathFromPublicImageUrl(imageUrl);
    if (path == null || !path.startsWith('design_review/')) return;

    try {
      await _client.storage.from(imagesBucket).remove([path]);
    } catch (_) {
      // Non-fatal: orphan cleanup should not block a new upload.
    }
  }

  /// Uploads evidence to the private `attachments` bucket.
  ///
  /// Returns a durable ref: `storage:attachments:workspace/{id}/{uuid}.ext`
  Future<String> uploadWorkspaceAttachment({
    required String workspaceId,
    required Uint8List bytes,
    String? mimeType,
    String? fileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final ext = _extensionFor(mimeType: mimeType, fileName: fileName);
    final safeName = (fileName == null || fileName.trim().isEmpty)
        ? 'file.$ext'
        : fileName.trim().replaceAll(RegExp(r'[/\\]'), '_');
    final objectPath =
        'workspace/$workspaceId/${const Uuid().v4()}_$safeName';
    final contentType = mimeType ?? _mimeForExt(ext);

    await supabaseCall(() async {
      await _client.storage.from(attachmentsBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
    }, operation: 'uploadWorkspaceAttachment');

    return '$attachmentRefPrefix$objectPath';
  }

  /// Resolves a stored attachment ref or legacy path/URL into an openable URL.
  Future<String?> resolveAttachmentUrl(
    String stored, {
    String? workspaceId,
  }) async {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    String? path = attachmentObjectPath(trimmed);
    if (path == null) return null;

    if (!path.startsWith('workspace/') &&
        workspaceId != null &&
        workspaceId.trim().isNotEmpty) {
      path = 'workspace/${workspaceId.trim()}/$path';
    }

    try {
      final signedUrl = await supabaseCall(() async {
        return _client.storage
            .from(attachmentsBucket)
            .createSignedUrl(path!, 60 * 60 * 24 * 7);
      }, operation: 'resolveAttachmentUrl');
      if (signedUrl.isNotEmpty) return signedUrl;
    } catch (e) {
      debugPrint('Direct signed URL failed for "$path": $e');
    }

    if (workspaceId != null && workspaceId.trim().isNotEmpty) {
      try {
        final folderPath = 'workspace/${workspaceId.trim()}';
        final files = await _client.storage
            .from(attachmentsBucket)
            .list(path: folderPath);
        final fileNameOnly = attachmentDisplayName(trimmed);

        for (final file in files) {
          if (file.name == fileNameOnly ||
              file.name.endsWith('_$fileNameOnly')) {
            final matchedPath = '$folderPath/${file.name}';
            final signedUrl = await _client.storage
                .from(attachmentsBucket)
                .createSignedUrl(matchedPath, 60 * 60 * 24 * 7);
            if (signedUrl.isNotEmpty) return signedUrl;
          }
        }
      } catch (e) {
        debugPrint('List fallback failed for workspace "$workspaceId": $e');
      }
    }

    return null;
  }

  static String? attachmentObjectPath(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith(attachmentRefPrefix)) {
      return trimmed.substring(attachmentRefPrefix.length);
    }
    if (trimmed.startsWith('workspace/')) {
      return trimmed;
    }
    return trimmed;
  }

  static String attachmentDisplayName(String stored) {
    final path = attachmentObjectPath(stored) ?? stored;
    final leaf = path.split(RegExp(r'[/\\]')).last;
    final underscore = leaf.indexOf('_');
    if (underscore > 0 && underscore < leaf.length - 1) {
      // Strip leading uuid_ prefix when present.
      final maybeUuid = leaf.substring(0, underscore);
      if (maybeUuid.length >= 32) {
        return leaf.substring(underscore + 1);
      }
    }
    return leaf;
  }

  static String? objectPathFromPublicImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return null;
    final marker = '/object/public/$imagesBucket/';
    final full = uri.path;
    final idx = full.indexOf(marker);
    if (idx < 0) return null;
    return Uri.decodeComponent(full.substring(idx + marker.length));
  }

  static String _extensionFor({String? mimeType, String? fileName}) {
    final fromName = fileName?.split('.').last.toLowerCase();
    if (fromName != null &&
        fromName.length <= 5 &&
        !fromName.contains('/') &&
        fromName != fileName?.toLowerCase()) {
      return fromName;
    }
    return switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/heic' || 'image/heif' => 'heic',
      'image/jpeg' || 'image/jpg' => 'jpg',
      'application/pdf' => 'pdf',
      _ => 'bin',
    };
  }

  static String _mimeForExt(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' || 'heif' => 'image/heic',
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
