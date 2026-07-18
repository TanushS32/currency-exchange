import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Browsers have no native "photo gallery" — the closest equivalent to
/// gal's save-to-gallery on mobile is triggering a normal file download.
void downloadBytesOnWeb(Uint8List bytes, String filename) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
