import 'dart:convert';

import '../services/api_service.dart';

class ContratoPadraoRepository {
  String _erro(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map && data['detail'] != null ? data['detail'].toString() : body;
    } catch (_) { return body; }
  }

  Future<List<Map<String, dynamic>>> listar() async {
    final resposta = await ApiService.get('/contratos-padrao');
    if (resposta.statusCode != 200) throw Exception(_erro(resposta.body));
    return (jsonDecode(resposta.body) as List)
        .map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> publicar(Map<String, dynamic> dados) async {
    final resposta = await ApiService.post('/contratos-padrao', dados);
    if (resposta.statusCode != 201) throw Exception(_erro(resposta.body));
    return Map<String, dynamic>.from(jsonDecode(resposta.body) as Map);
  }
}
