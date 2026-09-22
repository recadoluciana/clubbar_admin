import 'dart:convert';

import '../services/api_service.dart';

class PoliticaCompraRepository {
  String _erro(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map && data['detail'] != null
          ? data['detail'].toString()
          : body;
    } catch (_) {
      return body;
    }
  }

  Future<List<Map<String, dynamic>>> listar(String tipo) async {
    final resposta = await ApiService.get('/politicas/compra?tipo=$tipo');
    if (resposta.statusCode != 200) throw Exception(_erro(resposta.body));
    return (jsonDecode(resposta.body) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> criar(Map<String, dynamic> dados) async {
    final resposta = await ApiService.post('/politicas/compra', dados);
    if (resposta.statusCode != 201) throw Exception(_erro(resposta.body));
  }

  Future<void> vigenciar(int politicaId) async {
    final resposta = await ApiService.post(
      '/politicas/compra/$politicaId/vigenciar',
      {},
    );
    if (resposta.statusCode != 200) throw Exception(_erro(resposta.body));
  }
}
