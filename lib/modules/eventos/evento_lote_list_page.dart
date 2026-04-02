import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/evento_lote_repository.dart';
import '../../models/evento_lote.dart';
import '../../core/services/storage_service.dart';
import 'evento_lote_form_page.dart';

class EventoLoteListPage extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const EventoLoteListPage({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
  });

  @override
  State<EventoLoteListPage> createState() => _EventoLoteListPageState();
}

class _EventoLoteListPageState extends State<EventoLoteListPage> {
  final _repo = EventoLoteRepository();
  final _buscaController = TextEditingController();

  final NumberFormat _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  List<EventoLote> _lotes = [];
  List<EventoLote> _lotesFiltrados = [];
  bool _loading = true;
  int? _organizacaoId;
  int? _lojaId;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    _organizacaoId = await StorageService.getOrganizacaoId();
    _lojaId = await StorageService.getLojaId();
    await _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);

    try {
      final lista = await _repo.listar(widget.eventoId);

      if (!mounted) return;

      setState(() {
        _lotes = lista;
        _lotesFiltrados = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filtrar(String texto) {
    final busca = texto.trim().toLowerCase();

    setState(() {
      if (busca.isEmpty) {
        _lotesFiltrados = _lotes;
      } else {
        _lotesFiltrados = _lotes.where((lote) {
          return lote.loteId.toString().contains(busca) ||
              lote.nmlote.toLowerCase().contains(busca) ||
              lote.vrprecolote.toString().contains(busca) ||
              lote.qttotallote.toString().contains(busca) ||
              lote.qtvendidalote.toString().contains(busca) ||
              (lote.statuslote ?? '').toLowerCase().contains(busca);
        }).toList();
      }
    });
  }

  String _formatarData(String? valor) {
    if (valor == null || valor.trim().isEmpty) return '-';

    try {
      final data = DateTime.parse(valor);
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (_) {
      return valor;
    }
  }

  Future<void> _novoLote() async {
    if (_organizacaoId == null || _lojaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organização ou loja não encontrada no login'),
        ),
      );
      return;
    }

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventoLoteFormPage(
          eventoId: widget.eventoId,
          organizacaoId: _organizacaoId!,
          lojaId: _lojaId!,
        ),
      ),
    );

    if (ok == true) {
      _carregar();
    }
  }

  Future<void> _editarLote(EventoLote lote) async {
    if (_organizacaoId == null || _lojaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organização ou loja não encontrada no login'),
        ),
      );
      return;
    }

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventoLoteFormPage(
          eventoId: widget.eventoId,
          organizacaoId: _organizacaoId!,
          lojaId: _lojaId!,
          lote: lote,
        ),
      ),
    );

    if (ok == true) {
      _carregar();
    }
  }

  Future<void> _excluir(int loteId) async {
    try {
      await _repo.excluir(loteId);
      _carregar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _confirmarExclusao(EventoLote lote) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lote'),
        content: Text('Deseja excluir o lote "${lote.nmlote}"?'),
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

    if (confirmar == true) {
      _excluir(lote.loteId);
    }
  }

  Widget _buildTabela() {
    if (_lotesFiltrados.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhum lote encontrado.'),
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
            DataColumn(label: Text('Preço')),
            DataColumn(label: Text('Qt Total')),
            DataColumn(label: Text('Qt Vendida')),
            DataColumn(label: Text('Início Venda')),
            DataColumn(label: Text('Fim Venda')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _lotesFiltrados.map((lote) {
            return DataRow(
              cells: [
                DataCell(Text(lote.loteId.toString())),
                DataCell(Text(lote.nmlote)),
                DataCell(Text(_moeda.format(lote.vrprecolote))),
                DataCell(Text(lote.qttotallote.toString())),
                DataCell(Text(lote.qtvendidalote.toString())),
                DataCell(Text(_formatarData(lote.dtiniciovenda))),
                DataCell(Text(_formatarData(lote.dtfimvenda))),
                DataCell(Text(lote.statuslote ?? '-')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _editarLote(lote),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(lote),
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
        title: Text('Lotes - ${widget.eventoTitulo}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _buscaController,
                          onChanged: _filtrar,
                          decoration: const InputDecoration(
                            labelText: 'Buscar lote',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _novoLote,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo Lote'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Atualizar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: _buildTabela()),
                ],
              ),
      ),
    );
  }
}