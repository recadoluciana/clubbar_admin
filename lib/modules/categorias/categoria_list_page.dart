import 'package:flutter/material.dart';
import '../../core/repositories/categoria_repository.dart';
import '../../models/categoria.dart';
import 'categoria_form_page.dart';

class CategoriaListPage extends StatefulWidget {
  final int lojaId;

  const CategoriaListPage({
    super.key,
    required this.lojaId,
  });

  @override
  State<CategoriaListPage> createState() => _CategoriaListPageState();
}

class _CategoriaListPageState extends State<CategoriaListPage> {
  final CategoriaRepository _repository = CategoriaRepository();
  final TextEditingController _buscaController = TextEditingController();

  bool _carregando = true;
  List<Categoria> _categorias = [];
  List<Categoria> _categoriasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _carregando = true;
    });

    try {
      final lista = await _repository.listar(widget.lojaId);

      if (!mounted) return;

      setState(() {
        _categorias = lista;
        _categoriasFiltradas = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar categorias: $e')),
      );
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
          return categoria.nmcategoria.toLowerCase().contains(busca) ||
              categoria.categoriaId.toString().contains(busca);
        }).toList();
      }
    });
  }

  Future<void> _abrirNovaCategoria() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoriaFormPage(lojaId: widget.lojaId),
      ),
    );

    if (resultado == true) {
      await _carregarCategorias();
    }
  }

  Future<void> _abrirEdicao(Categoria categoria) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoriaFormPage(
          categoria: categoria,
          lojaId: widget.lojaId,
        ),
      ),
    );

    if (resultado == true) {
      await _carregarCategorias();
    }
  }

  Future<void> _confirmarExclusao(Categoria categoria) async {
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
      await _repository.excluir(
        widget.lojaId,
        categoria.categoriaId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída com sucesso.')),
      );

      await _carregarCategorias();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  Widget _buildTabela() {
    if (_categoriasFiltradas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhuma categoria encontrada.'),
          ),
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
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _categoriasFiltradas.map((categoria) {
            return DataRow(
              cells: [
                DataCell(Text(categoria.categoriaId.toString())),
                DataCell(Text(categoria.nmcategoria)),
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
      appBar: AppBar(
        title: const Text('Categorias'),
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
                      labelText: 'Buscar categoria',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
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