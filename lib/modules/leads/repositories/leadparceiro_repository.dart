import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

import '../../../core/services/api_service.dart';
import '../models/leadparceiro.dart';

class LeadParceiroRepository {
  Future<Map<String, dynamic>> consultarAtendimento(int id) async {
    final response = await ApiService.get('/lead-atendimento/$id');
    if (response.statusCode == 200)
      return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception(
      _extrairErro(response.body, 'Erro ao carregar atendimento.'),
    );
  }

  Future<void> enviarMensagem(int id, String mensagem) async {
    final r = await ApiService.post('/lead-atendimento/$id/mensagens', {
      'mensagem': mensagem,
    });
    if (r.statusCode != 201)
      throw Exception(_extrairErro(r.body, 'Erro ao enviar mensagem.'));
  }

  Future<void> criarAgendamento(int id, Map<String, dynamic> dados) async {
    final r = await ApiService.post(
      '/lead-atendimento/$id/agendamentos',
      dados,
    );
    if (r.statusCode != 201)
      throw Exception(_extrairErro(r.body, 'Erro ao criar agendamento.'));
  }

  Future<void> alterarAgendamento(int leadId, int itemId, String status) async {
    final r = await ApiService.patch(
      '/lead-atendimento/$leadId/agendamentos/$itemId',
      {'status': status},
    );
    if (r.statusCode != 200)
      throw Exception(_extrairErro(r.body, 'Erro ao atualizar agendamento.'));
  }

  Future<void> criarMaterial(int id, Map<String, dynamic> dados) async {
    final r = await ApiService.post('/lead-atendimento/$id/materiais', dados);
    if (r.statusCode != 201)
      throw Exception(_extrairErro(r.body, 'Erro ao incluir material.'));
  }

  Future<void> uploadMaterial({
    required int id,
    required String titulo,
    required String tipo,
    String? descricao,
    required PlatformFile arquivo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConfig.baseUrl +
            '/lead-atendimento/' +
            id.toString() +
            '/materiais-upload',
      ),
    );
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty)
      request.headers['Authorization'] = 'Bearer $token';
    request.fields['titulo'] = titulo;
    request.fields['tipo'] = tipo;
    if (descricao != null && descricao.isNotEmpty)
      request.fields['descricao'] = descricao;
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
    if (response.statusCode != 201)
      throw Exception(_extrairErro(response.body, 'Erro ao enviar arquivo.'));
  }

  Future<void> excluirMaterial(int leadId, int itemId) async {
    final r = await ApiService.delete(
      '/lead-atendimento/$leadId/materiais/$itemId',
    );
    if (r.statusCode != 200)
      throw Exception(_extrairErro(r.body, 'Erro ao excluir material.'));
  }

  Future<void> reenviarAcesso(int id) async {
    final r = await ApiService.post(
      '/lead-atendimento/$id/reenviar-acesso',
      {},
    );
    if (r.statusCode != 200)
      throw Exception(_extrairErro(r.body, 'Erro ao reenviar acesso.'));
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
    required String tipo,
    required String telefone,
    required String email,
    required String status,
  }) async {
    final response = await ApiService.put('/parceiros/$leadparceiroId', {
      'nmresponsavel': nmresponsavel,
      'tipo': tipo,
      'telefone': telefone,
      'email': email,
      'status': status,
    });

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
