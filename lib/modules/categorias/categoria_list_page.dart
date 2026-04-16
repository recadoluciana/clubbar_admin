import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/repositories/categoria_repository.dart';
import '../../core/repositories/loja_repository.dart';
import '../../models/categoria.dart';
import '../../models/loja.dart';
import 'categoria_form_page.dart';

class CategoriaListPage extends StatefulWidget {
  final int organizacaoId;

  const CategoriaListPage({super.key, required this.organizacaoId});

  @override
  State<CategoriaListPage> createState() => _CategoriaListPageState();
}

class _CategoriaListPageState extends State<CategoriaListPage> {
  final CategoriaRepository _repository = CategoriaRepository();
  final LojaRepository _lojaRepository = LojaRepository();
  final TextEditingController _buscaController = TextEditingController();

  bool _carregando = true;
  bool _carregandoLojas = true;

  List<Categoria> _categorias = [];
  List<Categoria> _categoriasFiltradas = [];

  List<Loja> _lojas = [];
  int? _lojaIdSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarLojas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
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

  Future<void> _carregarLojas() async {
    setState(() {
      _carregandoLojas = true;
      _carregando = true;
    });

    try {
      final lojas = await _lojaRepository.listar(widget.organizacaoId);

      if (!mounted) return;

      int? lojaSelecionada = _lojaIdSelecionada;

      if (lojas.isNotEmpty) {
        final existe = lojas.any((l) => l.lojaId == lojaSelecionada);
        if (!existe) {
          lojaSelecionada = lojas.first.lojaId;
        }
      } else {
        lojaSelecionada = null;
      }

      setState(() {
        _lojas = lojas;
        _lojaIdSelecionada = lojaSelecionada;
        _carregandoLojas = false;
      });

      if (_lojaIdSelecionada != null) {
        await _carregarCategorias();
      } else {
        setState(() {
          _categorias = [];
          _categoriasFiltradas = [];
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoLojas = false;
        _carregando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_extrairMensagemErro(e))));
    }
  }

  Future<void> _carregarCategorias() async {
    if (_lojaIdSelecionada == null) {
      setState(() {
        _categorias = [];
        _categoriasFiltradas = [];
        _carregando = false;
      });
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final lista = await _repository.listar(_lojaIdSelecionada!);

      if (!mounted) return;

      setState(() {
        _categorias = lista;
        _categoriasFiltradas = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_extrairMensagemErro(e))));
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _filtrar(String texto) {
    final busca = texto.trim().toLowerCase();

    setState(() {
      if (busca.isEmpty) {
        _categoriasFiltradas = _categorias;
      } else {
        _categoriasFiltradas = _categorias.where((categoria) {
          final id = categoria.categoriaId.toString();
          final nome = categoria.nmcategoria.toLowerCase();
          final status = (categoria.sitcategoria ?? '').toLowerCase();
          final ordem = (categoria.idordcategoria ?? 0).toString();

          return id.contains(busca) ||
              nome.contains(busca) ||
              status.contains(busca) ||
              ordem.contains(busca);
        }).toList();
      }
    });
  }

  Future<void> _abrirNovaCategoria() async {
    if (_lojaIdSelecionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma loja')));
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoriaFormPage(lojaId: _lojaIdSelecionada!),
      ),
    );

    if (result == true) {
      _carregarCategorias();
    }
  }

  Future<void> _abrirEdicao(Categoria categoria) async {
    if (_lojaIdSelecionada == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoriaFormPage(
          lojaId: _lojaIdSelecionada!,
          categoria: categoria,
        ),
      ),
    );

    if (result == true) {
      _carregarCategorias();
    }
  }

  Future<void> _confirmarExclusao(Categoria categoria) async {
    if (_lojaIdSelecionada == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          'Deseja realmente excluir a categoria "${categoria.nmcategoria}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repository.excluir(_lojaIdSelecionada!, categoria.categoriaId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída com sucesso.')),
      );

      _carregarCategorias();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_extrairMensagemErro(e))));
    }
  }

  Widget _buildTabela() {
    if (_categoriasFiltradas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhuma categoria encontrada.')),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('Ordem no cardápio')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _categoriasFiltradas.map((categoria) {
            return DataRow(
              cells: [
                DataCell(Text(categoria.categoriaId.toString())),
                DataCell(Text(categoria.nmcategoria)),
                DataCell(Text((categoria.idordcategoria ?? 0).toString())),
                DataCell(Text(categoria.sitcategoria ?? '-')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _abrirEdicao(categoria),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(categoria),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _buscaController,
                    onChanged: _filtrar,
                    decoration: const InputDecoration(
                      labelText: 'Buscar categoria',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _carregandoLojas
                      ? const SizedBox(
                          height: 50,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<int>(
                          initialValue: _lojaIdSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Loja',
                            border: OutlineInputBorder(),
                          ),
                          items: _lojas.map((loja) {
                            return DropdownMenuItem<int>(
                              value: loja.lojaId,
                              child: Text(loja.nmloja),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _lojaIdSelecionada = value;
                            });
                            _carregarCategorias();
                          },
                        ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _abrirNovaCategoria,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _carregarCategorias,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabela(),
            ),
          ],
        ),
      ),
    );
  }
}
