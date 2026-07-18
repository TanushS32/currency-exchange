import 'dart:typed_data';

/// No-op on non-web platforms; the real implementation (web_download_web.dart)
/// is swapped in at compile time via a conditional import.
void downloadBytesOnWeb(Uint8List bytes, String filename) {}
