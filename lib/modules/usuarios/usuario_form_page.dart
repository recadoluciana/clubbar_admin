import 'package:flutter/material.dart';
import 'package:clubbar_admin/models/usuario.dart';
import 'package:clubbar_admin/core/repositories/usuario_repository.dart';

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

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _lojaIdController = TextEditingController();

  final UsuarioRepository _repository = UsuarioRepository();

  bool _salvando = false;
  String _situacao = 'ATIVO';

  bool get _editando => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    if (_editando) {
      final usuario = widget.usuario!;
      _nomeController.text = usuario.nmusuario;
      _emailController.text = usuario.emailuser;
      _situacao = usuario.situsuario ?? 'ATIVO';

      if (usuario.lojaId != null) {
        _lojaIdController.text = usuario.lojaId.toString();
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _lojaIdController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();
      final lojaIdTexto = _lojaIdController.text.trim();

      final int? lojaId =
          lojaIdTexto.isEmpty ? null : int.tryParse(lojaIdTexto);

      if (_editando) {
        await _repository.atualizar(
          usuarioId: widget.usuario!.usuarioId,
          nome: nome,
          email: email,
          senha: senha.isEmpty ? null : senha,
          lojaId: lojaId,
          situsuario: _situacao,
        );
      } else {
        await _repository.criar(
          organizacaoId: widget.organizacaoId,
          nome: nome,
          email: email,
          senha: senha,
          lojaId: lojaId,
          situsuario: _situacao,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Usuário atualizado com sucesso'
                : 'Usuário criado com sucesso',
          ),
        ),
      );

      Navigator.pop(context, true);
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
        title: Text(_editando ? 'Editar Usuário' : 'Novo Usuário'),
      ),
      body: AbsorbPointer(
        absorbing: _salvando,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome';
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
                    if (!value.contains('@')) {
                      return 'Informe um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _editando
                        ? 'Senha (deixe em branco para não alterar)'
                        : 'Senha',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_editando && (value == null || value.trim().isEmpty)) {
                      return 'Informe a senha';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lojaIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Loja ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _situacao,
                  decoration: const InputDecoration(
                    labelText: 'Situação',
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
                        _situacao = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_editando ? 'Atualizar' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}