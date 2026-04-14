import 'package:flutter/material.dart';

import '../../core/repositories/evento_lote_repository.dart';
import '../../models/evento_lote.dart';

class EventoLoteFormPage extends StatefulWidget {
  final int eventoId;
  final int organizacaoId;
  final int lojaId;
  final EventoLote? lote;

  const EventoLoteFormPage({
    super.key,
    required this.eventoId,
    required this.organizacaoId,
    required this.lojaId,
    this.lote,
  });

  @override
  State<EventoLoteFormPage> createState() => _EventoLoteFormPageState();
}

class _EventoLoteFormPageState extends State<EventoLoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EventoLoteRepository();

  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _qtTotalController = TextEditingController();
  final _qtVendidaController = TextEditingController();
  final _dtInicioController = TextEditingController();
  final _dtFimController = TextEditingController();

  bool _salvando = false;
  String _status = 'ATIVO';

  bool get editando => widget.lote != null;

  @override
  void initState() {
    super.initState();

    if (widget.lote != null) {
      _nomeController.text = widget.lote!.nmlote;
      _precoController.text = widget.lote!.vrprecolote.toString();
      _qtTotalController.text = widget.lote!.qttotallote.toString();
      _qtVendidaController.text = widget.lote!.qtvendidalote.toString();
      _dtInicioController.text = widget.lote!.dtiniciovenda ?? '';
      _dtFimController.text = widget.lote!.dtfimvenda ?? '';
      _status = widget.lote!.statuslote ?? 'ATIVO';
    } else {
      _qtVendidaController.text = '0';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _qtTotalController.dispose();
    _qtVendidaController.dispose();
    _dtInicioController.dispose();
    _dtFimController.dispose();
    super.dispose();
  }

  String _formatIso(DateTime data, TimeOfDay hora) {
    final dt = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    String two(int n) => n.toString().padLeft(2, '0');

    return '${dt.year}-${two(dt.month)}-${two(dt.day)}'
        'T${two(dt.hour)}:${two(dt.minute)}:00';
  }

  Future<void> _selecionarDataHora(TextEditingController controller) async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(agora),
    );

    if (hora == null) return;

    controller.text = _formatIso(data, hora);
    setState(() {});
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      final preco = double.tryParse(
        _precoController.text.trim().replaceAll(',', '.'),
      );
      final qtTotal = int.tryParse(_qtTotalController.text.trim());
      final qtVendida = int.tryParse(_qtVendidaController.text.trim());

      if (preco == null) {
        throw Exception('Preço inválido');
      }
      if (qtTotal == null) {
        throw Exception('Quantidade total inválida');
      }
      if (qtVendida == null) {
        throw Exception('Quantidade vendida inválida');
      }

      if (editando) {
        await _repo.atualizar(
          loteId: widget.lote!.loteId,
          organizacaoId: widget.organizacaoId,
          lojaId: widget.lojaId,
          eventoId: widget.eventoId,
          nome: _nomeController.text.trim(),
          preco: preco,
          quantidadeTotal: qtTotal,
          quantidadeVendida: qtVendida,
          dtInicioVenda: _dtInicioController.text.trim().isEmpty
              ? null
              : _dtInicioController.text.trim(),
          dtFimVenda: _dtFimController.text.trim().isEmpty
              ? null
              : _dtFimController.text.trim(),
          status: _status,
        );
      } else {
        await _repo.criar(
          eventoId: widget.eventoId,
          organizacaoId: widget.organizacaoId,
          lojaId: widget.lojaId,
          nome: _nomeController.text.trim(),
          preco: preco,
          quantidadeTotal: qtTotal,
          quantidadeVendida: qtVendida,
          dtInicioVenda: _dtInicioController.text.trim().isEmpty
              ? null
              : _dtInicioController.text.trim(),
          dtFimVenda: _dtFimController.text.trim().isEmpty
              ? null
              : _dtFimController.text.trim(),
          status: _status,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar lote: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  Widget _buildCampoDataHora({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: '2026-04-01T18:00:00',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _selecionarDataHora(controller),
        ),
      ),
      onTap: () => _selecionarDataHora(controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Lote' : 'Novo Lote'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do lote',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do lote';
                      }
                      return null;
                    },
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
                  TextFormField(
                    controller: _qtTotalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade total',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a quantidade total';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qtVendidaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade vendida',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a quantidade vendida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCampoDataHora(
                    controller: _dtInicioController,
                    label: 'Data início venda',
                  ),
                  const SizedBox(height: 16),
                  _buildCampoDataHora(
                    controller: _dtFimController,
                    label: 'Data fim venda',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
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
                          _status = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
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