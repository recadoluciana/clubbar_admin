import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/repositories/produto_repository.dart';
import 'produto_form_page.dart';

class ProdutoListPage extends StatefulWidget {
  final int lojaId;
  final int organizacaoId;

  const ProdutoListPage({
    super.key,
    required this.lojaId,
    required this.organizacaoId,
  });

  @override
  State<ProdutoListPage> createState() => _ProdutoListPageState();
}

class _ProdutoListPageState extends State<ProdutoListPage> {
  final ProdutoRepository _repository = ProdutoRepository();
  final TextEditingController _buscaController = TextEditingController();

  bool _carregando = true;
  List<dynamic> _produtos = [];
  List<dynamic> _produtosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
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

  Future<void> _carregarProdutos() async {
    setState(() => _carregando = true);

    try {
      final lista = await _repository.listar(widget.lojaId);

      if (!mounted) return;

      setState(() {
        _produtos = lista;
        _produtosFiltrados = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _filtrar(String texto) {
    final busca = texto.trim().toLowerCase();

    setState(() {
      if (busca.isEmpty) {
        _produtosFiltrados = _produtos;
      } else {
        _produtosFiltrados = _produtos.where((produto) {
          final nome = (produto['nmproduto'] ?? '').toString().toLowerCase();
          final categoria =
              (produto['nmcategoria'] ?? '').toString().toLowerCase();
          final id = (produto['produto_id'] ?? '').toString();

          return nome.contains(busca) ||
              categoria.contains(busca) ||
              id.contains(busca);
        }).toList();
      }
    });
  }

  Future<void> _abrirCadastro() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProdutoFormPage(
          lojaId: widget.lojaId,
          organizacaoId: widget.organizacaoId,
        ),
      ),
    );

    if (result == true) {
      _carregarProdutos();
    }
  }

  Future<void> _abrirEdicao(dynamic produto) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProdutoFormPage(
          lojaId: widget.lojaId,
          organizacaoId: widget.organizacaoId,
          produto: Map<String, dynamic>.from(produto),
        ),
      ),
    );

    if (result == true) {
      _carregarProdutos();
    }
  }

  Future<void> _confirmarExclusao(dynamic produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja excluir "${produto['nmproduto']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repository.excluir(produto['produto_id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto excluído com sucesso')),
      );

      _carregarProdutos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    }
  }

  Widget _buildTabela() {
    if (_produtosFiltrados.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhum produto encontrado.'),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Foto')),
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Preço')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _produtosFiltrados.map((produto) {
              final urlFoto = produto['urlfotoproduto']?.toString() ?? '';
              final urlCompleta = urlFoto.startsWith('http')
                  ? urlFoto
                  : '${ApiConfig.baseUrl}$urlFoto';

              return DataRow(
                cells: [
                  DataCell(
                    urlFoto.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              urlCompleta,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                  DataCell(Text((produto['produto_id'] ?? '').toString())),
                  DataCell(Text((produto['nmproduto'] ?? '').toString())),
                  DataCell(Text((produto['nmcategoria'] ?? '-').toString())),
                  DataCell(Text('R\$ ${produto['vrprecoprod'] ?? ''}')),
                  DataCell(Text((produto['sitproduto'] ?? '-').toString())),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _abrirEdicao(produto),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () => _confirmarExclusao(produto),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscaController,
                    onChanged: _filtrar,
                    decoration: const InputDecoration(
                      labelText: 'Buscar produto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _abrirCadastro,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _carregarProdutos,
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