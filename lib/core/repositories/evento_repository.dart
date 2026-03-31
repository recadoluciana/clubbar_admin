import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../models/evento.dart';
import '../services/api_service.dart';

class EventoRepository {
  Future<List<Evento>> listar(int lojaId) async {
    final response = await ApiService.get('/eventos/loja/$lojaId');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Evento.fromJson(e)).toList();
    }

    throw Exception('Erro ao listar eventos: ${response.body}');
  }

  Future<void> criar({
    required int organizacaoId,
    required int lojaId,
    required int produtoIdIngresso,
    required String titulo,
    String? descricao,
    required String dataInicio,
    String? dataFim,
    String? local,
    String? endereco,
    String? status,
    File? imagem,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/eventos');

    final request = http.MultipartRequest('POST', uri);

    request.fields['organizacao_id'] = organizacaoId.toString();
    request.fields['loja_id'] = lojaId.toString();
    request.fields['produto_id_ingresso'] = produtoIdIngresso.toString();
    request.fields['nmtituloevento'] = titulo;
    request.fields['dtinicioevento'] = dataInicio;

    if (descricao != null && descricao.isNotEmpty) {
      request.fields['dsdescevento'] = descricao;
    }
    if (dataFim != null && dataFim.isNotEmpty) {
      request.fields['dtfimevento'] = dataFim;
    }
    if (local != null && local.isNotEmpty) {
      request.fields['nmlocalevento'] = local;
    }
    if (endereco != null && endereco.isNotEmpty) {
      request.fields['dsendlocevento'] = endereco;
    }
    if (status != null && status.isNotEmpty) {
      request.fields['statusevento'] = status;
    }

    if (imagem != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'urlbannerevento',
          imagem.path,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar evento: $body');
    }
  }

  Future<void> atualizar({
    required int eventoId,
    String? titulo,
    String? descricao,
    String? dataInicio,
    String? dataFim,
    String? local,
    String? endereco,
    String? status,
    File? imagem,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/eventos/$eventoId');

    final request = http.MultipartRequest('PUT', uri);

    if (titulo != null && titulo.isNotEmpty) {
      request.fields['nmtituloevento'] = titulo;
    }
    if (descricao != null) {
      request.fields['dsdescevento'] = descricao;
    }
    if (dataInicio != null && dataInicio.isNotEmpty) {
      request.fields['dtinicioevento'] = dataInicio;
    }
    if (dataFim != null) {
      request.fields['dtfimevento'] = dataFim;
    }
    if (local != null) {
      request.fields['nmlocalevento'] = local;
    }
    if (endereco != null) {
      request.fields['dsendlocevento'] = endereco;
    }
    if (status != null && status.isNotEmpty) {
      request.fields['statusevento'] = status;
    }

    if (imagem != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'urlbannerevento',
          imagem.path,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar evento: $body');
    }
  }

  Future<void> excluir(int eventoId) async {
    final response = await ApiService.delete('/eventos/$eventoId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir evento: ${response.body}');
    }
  }
}