import 'dart:convert';

import '../services/api_service.dart';

class FinanceiroRepository {
  Future<Map<String, dynamic>> consultarExtratoAsaas({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    String data(DateTime valor) =>
        '${valor.year.toString().padLeft(4, '0')}-'
        '${valor.month.toString().padLeft(2, '0')}-'
        '${valor.day.toString().padLeft(2, '0')}';

    final response = await ApiService.get(
      '/financeiro/extrato-asaas'
      '?data_inicio=${data(inicio)}&data_fim=${data(fim)}&limite=100',
    );
    final body = response.body.trim().isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode != 200) {
      throw Exception(
        body['detail']?.toString() ??
            'Não foi possível consultar o extrato do Clubbar no Asaas.',
      );
    }
    return body;
  }
}
