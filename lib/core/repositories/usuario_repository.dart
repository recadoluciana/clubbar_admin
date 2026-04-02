import 'dart:convert';

import '../../models/usuario.dart';
import '../services/api_service.dart';

class UsuarioRepository {
  Future<List<Usuario>> listar(int organizacaoId) async {
    final response =
        await ApiService.get('/organizacoes/$organizacaoId/usuarios');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data.map((e) => Usuario.fromJson(e)).toList();
      }

      return [];
    }

    throw Exception('Erro ao listar usuários: ${response.body}');
  }

  Future<void> criar({
    required int organizacaoId,
    required String nome,
    required String email,
    required String senha,
    int? lojaId,
    String situsuario = 'ATIVO',
  }) async {
    final response = await ApiService.post(
      '/organizacoes/$organizacaoId/usuarios',
      {
        'nmusuario': nome,
        'emailuser': email,
        'senha': senha,
        'loja_id': lojaId,
        'situsuario': situsuario,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar usuário: ${response.body}');
    }
  }

  Future<void> atualizar({
    required int usuarioId,
    String? nome,
    String? email,
    String? senha,
    int? lojaId,
    String? situsuario,
  }) async {
    final response = await ApiService.put(
      '/usuarios/$usuarioId',
      {
        'nmusuario': nome,
        'emailuser': email,
        'senha': senha,
        'loja_id': lojaId,
        'situsuario': situsuario,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar usuário: ${response.body}');
    }
  }

  Future<void> excluir(int usuarioId) async {
    final response = await ApiService.delete('/usuarios/$usuarioId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir usuário: ${response.body}');
    }
  }
}