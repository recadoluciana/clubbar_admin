import 'package:flutter/material.dart';

import '../../core/repositories/loja_repository.dart';
import '../../core/repositories/usuario_repository.dart';
import '../../models/loja.dart';
import '../../models/usuario.dart';

class UsuarioFormPage extends StatefulWidget {
  final int organizacaoId;
  final Usuario? usuario;

  const UsuarioFormPage({
    super.key,
    required this.organizacaoId,
    this.usuario,
  });

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioRepository = UsuarioRepository();
  final _lojaRepository = LojaRepository();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _salvando = false;
  bool _carregandoLojas = true;

  List<Loja> _lojas = [];
  int? _lojaIdSelecionada;
  String _statusSelecionado = 'ATIVO';

  bool get editando => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    if (widget.usuario != null) {
      _nomeController.text = widget.usuario!.nmusuario;
      _emailController.text = widget.usuario!.emailuser;
      _lojaIdSelecionada = widget.usuario!.lojaId;
      _statusSelecionado = widget.usuario!.situsuario ?? 'ATIVO';
    }

    _carregarLojas();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarLojas() async {
    setState(() {
      _carregandoLojas = true;
    });

    try {
      final lista = await _lojaRepository.listar(widget.organizacaoId);

      if (!mounted) return;

      int? lojaSelecionada = _lojaIdSelecionada;

      if (lista.isNotEmpty && lojaSelecionada != null) {
        final existe = lista.any((loja) => loja.lojaId == lojaSelecionada);
        if (!existe) {
          lojaSelecionada = null;
        }
      }

      setState(() {
        _lojas = lista;
        _lojaIdSelecionada = lojaSelecionada;
        _carregandoLojas = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoLojas = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar lojas: $e')),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      if (editando) {
        await _usuarioRepository.atualizar(
          usuarioId: widget.usuario!.usuarioId,
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim().isEmpty
              ? null
              : _senhaController.text.trim(),
          lojaId: _lojaIdSelecionada,
          situsuario: _statusSelecionado,
        );
      } else {
        await _usuarioRepository.criar(
          organizacaoId: widget.organizacaoId,
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          lojaId: _lojaIdSelecionada,
          situsuario: _statusSelecionado,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Usuário atualizado com sucesso'
                : 'Usuário criado com sucesso',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar usuário: $e')),
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
        title: Text(editando ? 'Editar Usuário' : 'Novo Usuário'),
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
                      labelText: 'Nome do usuário',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do usuário';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: editando ? 'Nova senha (opcional)' : 'Senha',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!editando && (value == null || value.trim().isEmpty)) {
                        return 'Informe a senha';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _carregandoLojas
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int?>(
                          value: _lojaIdSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Loja',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Sem loja'),
                            ),
                            ..._lojas.map((loja) {
                              return DropdownMenuItem<int?>(
                                value: loja.lojaId,
                                child: Text(loja.nmloja),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _lojaIdSelecionada = value;
                            });
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