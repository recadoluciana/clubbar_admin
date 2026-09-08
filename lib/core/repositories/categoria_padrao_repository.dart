import 'dart:convert';

import '../services/api_service.dart';

class CategoriaPadraoAdmin {
  final int id;
  final String nome;
  final String icone;
  final String situacao;
  final int ordem;

  const CategoriaPadraoAdmin({
    required this.id,
    required this.nome,
    required this.icone,
    required this.situacao,
    required this.ordem,
  });

  factory CategoriaPadraoAdmin.fromJson(Map<String, dynamic> json) =>
      CategoriaPadraoAdmin(
        id: int.tryParse('${json['categoriapadrao_id']}') ?? 0,
        nome: '${json['nmcategoria'] ?? ''}',
        icone: '${json['dsicone'] ?? 'more_horiz'}',
        situacao: '${json['sitcategoria'] ?? 'ATIVA'}'.toUpperCase(),
        ordem: int.tryParse('${json['idordcategoria']}') ?? 1,
      );
}

class CategoriaPadraoRepository {
  Future<List<CategoriaPadraoAdmin>> listar() async {
    final resposta = await ApiService.get('/admin/categorias-padrao');
    if (resposta.statusCode != 200) throw Exception(_erro(resposta.body));
    return (jsonDecode(resposta.body) as List)
        .map((e) => CategoriaPadraoAdmin.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> alterarSituacao(int id, bool ativa) async {
    final resposta = await ApiService.patch(
      '/admin/categorias-padrao/$id/situacao',
      {'sitcategoria': ativa ? 'ATIVA' : 'INATIVA'},
    );
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception(_erro(resposta.body));
    }
  }

  String _erro(String body) {
    try {
      final dados = jsonDecode(body);
      if (dados is Map && dados['detail'] != null) return '${dados['detail']}';
    } catch (_) {}
    return 'Não foi possível concluir a operação.';
  }
}
