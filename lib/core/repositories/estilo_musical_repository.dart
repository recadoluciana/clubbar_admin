import 'dart:convert';

import '../services/api_service.dart';

class EstiloMusicalAdmin {
  final int id;
  final String nome;
  final String situacao;
  const EstiloMusicalAdmin(this.id, this.nome, this.situacao);
  factory EstiloMusicalAdmin.fromJson(Map<String, dynamic> j) =>
      EstiloMusicalAdmin(
        int.tryParse('${j['estilomusical_id']}') ?? 0,
        '${j['nmestilomusical'] ?? ''}',
        '${j['sitestilomusical'] ?? 'ATIVO'}'.toUpperCase(),
      );
}

class EstiloMusicalRepository {
  Future<List<EstiloMusicalAdmin>> listar() async {
    final r = await ApiService.get('/admin/estilos-musicais');
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    return (jsonDecode(r.body) as List)
        .map((e) => EstiloMusicalAdmin.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> salvar(
    EstiloMusicalAdmin? item,
    String nome,
    String situacao,
  ) async {
    final body = {'nmestilomusical': nome, 'sitestilomusical': situacao};
    final r = item == null
        ? await ApiService.post('/admin/estilos-musicais', body)
        : await ApiService.put('/admin/estilos-musicais/${item.id}', body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_erro(r.body));
    }
  }

  Future<void> excluir(int id) async {
    final r = await ApiService.delete('/admin/estilos-musicais/$id');
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_erro(r.body));
    }
  }

  String _erro(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) return '${j['detail']}';
    } catch (_) {}
    return 'Não foi possível concluir a operação.';
  }
}
