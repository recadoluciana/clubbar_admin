import 'dart:convert';
import 'dart:typed_data';
import '../services/api_service.dart';

class ManualRepository {
  Future<Uint8List> exportarBackup() async {
    final r = await ApiService.get('/manuais/backup/exportar');
    if (r.statusCode != 200) _decode(r);
    return r.bodyBytes;
  }

  Future<Map<String, dynamic>> importarBackup(
    Map<String, dynamic> dados,
  ) async {
    final r = await ApiService.post('/manuais/backup/importar', dados);
    if (r.statusCode == 422) {
      throw Exception(
        'Backup inválido ou incompatível. Nenhum manual foi alterado.',
      );
    }
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  dynamic _decode(dynamic response, [int expected = 200]) {
    final body = utf8.decode(response.bodyBytes as List<int>);
    if (response.statusCode != expected) {
      String message = 'Não foi possível acessar os manuais.';
      try {
        final data = jsonDecode(body);
        if (data is Map && data['detail'] is String) {
          message = data['detail'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }
    return jsonDecode(body);
  }

  Future<List<Map<String, dynamic>>> listar() async =>
      (_decode(await ApiService.get('/manuais')) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<Map<String, dynamic>> consultar(String slug, [int? versao]) async =>
      Map<String, dynamic>.from(
        _decode(
              await ApiService.get(
                '/manuais/$slug${versao == null ? '' : '?versao=$versao'}',
              ),
            )
            as Map,
      );

  Future<void> publicar(String slug, Map<String, dynamic> dados) async {
    _decode(await ApiService.post('/manuais/$slug/versoes', dados), 201);
  }

  Future<Uint8List> pdf(String slug, int versao, String? publico) async {
    final response = await ApiService.get(
      '/manuais/$slug/pdf?versao=$versao${publico == null ? '' : '&publico=$publico'}',
    );
    if (response.statusCode != 200) _decode(response);
    if (!(response.headers['content-type'] ?? '').contains('application/pdf')) {
      throw Exception('O servidor não retornou um PDF. Tente novamente.');
    }
    return response.bodyBytes;
  }
}
