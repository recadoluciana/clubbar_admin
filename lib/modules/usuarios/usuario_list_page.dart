import 'package:flutter/material.dart';
import 'package:clubbar_admin/models/usuario.dart';
import 'package:clubbar_admin/core/repositories/usuario_repository.dart';
import 'package:clubbar_admin/modules/usuarios/usuario_form_page.dart';

class UsuarioListPage extends StatefulWidget {
  final int organizacaoId;

  const UsuarioListPage({
    super.key,
    required this.organizacaoId,
  });

  @override
  State<UsuarioListPage> createState() => _UsuarioListPageState();
}

class _UsuarioListPageState extends State<UsuarioListPage> {
  final UsuarioRepository _repository = UsuarioRepository();

  List<Usuario> _usuarios = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _repository.listar(widget.organizacaoId);

      if (!mounted) return;

      setState(() {
        _usuarios = lista;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Erro ao carregar usuários: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _novoUsuario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioFormPage(
          organizacaoId: widget.organizacaoId,
        ),
      ),
    );

    if (resultado == true) {
      _carregarUsuarios();
    }
  }

  Future<void> _editarUsuario(Usuario usuario) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioFormPage(
          organizacaoId: widget.organizacaoId,
          usuario: usuario,
        ),
      ),
    );

    if (resultado == true) {
      _carregarUsuarios();
    }
  }

  Future<void> _excluirUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
            'Deseja realmente excluir o usuário "${usuario.nmusuario}"?',
          ),
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
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _repository.excluir(usuario.usuarioId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário excluído com sucesso'),
        ),
      );

      _carregarUsuarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir usuário: $e'),
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _erro!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_usuarios.isEmpty) {
      return const Center(
        child: Text('Nenhum usuário encontrado.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarUsuarios,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _usuarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];

          return Card(
            child: ListTile(
              title: Text(usuario.nmusuario),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.emailuser),
                  Text('Situação: ${usuario.situsuario ?? '-'}'),
                  Text(
                    'Loja ID: ${usuario.lojaId?.toString() ?? 'Não vinculada'}',
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _editarUsuario(usuario);
                  } else if (value == 'excluir') {
                    _excluirUsuario(usuario);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir'),
                  ),
                ],
              ),
              onTap: () => _editarUsuario(usuario),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoUsuario,
        child: const Icon(Icons.add),
      ),
    );
  }
}