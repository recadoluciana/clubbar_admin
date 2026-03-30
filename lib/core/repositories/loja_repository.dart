import 'dart:convert';

import '../../models/loja.dart';
import '../services/api_service.dart';

class LojaRepository {
  Future<List<Loja>> listar(int organizacaoId) async {
    final response = await ApiService.get('/organizacoes/$organizacaoId/lojas');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data.map((e) => Loja.fromJson(e)).toList();
      }

      return [];
    }

    throw Exception('Erro ao listar lojas: ${response.body}');
  }

  Future<void> criar({
    required int organizacaoId,
    required String nome,
    required String status,
    String? cnpj,
    String? email,
    String? telefone,
  }) async {
    final response = await ApiService.post(
      '/organizacoes/$organizacaoId/lojas',
      {
        'nmloja': nome,
        'sitloja': status,
        'cnpjloja': cnpj,
        'emailloja': email,
        'telloja': telefone,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar loja: ${response.body}');
    }
  }

  Future<void> atualizar({
    required int lojaId,
    required String nome,
    required String status,
    String? cnpj,
    String? email,
    String? telefone,
  }) async {
    final response = await ApiService.put(
      '/lojas/$lojaId',
      {
        'nmloja': nome,
        'sitloja': status,
        'cnpjloja': cnpj,
        'emailloja': email,
        'telloja': telefone,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar loja: ${response.body}');
    }
  }

  Future<void> excluir(int lojaId) async {
    final response = await ApiService.delete('/lojas/$lojaId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir loja: ${response.body}');
    }
  }
}