import 'package:flutter/material.dart';

import '../../core/repositories/organizacao_repository.dart';
import '../../core/services/storage_service.dart';
import '../../models/organizacao.dart';

class OrganizacaoFormPage extends StatefulWidget {
  final Organizacao? organizacao;

  const OrganizacaoFormPage({
    super.key,
    this.organizacao,
  });

  @override
  State<OrganizacaoFormPage> createState() => _OrganizacaoFormPageState();
}

class _OrganizacaoFormPageState extends State<OrganizacaoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = OrganizacaoRepository();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  bool _salvando = false;
  String _status = 'ATIVA';

  bool get editando => widget.organizacao != null;

  @override
  void initState() {
    super.initState();

    if (widget.organizacao != null) {
      _nomeController.text = widget.organizacao!.nmorganizacao;
      _cnpjController.text = widget.organizacao!.cnpjorganizacao ?? '';
      _emailController.text = widget.organizacao!.emailorganizacao ?? '';
      _telefoneController.text = widget.organizacao!.telorganizacao ?? '';
      _status = widget.organizacao!.sitorganizacao ?? 'ATIVA';
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
        final usuarioId = await StorageService.getUsuarioId();

        if (usuarioId == null) {
          throw Exception('Usuário não encontrado');
        }

        await _repository.atualizar(
          usuarioId,
          {
            'nmorganizacao': _nomeController.text.trim(),
            'cnpjorganizacao': _cnpjController.text.trim(),
            'emailorganizacao': _emailController.text.trim(),
            'telorganizacao': _telefoneController.text.trim(),
            'sitorganizacao': _status,
          },
        );
      } else {
        await _repository.criar(
          {
            'nmorganizacao': _nomeController.text.trim(),
            'cnpjorganizacao': _cnpjController.text.trim(),
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Organização atualizada com sucesso'
                : 'Organização criada com sucesso',
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
        title: Text(editando ? 'Editar Organização' : 'Nova Organização'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
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
                      labelText: 'Nome da organização',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da organização';
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
                  if (editando) ...[
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
                  ],
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