import 'package:flutter/material.dart';

import '../../core/repositories/evento_lote_repository.dart';
import '../../models/evento_lote.dart';

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

  List<EventoLote> _lotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);

    try {
      final lista = await _repo.listar(widget.eventoId);

      if (!mounted) return;

      setState(() {
        _lotes = lista;
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

  Future<void> _novoLote() async {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();
    final qtdController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo Lote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: precoController,
              decoration: const InputDecoration(labelText: 'Preço'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: qtdController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _repo.criar(
        eventoId: widget.eventoId,
        organizacaoId: 1,
        lojaId: 1,
        nome: nomeController.text.trim(),
        preco: double.tryParse(precoController.text.trim()) ?? 0,
        quantidade: int.tryParse(qtdController.text.trim()) ?? 0,
      );

      _carregar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
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
                      ElevatedButton.icon(
                        onPressed: _novoLote,
                        icon: const Icon(Icons.add),
                        label: const Text('Novo Lote'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _carregar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Atualizar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        itemCount: _lotes.length,
                        itemBuilder: (_, i) {
                          final l = _lotes[i];

                          return ListTile(
                            title: Text(l.nmlote),
                            subtitle: Text(
                              'R\$ ${l.vrprecolote} | Total: ${l.qttotallote} | Vendidos: ${l.qtvendidalote}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _excluir(l.loteId),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}