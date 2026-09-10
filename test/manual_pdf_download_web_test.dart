@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:clubbar_gestao/modules/manuais/manual_pdf_download.dart';

void main() {
  test(
    'download web entrega o PDF ao navegador com nome e conteúdo corretos',
    () async {
      String? url;
      String? nome;
      final listener = ((web.Event event) {
        final target = event.target;
        if (target != null && target.isA<web.HTMLAnchorElement>()) {
          final link = target as web.HTMLAnchorElement;
          event.preventDefault();
          url = link.href;
          nome = link.download;
        }
      }).toJS;
      web.document.addEventListener('click', listener);
      try {
        final bytes = Uint8List.fromList(
          utf8.encode('%PDF-1.4\nTeste do manual\n%%EOF'),
        );
        await salvarManualPdf(bytes, 'manual-parceiro-v1.pdf');
        expect(nome, 'manual-parceiro-v1.pdf');
        expect(url, startsWith('blob:'));
        final response = await web.window.fetch(url!.toJS).toDart;
        expect(response.headers.get('content-type'), 'application/pdf');
        final data = await response.arrayBuffer().toDart;
        expect(data.toDart.asUint8List(), orderedEquals(bytes));
        expect(
          web.document.querySelector('a[download="manual-parceiro-v1.pdf"]'),
          isNull,
        );
      } finally {
        web.document.removeEventListener('click', listener);
      }
    },
  );
}
