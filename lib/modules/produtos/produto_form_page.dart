import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/repositories/categoria_repository.dart';
import '../../core/repositories/produto_repository.dart';
import '../../core/services/storage_service.dart';
import '../../models/categoria.dart';

class ProdutoFormPage extends StatefulWidget {
  final int lojaId;
  final int organizacaoId;
  final Map<String, dynamic>? produto;

  const ProdutoFormPage({
    super.key,
    required this.lojaId,
    required this.organizacaoId,
    this.produto,
  });

  @override
  State<ProdutoFormPage> createState() => _ProdutoFormPageState();
}

class _ProdutoFormPageState extends State<ProdutoFormPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  File? _imagemSelecionada;

  bool _carregando = false;
  bool _carregandoCategorias = true;

  int? _categoriaIdSelecionada;
  List<Categoria> _categorias = [];
  String _sitproduto = 'ATIVO';

  bool get editando => widget.produto != null;

  @override
  void initState() {
    super.initState();
    _preencherCamposSeEdicao();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  void _preencherCamposSeEdicao() {
    final produto = widget.produto;
    if (produto == null) return;

    _nomeController.text = (produto['nmproduto'] ?? '').toString();
    _descricaoController.text = (produto['dsproduto'] ?? '').toString();
    _precoController.text = (produto['vrprecoprod'] ?? '').toString();
    _skuController.text = (produto['skuproduto'] ?? '').toString();
    _sitproduto = (produto['sitproduto'] ?? 'ATIVO').toString();

    final categoriaId = produto['categoria_id'];
    if (categoriaId is int) {
      _categoriaIdSelecionada = categoriaId;
    } else if (categoriaId != null) {
      _categoriaIdSelecionada = int.tryParse(categoriaId.toString());
    }
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _carregandoCategorias = true;
    });

    try {
      final lista = await _categoriaRepository.listar(widget.lojaId);

      if (!mounted) return;

      int? categoriaSelecionada = _categoriaIdSelecionada;

      final existe = lista.any((c) => c.categoriaId == categoriaSelecionada);

      if (!existe) {
        categoriaSelecionada =
            lista.isNotEmpty ? lista.first.categoriaId : null;
      }

      setState(() {
        _categorias = lista;
        _categoriaIdSelecionada = categoriaSelecionada;
        _carregandoCategorias = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoCategorias = false;
        _categorias = [];
        _categoriaIdSelecionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar categorias: $e')),
      );
    }
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? arquivo = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (arquivo != null) {
        setState(() {
          _imagemSelecionada = File(arquivo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  String _extrairMensagemErro(Object e) {
    final texto = e.toString();

    try {
      final inicio = texto.indexOf('{');
      final fim = texto.lastIndexOf('}');

      if (inicio != -1 && fim != -1) {
        final jsonStr = texto.substring(inicio, fim + 1);
        final jsonMap = jsonDecode(jsonStr);

        if (jsonMap is Map && jsonMap['detail'] != null) {
          return jsonMap['detail'].toString();
        }
      }
    } catch (_) {}

    return texto.replaceAll('Exception:', '').trim();
  }

  Future<void> _salvarProdutoNaApi() async {
    final String nome = _nomeController.text.trim();
    final String descricao = _descricaoController.text.trim();
    final String precoTexto = _precoController.text.trim().replaceAll(',', '.');
    final String sku = _skuController.text.trim();

    if (nome.isEmpty || precoTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e preço.')),
      );
      return;
    }

    if (_categoriaIdSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria.')),
      );
      return;
    }

    final preco = double.tryParse(precoTexto);
    if (preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um preço válido.')),
      );
      return;
    }

    if (!editando && _imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem.')),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      if (editando) {
        await _produtoRepository.atualizar(
          produtoId: widget.produto!['produto_id'],
          categoriaId: _categoriaIdSelecionada!,
          nome: nome,
          descricao: descricao,
          preco: preco,
          sitproduto: _sitproduto,
          skuproduto: sku,
          imagem: _imagemSelecionada,
        );
      } else {
        final token = await StorageService.getToken();

        final uri = Uri.parse('${ApiConfig.baseUrl}/produtos');
        final request = http.MultipartRequest('POST', uri);

        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['organizacao_id'] = widget.organizacaoId.toString();
        request.fields['loja_id'] = widget.lojaId.toString();
        request.fields['categoria_id'] = _categoriaIdSelecionada.toString();
        request.fields['nmproduto'] = nome;
        request.fields['dsproduto'] = descricao;
        request.fields['vrprecoprod'] = preco.toString();
        request.fields['idtipoproduto'] = 'P';
        request.fields['sitproduto'] = 'ATIVO';
        request.fields['skuproduto'] = sku;

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _imagemSelecionada!.path,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode != 200 && response.statusCode != 201) {
          String mensagemErro = response.body;

          try {
            final jsonBody = jsonDecode(response.body);
            if (jsonBody is Map && jsonBody['detail'] != null) {
              mensagemErro = jsonBody['detail'].toString();
            }
          } catch (_) {}

          throw Exception('${response.statusCode} - $mensagemErro');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Produto atualizado com sucesso!'
                : 'Produto salvo com sucesso!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagemAtual = widget.produto?['urlfotoproduto']?.toString() ?? '';
    final imagemAtualCompleta = imagemAtual.startsWith('http')
        ? imagemAtual
        : '${ApiConfig.baseUrl}$imagemAtual';

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Produto' : 'Cadastrar Produto'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          GestureDetector(
            onTap: _selecionarImagem,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imagemSelecionada != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imagemSelecionada!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : (editando && imagemAtual.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imagemAtualCompleta,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.image_outlined, size: 50),
                              SizedBox(height: 8),
                              Text('Toque para selecionar uma imagem'),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome do produto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descricaoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descrição do produto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _precoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preço',
              border: OutlineInputBorder(),
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _skuController,
            decoration: const InputDecoration(
              labelText: 'SKU',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _sitproduto,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'ATIVO',
                child: Text('ATIVO'),
              ),
              DropdownMenuItem(
                value: 'INATIVO',
                child: Text('INATIVO'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sitproduto = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _carregandoCategorias
              ? const Center(child: CircularProgressIndicator())
              : _categorias.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nenhuma categoria encontrada para esta loja.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _carregarCategorias,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recarregar categorias'),
                        ),
                      ],
                    )
                  : DropdownButtonFormField<int>(
                      value: _categorias.any(
                              (c) => c.categoriaId == _categoriaIdSelecionada)
                          ? _categoriaIdSelecionada
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem<int>(
                          value: categoria.categoriaId,
                          child: Text(categoria.nmcategoria),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaIdSelecionada = value;
                        });
                      },
                    ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _carregando ? null : _salvarProdutoNaApi,
              child: _carregando
                  ? const CircularProgressIndicator()
                  : Text(editando ? 'Salvar Alterações' : 'Salvar Produto'),
            ),
          ),
        ],
      ),
    );
  }
}