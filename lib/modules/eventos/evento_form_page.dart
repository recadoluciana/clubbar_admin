import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/repositories/evento_repository.dart';
import '../../models/evento.dart';

class EventoFormPage extends StatefulWidget {
  final int organizacaoId;
  final int lojaId;
  final Evento? evento;

  const EventoFormPage({
    super.key,
    required this.organizacaoId,
    required this.lojaId,
    this.evento,
  });

  @override
  State<EventoFormPage> createState() => _EventoFormPageState();
}

class _EventoFormPageState extends State<EventoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EventoRepository();
  final _picker = ImagePicker();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();
  final _localController = TextEditingController();
  final _enderecoController = TextEditingController();

  XFile? _imagemSelecionada;
  Uint8List? _imagemBytes;
  bool _salvando = false;

  bool get editando => widget.evento != null;

  @override
  void initState() {
    super.initState();

    if (widget.evento != null) {
      _tituloController.text = widget.evento!.nmtituloevento;
      _descricaoController.text = widget.evento!.dsdescevento ?? '';
      _dataInicioController.text = widget.evento!.dtinicioevento ?? '';
      _dataFimController.text = widget.evento!.dtfimevento ?? '';
      _localController.text = widget.evento!.nmlocalevento ?? '';
      _enderecoController.text = widget.evento!.dsendlocevento ?? '';
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _localController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _pickImagem() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = await file.readAsBytes();
        }

        setState(() {
          _imagemSelecionada = file;
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      if (editando) {
        await _repo.atualizar(
          eventoId: widget.evento!.eventoId,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          dataInicio: _dataInicioController.text.trim(),
          dataFim: _dataFimController.text.trim(),
          local: _localController.text.trim(),
          endereco: _enderecoController.text.trim(),
          status: 'ATIVO',
          imagem: _imagemSelecionada,
        );
      } else {
        await _repo.criar(
          organizacaoId: widget.organizacaoId,
          lojaId: widget.lojaId,
          produtoIdIngresso: 1,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          dataInicio: _dataInicioController.text.trim(),
          dataFim: _dataFimController.text.trim(),
          local: _localController.text.trim(),
          endereco: _enderecoController.text.trim(),
          status: 'ATIVO',
          imagem: _imagemSelecionada,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Evento atualizado com sucesso'
                : 'Evento criado com sucesso',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerAtual = widget.evento?.urlbannerevento ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Evento' : 'Novo Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImagem,
                child: Container(
                  height: 160,
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
                              : Image.file(
                                  File(_imagemSelecionada!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        )
                      : (editando && bannerAtual.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                bannerAtual,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported,
                                      size: 50),
                                ),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 40),
                                  SizedBox(height: 8),
                                  Text('Selecionar banner'),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dataInicioController,
                decoration: const InputDecoration(
                  labelText: 'Data início (ISO)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dataFimController,
                decoration: const InputDecoration(
                  labelText: 'Data fim (ISO)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                  labelText: 'Local',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
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
    );
  }
}