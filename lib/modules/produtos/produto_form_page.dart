import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/repositories/categoria_repository.dart';
import '../../core/repositories/produto_repository.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _produtoRepository = ProdutoRepository();
  final _categoriaRepository = CategoriaRepository();
  final _picker = ImagePicker();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  
  bool _salvando = false;
  bool _carregandoCategorias = true;

  List<Categoria> _categorias = [];
  int? _categoriaIdSelecionada;
  String _statusSelecionado = 'ATIVO';

  XFile? _imagemSelecionada;
  Uint8List? _imagemBytes;

  bool get editando => widget.produto != null;

  @override
  void initState() {
    super.initState();

    if (widget.produto != null) {
      _nomeController.text = (widget.produto!['nmproduto'] ?? '').toString();
      _descricaoController.text =
          (widget.produto!['dsproduto'] ?? '').toString();
      _precoController.text =
          (widget.produto!['vrprecoprod'] ?? '').toString();
      _skuController.text = (widget.produto!['skuproduto'] ?? '').toString();
      _categoriaIdSelecionada = widget.produto!['categoria_id'];
      _statusSelecionado =
          (widget.produto!['sitproduto'] ?? 'ATIVO').toString();
    }

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

  Future<void> _carregarCategorias() async {
    setState(() {
      _carregandoCategorias = true;
    });

    try {
      final lista = await _categoriaRepository.listar(widget.lojaId);

      if (!mounted) return;

      int? categoriaSelecionada = _categoriaIdSelecionada;

      if (lista.isNotEmpty) {
        final existe = lista.any(
          (categoria) => categoria.categoriaId == categoriaSelecionada,
        );

        if (!existe) {
          categoriaSelecionada = lista.first.categoriaId;
        }
      } else {
        categoriaSelecionada = null;
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
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = await arquivo.readAsBytes();
        }

        setState(() {
          _imagemSelecionada = arquivo;
          _imagemBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  String _montarUrlImagemAtual() {
    final imagemAtual = (widget.produto?['urlfotoproduto'] ?? '').toString().trim();

    if (imagemAtual.isEmpty) return '';

    if (imagemAtual.startsWith('http')) {
      return imagemAtual;
    }

    final path = imagemAtual.startsWith('/') ? imagemAtual : '/$imagemAtual';
    return '${ApiConfig.baseUrl}$path';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaIdSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final precoTexto = _precoController.text
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll(',', '.')
          .trim();

      final preco = double.tryParse(precoTexto);

      if (preco == null) {
        throw Exception('Preço inválido');
      }

      if (editando) {
        await _produtoRepository.atualizar(
          produtoId: widget.produto!['produto_id'],
          categoriaId: _categoriaIdSelecionada,
          nome: _nomeController.text.trim(),
          descricao: _descricaoController.text.trim(),
          preco: preco,
          status: _statusSelecionado,
          sku: _skuController.text.trim(),
          imagem: _imagemSelecionada,
        );
      } else {
        await _produtoRepository.criar(
          organizacaoId: widget.organizacaoId,
          lojaId: widget.lojaId,
          categoriaId: _categoriaIdSelecionada!,
          nome: _nomeController.text.trim(),
          descricao: _descricaoController.text.trim(),
          preco: preco,
          sku: _skuController.text.trim(),
          sitproduto: _statusSelecionado,
          imagem: _imagemSelecionada,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Produto atualizado com sucesso'
                : 'Produto criado com sucesso',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagemAtualUrl = _montarUrlImagemAtual();

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Produto' : 'Novo Produto'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  GestureDetector(
                    onTap: _selecionarImagem,
                    child: Container(
                      height: 160,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imagemSelecionada != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(
                                      _imagemBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.network(
                                      _imagemSelecionada!.path,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                            )
                          : (editando && imagemAtualUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imagemAtualUrl,
                                    key: ValueKey(imagemAtualUrl),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, error, __) {
                                      print('ERRO IMG PRODUTO: $imagemAtualUrl');
                                      print('DETALHE: $error');
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 40),
                                      SizedBox(height: 8),
                                      Text('Toque para selecionar uma imagem'),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do produto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descrição do produto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _precoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preço',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o preço';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _statusSelecionado,
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
                          _statusSelecionado = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _carregandoCategorias
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                          value: _categoriaIdSelecionada,
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
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione uma categoria';
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}