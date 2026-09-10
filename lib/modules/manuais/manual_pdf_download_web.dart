import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> salvarManualPdf(Uint8List bytes, String nome) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = nome
    ..style.display = 'none';
  try {
    web.document.body!.appendChild(link);
    link.click();
  } finally {
    link.remove();
    // Allow the browser to start consuming the Blob before releasing it.
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  }
}
