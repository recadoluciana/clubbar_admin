import 'dart:convert';

import '../services/api_service.dart';

class SuperAdminRepository {
  dynamic _decodificarResposta(dynamic response, String mensagem) {
    final dynamic data = response.body.toString().trim().isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detalhe = data is Map ? data['detail']?.toString() : null;
      throw Exception(detalhe ?? mensagem);
    }
    return data;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final response = await ApiService.get('/superadmin/dashboard');
    return Map<String, dynamic>.from(
      _decodificarResposta(response, 'Erro ao carregar o dashboard.'),
    );
  }

  Future<List<Map<String, dynamic>>> listarOrganizacoes() async {
    final response = await ApiService.get('/superadmin/organizacoes');
    final data = _decodificarResposta(
      response,
      'Erro ao carregar as organizações parceiras.',
    );
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarLojas(int organizacaoId) async {
    final response = await ApiService.get(
      '/superadmin/organizacoes/$organizacaoId/lojas',
    );
    final data = _decodificarResposta(
      response,
      'Erro ao carregar os estabelecimentos.',
    );
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarUsuarios(int organizacaoId) async {
    final response = await ApiService.get(
      '/superadmin/organizacoes/$organizacaoId/usuarios',
    );
    final data = _decodificarResposta(
      response,
      'Erro ao carregar os usuários.',
    );
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> vendasHoje({
    int? organizacaoId,
    int? lojaId,
  }) async {
    final parametros = <String>[];
    if (organizacaoId != null) {
      parametros.add('organizacao_id=$organizacaoId');
    }
    if (lojaId != null) parametros.add('loja_id=$lojaId');
    final query = parametros.isEmpty ? '' : '?${parametros.join('&')}';
    final response = await ApiService.get('/superadmin/vendas-hoje$query');
    return Map<String, dynamic>.from(
      _decodificarResposta(response, 'Erro ao carregar as vendas de hoje.'),
    );
  }
}
