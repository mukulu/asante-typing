import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;
import 'package:file_picker/file_picker.dart';

/// Opens a .txt file picker across platforms (Web, mobile, desktop)
/// and returns the entire file contents as a String.
/// Returns null if the user cancels or reading fails.
Future<String?> pickTextFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['txt','csv'],
    withData: true,           // ensures bytes on Web; often on desktop/mobile too
    withReadStream: true,     // desktop/mobile stream fallback when bytes are null
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;

  // 1) Prefer in-memory bytes (works on Web and often on mobile/desktop)
  if (file.bytes != null) {
    return utf8.decode(file.bytes!, allowMalformed: true);
  }

  // 2) Fallback to readStream on platforms where file bytes aren't preloaded
  if (file.readStream != null) {
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in file.readStream!) {
      buffer.add(chunk);
    }
    return utf8.decode(buffer.toBytes(), allowMalformed: true);
  }

  // 3) As a last resort, give up (we intentionally avoid dart:io here
  // to stay web-safe without conditional imports).
  return null;
}
