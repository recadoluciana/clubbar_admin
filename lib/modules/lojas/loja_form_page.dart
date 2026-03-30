import 'package:flutter/material.dart';

import '../../core/repositories/loja_repository.dart';
import '../../models/loja.dart';

class LojaFormPage extends StatefulWidget {
  final int organizacaoId;
  final Loja? loja;

  const LojaFormPage({
    super.key,
    required this.organizacaoId,
    this.loja,
  });

  @override
  State<LojaFormPage> createState() => _LojaFormPageState();
}

class _LojaFormPageState extends State<LojaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = LojaRepository();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  bool _salvando = false;
  String _status = 'ATIVA';

  bool get editando => widget.loja != null;

  @override
  void initState() {
    super.initState();

    if (widget.loja != null) {
      _nomeController.text = widget.loja!.nmloja;
      _cnpjController.text = widget.loja!.cnpjloja ?? '';
      _emailController.text = widget.loja!.emailloja ?? '';
      _telefoneController.text = widget.loja!.telloja ?? '';
      _status = widget.loja!.sitloja ?? 'ATIVA';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      if (editando) {
        await _repository.atualizar(
          lojaId: widget.loja!.lojaId,
          nome: _nomeController.text.trim(),
          status: _status,
          cnpj: _cnpjController.text.trim(),
          email: _emailController.text.trim(),
          telefone: _telefoneController.text.trim(),
        );
      } else {
        await _repository.criar(
          organizacaoId: widget.organizacaoId,
          nome: _nomeController.text.trim(),
          status: _status,
          cnpj: _cnpjController.text.trim(),
          email: _emailController.text.trim(),
          telefone: _telefoneController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Loja atualizada com sucesso.'
                : 'Loja criada com sucesso.',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Loja' : 'Nova Loja'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da loja',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da loja';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cnpjController,
                    decoration: const InputDecoration(
                      labelText: 'CNPJ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ATIVA',
                        child: Text('ATIVA'),
                      ),
                      DropdownMenuItem(
                        value: 'INATIVA',
                        child: Text('INATIVA'),
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
                          ? const CircularProgressIndicator()
                          : Text(editando ? 'Salvar Alterações' : 'Salvar'),
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