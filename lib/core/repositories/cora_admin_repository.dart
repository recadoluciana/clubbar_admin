import 'dart:convert';

import '../services/api_service.dart';

class CoraDuvidaAdmin {
  final int id;
  final String pergunta;
  final String resposta;
  final int ordem;
  final String situacao;
  const CoraDuvidaAdmin(
    this.id,
    this.pergunta,
    this.resposta,
    this.ordem,
    this.situacao,
  );
  factory CoraDuvidaAdmin.fromJson(Map<String, dynamic> j) => CoraDuvidaAdmin(
    int.tryParse('${j['coraduvida_id']}') ?? 0,
    '${j['pergunta'] ?? ''}',
    '${j['resposta'] ?? ''}',
    int.tryParse('${j['idordem']}') ?? 1,
    '${j['sitduvida'] ?? 'ATIVA'}'.toUpperCase(),
  );
}

class CoraAtendimentoResumo {
  final int clienteId;
  final String nome;
  final String email;
  final String ultimaMensagem;
  final DateTime? data;
  final int pendentes;
  const CoraAtendimentoResumo({
    required this.clienteId,
    required this.nome,
    required this.email,
    required this.ultimaMensagem,
    required this.data,
    required this.pendentes,
  });
  factory CoraAtendimentoResumo.fromJson(Map<String, dynamic> j) =>
      CoraAtendimentoResumo(
        clienteId: int.tryParse('${j['cliente_id']}') ?? 0,
        nome: '${j['nmcliente'] ?? ''}',
        email: '${j['emailcliente'] ?? ''}',
        ultimaMensagem: '${j['ultima_mensagem'] ?? ''}',
        data: DateTime.tryParse('${j['dtultima_mensagem'] ?? ''}')?.toLocal(),
        pendentes: int.tryParse('${j['pendentes']}') ?? 0,
      );
}

class CoraMensagemAdmin {
  final int id;
  final String origem;
  final String mensagem;
  final DateTime? data;
  const CoraMensagemAdmin(this.id, this.origem, this.mensagem, this.data);
  factory CoraMensagemAdmin.fromJson(Map<String, dynamic> j) =>
      CoraMensagemAdmin(
        int.tryParse('${j['coramensagem_id']}') ?? 0,
        '${j['origem'] ?? ''}',
        '${j['mensagem'] ?? ''}',
        DateTime.tryParse('${j['dtcriacao'] ?? ''}')?.toLocal(),
      );
}

class CoraAtendimentoDetalhe {
  final String nome;
  final String email;
  final List<CoraMensagemAdmin> mensagens;
  const CoraAtendimentoDetalhe(this.nome, this.email, this.mensagens);
}

class CoraAdminRepository {
  Future<List<CoraDuvidaAdmin>> listarDuvidas() async {
    final r = await ApiService.get('/cora/admin/duvidas');
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    return (jsonDecode(r.body) as List)
        .map((e) => CoraDuvidaAdmin.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> salvarDuvida(
    CoraDuvidaAdmin? item,
    String pergunta,
    String resposta,
    int ordem,
    String situacao,
  ) async {
    final dados = {
      'pergunta': pergunta,
      'resposta': resposta,
      'idordem': ordem,
      'sitduvida': situacao,
    };
    final r = item == null
        ? await ApiService.post('/cora/admin/duvidas', dados)
        : await ApiService.put('/cora/admin/duvidas/${item.id}', dados);
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }

  Future<void> excluirDuvida(int id) async {
    final r = await ApiService.delete('/cora/admin/duvidas/$id');
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }

  Future<List<CoraAtendimentoResumo>> listarAtendimentos() async {
    final r = await ApiService.get('/cora/admin/atendimentos');
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    return (jsonDecode(r.body) as List)
        .map(
          (e) => CoraAtendimentoResumo.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CoraAtendimentoDetalhe> consultarAtendimento(int clienteId) async {
    final r = await ApiService.get('/cora/admin/atendimentos/$clienteId');
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    final j = Map<String, dynamic>.from(jsonDecode(r.body));
    return CoraAtendimentoDetalhe(
      '${j['nmcliente'] ?? ''}',
      '${j['emailcliente'] ?? ''}',
      (j['mensagens'] as List)
          .map((e) => CoraMensagemAdmin.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<void> responder(int clienteId, String mensagem) async {
    final r = await ApiService.post(
      '/cora/admin/atendimentos/$clienteId/mensagens',
      {'mensagem': mensagem},
    );
    if (r.statusCode < 200 || r.statusCode >= 300)
      throw Exception(_erro(r.body));
  }

  String _erro(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) return '${j['detail']}';
    } catch (_) {}
    return 'Não foi possível concluir a operação.';
  }
}
