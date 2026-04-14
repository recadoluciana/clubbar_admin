import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../core/config/api_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProdutoRepository {
  Future<List<dynamic>> listar(int lojaId) async {
    final response = await ApiService.get('/lojas/$lojaId/produtos');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Erro ao listar produtos: ${response.body}');
  }

  Future<http.MultipartFile> _montarArquivoImagem(
    String fieldName,
    XFile imagem,
  ) async {
    final mimeType =
        lookupMimeType(imagem.name) ??
        lookupMimeType(imagem.path) ??
        'image/jpeg';

    final parts = mimeType.split('/');

    if (kIsWeb) {
      final bytes = await imagem.readAsBytes();

      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: imagem.name,
        contentType: MediaType(parts[0], parts[1]),
      );
    } else {
      return await http.MultipartFile.fromPath(
        fieldName,
        imagem.path,
        contentType: MediaType(parts[0], parts[1]),
      );
    }
  }

  Future<void> criar({
    required int organizacaoId,
    required int lojaId,
    required int categoriaId,
    required String nome,
    String descricao = '',
    required double preco,
    String sitproduto = 'ATIVO',
    XFile? imagem,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/produtos');

    final request = http.MultipartRequest('POST', uri);

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['organizacao_id'] = organizacaoId.toString();
    request.fields['loja_id'] = lojaId.toString();
    request.fields['categoria_id'] = categoriaId.toString();
    request.fields['nmproduto'] = nome;
    request.fields['dsproduto'] = descricao;
    request.fields['vrprecoprod'] = preco.toString();
    request.fields['sitproduto'] = sitproduto;
    request.fields['idtipoproduto'] = 'P';

    if (imagem != null) {
      request.files.add(await _montarArquivoImagem('urlfotoproduto', imagem));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar produto: $respStr');
    }
  }

  Future<void> atualizar({
    required int produtoId,
    int? categoriaId,
    String? nome,
    String? descricao,
    double? preco,
    String? status,
    XFile? imagem,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/produtos/$produtoId');

    final request = http.MultipartRequest('PUT', uri);

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (categoriaId != null) {
      request.fields['categoria_id'] = categoriaId.toString();
    }
    if (nome != null) {
      request.fields['nmproduto'] = nome;
    }
    if (descricao != null) {
      request.fields['dsproduto'] = descricao;
    }
    if (preco != null) {
      request.fields['vrprecoprod'] = preco.toString();
    }
    if (status != null) {
      request.fields['sitproduto'] = status;
    }

    if (imagem != null) {
      request.files.add(await _montarArquivoImagem('urlfotoproduto', imagem));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar produto: $respStr');
    }
  }

  Future<void> excluir(int produtoId) async {
    final response = await ApiService.delete('/produto/$produtoId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir produto: ${response.body}');
    }
  }
}
