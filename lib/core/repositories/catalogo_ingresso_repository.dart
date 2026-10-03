import 'dart:convert';

import '../services/api_service.dart';

class BeneficioCatalogo {
  final int id;
  final String codigo;
  final String nome;
  final bool exigeComprovante;
  final String situacao;
  final int ordem;
  const BeneficioCatalogo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.exigeComprovante,
    required this.situacao,
    required this.ordem,
  });
  factory BeneficioCatalogo.fromJson(Map<String, dynamic> j) =>
      BeneficioCatalogo(
        id: (j['beneficio_id'] as num?)?.toInt() ?? 0,
        codigo: '${j['cdbeneficio'] ?? ''}',
        nome: '${j['nmbeneficio'] ?? ''}',
        exigeComprovante: j['exigecomprovante'] == true,
        situacao: '${j['situacao'] ?? 'ATIVO'}',
        ordem: (j['nrordem'] as num?)?.toInt() ?? 1,
      );
  Map<String, dynamic> payload() => {
    'cdbeneficio': codigo,
    'nmbeneficio': nome,
    'exigecomprovante': exigeComprovante,
    'situacao': situacao,
    'nrordem': ordem,
  };
}

class ModalidadeCatalogo {
  final int id;
  final String codigo;
  final String nome;
  final String tipo;
  final bool aplicaCotaLegal;
  final bool exigeBeneficio;
  final bool exigeComprovante;
  final bool permitePersonalizarNome;
  final String situacao;
  final int ordem;
  final List<BeneficioCatalogo> beneficios;
  const ModalidadeCatalogo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.tipo,
    required this.aplicaCotaLegal,
    required this.exigeBeneficio,
    required this.exigeComprovante,
    required this.permitePersonalizarNome,
    required this.situacao,
    required this.ordem,
    required this.beneficios,
  });
  factory ModalidadeCatalogo.fromJson(Map<String, dynamic> j) =>
      ModalidadeCatalogo(
        id: (j['modalidade_id'] as num?)?.toInt() ?? 0,
        codigo: '${j['cdmodalidade'] ?? ''}',
        nome: '${j['nmmodalidade'] ?? ''}',
        tipo: '${j['tipomodalidade'] ?? 'COMERCIAL'}',
        aplicaCotaLegal: j['aplicacotalegal'] == true,
        exigeBeneficio: j['exigebeneficio'] == true,
        exigeComprovante: j['exigecomprovante'] == true,
        permitePersonalizarNome: j['permitepersonalizarnome'] == true,
        situacao: '${j['situacao'] ?? 'ATIVO'}',
        ordem: (j['nrordem'] as num?)?.toInt() ?? 1,
        beneficios: (j['beneficios'] as List? ?? const [])
            .map(
              (e) => BeneficioCatalogo.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
}

class CatalogoIngressoRepository {
  String _erro(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) return '${j['detail']}';
    } catch (_) {}
    return 'Não foi possível concluir a operação.';
  }

  Future<List<BeneficioCatalogo>> listarBeneficios() async {
    final r = await ApiService.get(
      '/ingressos-catalogo/beneficios?incluir_inativos=true',
    );
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    return (jsonDecode(r.body) as List)
        .map((e) => BeneficioCatalogo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ModalidadeCatalogo>> listarModalidades() async {
    final r = await ApiService.get(
      '/ingressos-catalogo/modalidades?incluir_inativos=true',
    );
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    return (jsonDecode(r.body) as List)
        .map((e) => ModalidadeCatalogo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> salvarBeneficio(
    BeneficioCatalogo? atual,
    Map<String, dynamic> body,
  ) async {
    final r = atual == null
        ? await ApiService.post('/ingressos-catalogo/beneficios', body)
        : await ApiService.put(
            '/ingressos-catalogo/beneficios/${atual.id}',
            body,
          );
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }

  Future<void> salvarModalidade(
    ModalidadeCatalogo? atual,
    Map<String, dynamic> body,
  ) async {
    final r = atual == null
        ? await ApiService.post('/ingressos-catalogo/modalidades', body)
        : await ApiService.put(
            '/ingressos-catalogo/modalidades/${atual.id}',
            body,
          );
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }

  Future<void> excluirBeneficio(int id) async {
    final r = await ApiService.delete('/ingressos-catalogo/beneficios/$id');
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }

  Future<void> excluirModalidade(int id) async {
    final r = await ApiService.delete('/ingressos-catalogo/modalidades/$id');
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }
}
