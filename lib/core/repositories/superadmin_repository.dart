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
      'Erro ao carregar as empresas parceiras.',
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
    DateTime? dataInicio,
    DateTime? dataFim,
    int? organizacaoId,
    int? lojaId,
  }) async {
    final parametros = <String>[];
    String formatarData(DateTime data) {
      final ano = data.year.toString().padLeft(4, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final dia = data.day.toString().padLeft(2, '0');
      return '$ano-$mes-$dia';
    }

    if (dataInicio != null) {
      parametros.add('data_inicio=${formatarData(dataInicio)}');
    }
    if (dataFim != null) {
      parametros.add('data_fim=${formatarData(dataFim)}');
    }
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
