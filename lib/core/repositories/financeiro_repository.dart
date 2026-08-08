import 'dart:convert';

import '../services/api_service.dart';

class FinanceiroRepository {
  Future<List<Map<String, dynamic>>> listar({String? status}) async {
    final filtro = status == null ? '' : '?status=$status';
    final response = await ApiService.get('/financeiro/repasses$filtro');
    if (response.statusCode != 200) throw Exception(_mensagem(response.body));
    return (jsonDecode(response.body) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> atualizar(int id, Map<String, dynamic> dados) async {
    final response = await ApiService.patch('/financeiro/repasses/$id', dados);
    if (response.statusCode != 200) throw Exception(_mensagem(response.body));
  }

  String _mensagem(String body) {
    try {
      final data = jsonDecode(body);
      return data['detail']?.toString() ??
          'Erro ao processar operação financeira.';
    } catch (_) {
      return 'Erro ao processar operação financeira.';
    }
  }
}
