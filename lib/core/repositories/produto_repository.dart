import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../core/config/api_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProdutoRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> listar(int lojaId) async {
    final response = await ApiService.get('/lojas/$lojaId/produtos');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Erro ao listar produtos: ${response.body}');
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
    required int lojaId,
    required int categoriaId,
    required String nome,
    String descricao = '',
    required double preco,
    File? imagem,
  }) async {
    final uri = Uri.parse('$baseUrl/produtos');

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
    request.fields['sitproduto'] = 'ATIVO';
    request.fields['skuproduto'] = '';
    request.fields['idtipoproduto'] = 'P';

    if (imagem != null) {
      request.files.add(await _montarArquivoImagem('foto', imagem));
    }

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Erro ao criar produto: $respStr');
    }
  }

  Future<void> atualizar({
    required int produtoId,
    required int categoriaId,
    required String nome,
    required String descricao,
    required double preco,
    required String sitproduto,
    required String skuproduto,
    File? imagem,
  }) async {
    final uri = Uri.parse('$baseUrl/produtos/$produtoId');

    final request = http.MultipartRequest('PUT', uri);

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['categoria_id'] = categoriaId.toString();
    request.fields['nmproduto'] = nome;
    request.fields['dsproduto'] = descricao;
    request.fields['vrprecoprod'] = preco.toString();
    request.fields['sitproduto'] = sitproduto;
    request.fields['skuproduto'] = skuproduto;

    if (imagem != null) {
      request.files.add(await _montarArquivoImagem('file', imagem));
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
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