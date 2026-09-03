import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

import '../../../core/services/api_service.dart';
import '../models/leadparceiro.dart';

class LeadParceiroRepository {
  Future<List<Map<String, dynamic>>> listarEstados() async {
    final response = await ApiService.get('/localidades/estados');
    if (response.statusCode != 200) {
      throw Exception(_extrairErro(response.body, 'Erro ao carregar estados.'));
    }
    return (jsonDecode(response.body) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarCidades(int estadoId) async {
    final response = await ApiService.get(
      '/localidades/estados/$estadoId/cidades',
    );
    if (response.statusCode != 200) {
      throw Exception(_extrairErro(response.body, 'Erro ao carregar cidades.'));
    }
    return (jsonDecode(response.body) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> adicionarEstabelecimento(
    int leadId,
    Map<String, dynamic> dados,
  ) async {
    final response = await ApiService.post(
      '/parceiros/$leadId/estabelecimentos',
      dados,
    );
    if (response.statusCode != 201) {
      throw Exception(
        _extrairErro(response.body, 'Erro ao cadastrar estabelecimento.'),
      );
    }
  }

  Future<void> atualizarEstabelecimento(
    int leadId,
    int estabelecimentoId,
    Map<String, dynamic> dados,
  ) async {
    final response = await ApiService.put(
      '/parceiros/$leadId/estabelecimentos/$estabelecimentoId',
      dados,
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extrairErro(response.body, 'Erro ao atualizar estabelecimento.'),
      );
    }
  }

  Future<Map<String, dynamic>> consultarAtendimento(
    int id,
    int estabelecimentoId,
  ) async {
    final response = await ApiService.get(
      '/lead-atendimento/$id?leadestabelecimento_id=$estabelecimentoId',
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception(
      _extrairErro(response.body, 'Erro ao carregar atendimento.'),
    );
  }

  Future<void> enviarMensagem(
    int id,
    int estabelecimentoId,
    String mensagem,
  ) async {
    final r = await ApiService.post(
      '/lead-atendimento/$id/mensagens?leadestabelecimento_id=$estabelecimentoId',
      {'mensagem': mensagem},
    );
    if (r.statusCode != 201) {
      throw Exception(_extrairErro(r.body, 'Erro ao enviar mensagem.'));
    }
  }

  Future<void> criarAgendamento(
    int id,
    int estabelecimentoId,
    Map<String, dynamic> dados,
  ) async {
    final r = await ApiService.post(
      '/lead-atendimento/$id/agendamentos?leadestabelecimento_id=$estabelecimentoId',
      dados,
    );
    if (r.statusCode != 201) {
      throw Exception(_extrairErro(r.body, 'Erro ao criar agendamento.'));
    }
  }

  Future<void> alterarAgendamento(
    int leadId,
    int estabelecimentoId,
    int itemId,
    String status,
  ) async {
    final r = await ApiService.patch(
      '/lead-atendimento/$leadId/agendamentos/$itemId?leadestabelecimento_id=$estabelecimentoId',
      {'status': status},
    );
    if (r.statusCode != 200) {
      throw Exception(_extrairErro(r.body, 'Erro ao atualizar agendamento.'));
    }
  }

  Future<void> criarMaterial(
    int id,
    int estabelecimentoId,
    Map<String, dynamic> dados,
  ) async {
    final r = await ApiService.post(
      '/lead-atendimento/$id/materiais?leadestabelecimento_id=$estabelecimentoId',
      dados,
    );
    if (r.statusCode != 201) {
      throw Exception(_extrairErro(r.body, 'Erro ao incluir material.'));
    }
  }

  Future<void> uploadMaterial({
    required int id,
    required int estabelecimentoId,
    required String titulo,
    required String tipo,
    String? descricao,
    required PlatformFile arquivo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/lead-atendimento/$id/materiais-upload?leadestabelecimento_id=$estabelecimentoId',
      ),
    );
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['titulo'] = titulo;
    request.fields['tipo'] = tipo;
    if (descricao != null && descricao.isNotEmpty) {
      request.fields['descricao'] = descricao;
    }
    if (kIsWeb || arquivo.path == null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          arquivo.bytes!,
          filename: arquivo.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'arquivo',
          arquivo.path!,
          filename: arquivo.name,
        ),
      );
    }
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 201) {
      throw Exception(_extrairErro(response.body, 'Erro ao enviar arquivo.'));
    }
  }

  Future<void> excluirMaterial(
    int leadId,
    int estabelecimentoId,
    int itemId,
  ) async {
    final r = await ApiService.delete(
      '/lead-atendimento/$leadId/materiais/$itemId?leadestabelecimento_id=$estabelecimentoId',
    );
    if (r.statusCode != 200) {
      throw Exception(_extrairErro(r.body, 'Erro ao excluir material.'));
    }
  }

  Future<List<LeadParceiro>> listar() async {
    final response = await ApiService.get('/parceiros');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(LeadParceiro.fromJson)
            .toList();
      }
      return [];
    }

    throw Exception(_extrairErro(response.body, 'Erro ao listar leads.'));
  }

  Future<LeadParceiro> buscar(int leadparceiroId) async {
    final response = await ApiService.get('/parceiros/$leadparceiroId');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return LeadParceiro.fromJson(data);
      }
    }

    throw Exception(_extrairErro(response.body, 'Erro ao buscar lead.'));
  }

  Future<LeadParceiro> atualizar({
    required int leadparceiroId,
    required String nmresponsavel,
    required String telefone,
    required String email,
  }) async {
    final dados = <String, dynamic>{
      'nmresponsavel': nmresponsavel,
      'telefone': telefone,
      'email': email,
    };
    final response = await ApiService.put('/parceiros/$leadparceiroId', dados);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return LeadParceiro.fromJson(data);
      }
    }

    throw Exception(_extrairErro(response.body, 'Erro ao atualizar lead.'));
  }

  Future<Map<String, dynamic>> converterEmParceiro({
    required int leadparceiroId,
    required int leadestabelecimentoId,
    required String nomeOrganizacao,
    required String nomeLoja,
    required String tipoLoja,
    required String emailResponsavel,
    required double taxaProdutos,
    required double taxaIngressos,
  }) async {
    final response = await ApiService.post(
      '/parceiros/$leadparceiroId/converter-em-parceiro',
      {
        'leadestabelecimento_id': leadestabelecimentoId,
        'nome_organizacao': nomeOrganizacao.trim(),
        'nome_loja': nomeLoja.trim(),
        'tipo_loja': tipoLoja,
        'email_responsavel': emailResponsavel.trim().toLowerCase(),
        'taxa_produtos': taxaProdutos,
        'taxa_ingressos': taxaIngressos,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    }

    throw Exception(
      _extrairErro(response.body, 'Erro ao converter lead em parceiro.'),
    );
  }

  Future<void> criarContrato(
    int leadestabelecimentoId,
    Map<String, dynamic> dados,
  ) async {
    final r = await ApiService.post(
      '/lead-estabelecimento-contratos/estabelecimento/$leadestabelecimentoId',
      dados,
    );
    if (r.statusCode != 201) {
      throw Exception(_extrairErro(r.body, 'Erro ao disponibilizar contrato.'));
    }
  }

  Future<String> previsualizarContrato(
    int leadestabelecimentoId,
    Map<String, dynamic> dados,
  ) async {
    final r = await ApiService.post(
      '/lead-estabelecimento-contratos/estabelecimento/$leadestabelecimentoId/previsualizar',
      dados,
    );
    if (r.statusCode != 200) {
      throw Exception(
        _extrairErro(r.body, 'Erro ao gerar prévia do contrato.'),
      );
    }
    final resposta = jsonDecode(r.body) as Map<String, dynamic>;
    return resposta['conteudocontrato']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> reenviarConviteParceiro({
    required int leadparceiroId,
  }) async {
    final response = await ApiService.post(
      '/parceiros/$leadparceiroId/reenviar-convite-parceiro',
      {},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return {};
    }

    throw Exception(
      _extrairErro(response.body, 'Erro ao reenviar convite do parceiro.'),
    );
  }

  String _extrairErro(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is List) {
          return detail
              .map((item) {
                if (item is Map && item['msg'] != null) {
                  return item['msg'].toString();
                }
                return item.toString();
              })
              .join(' ');
        }
        return detail.toString();
      }
    } catch (_) {}

    final texto = body.trim();
    return texto.isEmpty ? fallback : texto;
  }
}
