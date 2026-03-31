import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../core/config/api_config.dart';
import '../../models/loja.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LojaRepository {
  Future<List<Loja>> listar(int organizacaoId) async {
    final response =
        await ApiService.get('/lojas/organizacoes/$organizacaoId/lojas_todas');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data.map((e) => Loja.fromJson(e)).toList();
      }

      return [];
    }

    throw Exception('Erro ao listar lojas: ${response.body}');
  }

  Future<http.MultipartFile> _montarArquivoImagem(
    String fieldName,
    File imagem,
  ) async {
    final mimeType = lookupMimeType(imagem.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');

    return await http.MultipartFile.fromPath(
      fieldName,
      imagem.path,
      contentType: MediaType(parts[0], parts[1]),
    );
  }

  Future<void> criar({
    required int organizacaoId,
    required int cidadeId,
    required String nome,
    String? bairro,
    String? telefone,
    String? horario,
    int? diasValidade,
    File? imagem,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/lojas');

    final request = http.MultipartRequest('POST', uri);

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['organizacao_id'] = organizacaoId.toString();
    request.fields['cidade_id'] = cidadeId.toString();
    request.fields['nmloja'] = nome;
    request.fields['dsbairroloja'] = bairro ?? '';
    request.fields['nrtelloja'] = telefone ?? '';
    request.fields['dshorarioloja'] = horario ?? '';

    if (diasValidade != null) {
      request.fields['nrdiavalidade'] = diasValidade.toString();
    }

    if (imagem != null) {
      request.files.add(await _montarArquivoImagem('file', imagem));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar loja: $responseBody');
    }
  }

  Future<void> atualizar({
    required int lojaId,
    required int organizacaoId,
    required int cidadeId,
    required String nome,
    String? bairro,
    String? telefone,
    String? horario,
    int? diasValidade,
    File? imagem,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/lojas/$lojaId');

    final request = http.MultipartRequest('PUT', uri);

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['organizacao_id'] = organizacaoId.toString();
    request.fields['cidade_id'] = cidadeId.toString();
    request.fields['nmloja'] = nome;
    request.fields['dsbairroloja'] = bairro ?? '';
    request.fields['nrtelloja'] = telefone ?? '';
    request.fields['dshorarioloja'] = horario ?? '';

    if (diasValidade != null) {
      request.fields['nrdiavalidade'] = diasValidade.toString();
    }

    if (imagem != null) {
      request.files.add(await _montarArquivoImagem('file', imagem));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar loja: $responseBody');
    }
  }

  Future<void> excluir(int lojaId) async {
    final response = await ApiService.delete('/lojas/$lojaId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir loja: ${response.body}');
    }
  }
}