import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/repositories/superadmin_repository.dart';
import '../../core/theme/clubbar_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_card.dart';
import '../../core/widgets/clubbar_page_header.dart';

class ControleUsuariosAdminPage extends StatefulWidget {
  const ControleUsuariosAdminPage({super.key});

  @override
  State<ControleUsuariosAdminPage> createState() =>
      _ControleUsuariosAdminPageState();
}

class _ControleUsuariosAdminPageState extends State<ControleUsuariosAdminPage> {
  final _repo = SuperAdminRepository();
  List<Map<String, dynamic>> _organizacoes = [];
  List<Map<String, dynamic>> _usuarios = [];
  int? _organizacaoId;
  bool _carregando = true;
  int? _usuarioEmReset;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  String _texto(dynamic valor, {String padrao = ''}) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? padrao : texto;
  }

  int _inteiro(dynamic valor) =>
      valor is num ? valor.toInt() : int.tryParse('$valor') ?? 0;

  String _cargo(dynamic valor) => _texto(valor, padrao: 'Não informado')
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (parte) => parte.isEmpty
            ? parte
            : '${parte[0].toUpperCase()}${parte.substring(1)}',
      )
      .join(' ');

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resultados = await Future.wait([
        _repo.listarOrganizacoes(),
        _repo.listarUsuariosControle(organizacaoId: _organizacaoId),
      ]);
      if (!mounted) return;
      setState(() {
        _organizacoes = resultados[0];
        _usuarios = resultados[1];
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarOrganizacao(int? organizacaoId) async {
    setState(() => _organizacaoId = organizacaoId);
    await _carregar();
  }

  Future<void> _resetarSenha(Map<String, dynamic> usuario) async {
    final nome = _texto(usuario['nmusuario'], padrao: 'este usuário');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: ClubbarColors.ambarEscuro),
            SizedBox(width: 10),
            Expanded(child: Text('Redefinir senha')),
          ],
        ),
        content: Text(
          'Gerar uma nova senha temporária para $nome? A senha anterior deixará de funcionar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Gerar senha'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final usuarioId = _inteiro(usuario['usuario_id']);
    setState(() => _usuarioEmReset = usuarioId);
    try {
      final resposta = await _repo.resetarSenhaUsuario(usuarioId);
      if (!mounted) return;
      await _mostrarSenhaGerada(
        nome: _texto(resposta['nmusuario'], padrao: nome),
        email: _texto(resposta['emailuser']),
        senha: _texto(resposta['senha_temporaria']),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _usuarioEmReset = null);
    }
  }

  Future<void> _mostrarSenhaGerada({
    required String nome,
    required String email,
    required String senha,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.password_rounded, color: ClubbarColors.sucesso),
            SizedBox(width: 10),
            Expanded(child: Text('Senha temporária gerada')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envie esta senha para $nome acessar o Clubbar Partner ou o QR Code.',
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                email,
                style: const TextStyle(color: ClubbarColors.textoSecundario),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: ClubbarColors.ambarClaro,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ClubbarColors.ambarEscuro),
              ),
              child: SelectableText(
                senha,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Copie ou anote agora: por segurança, esta senha não será exibida novamente.',
              style: TextStyle(
                fontSize: 12,
                color: ClubbarColors.textoSecundario,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: senha));
              if (context.mounted) {
                AppSnackBar.sucesso(context, 'Senha copiada.');
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar senha'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Concluído'),
          ),
        ],
      ),
    );
  }

  Color _corStatus(String status) => status.toUpperCase() == 'ATIVO'
      ? ClubbarColors.sucesso
      : ClubbarColors.erro;

  Widget _chip({required IconData icon, required String label, Color? color}) {
    final cor = color ?? ClubbarColors.textoSecundario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardUsuario(Map<String, dynamic> usuario) {
    final status = _texto(usuario['situsuario'], padrao: 'INATIVO');
    final usuarioId = _inteiro(usuario['usuario_id']);
    final emReset = _usuarioEmReset == usuarioId;
    return ClubbarCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: ClubbarColors.info.withValues(alpha: 0.14),
                foregroundColor: ClubbarColors.info,
                child: const Icon(Icons.person_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _texto(usuario['nmusuario'], padrao: 'Usuário sem nome'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _texto(
                        usuario['emailuser'],
                        padrao: 'E-mail não informado',
                      ),
                    ),
                  ],
                ),
              ),
              _chip(
                icon: status.toUpperCase() == 'ATIVO'
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                label: _cargo(status),
                color: _corStatus(status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                icon: Icons.business_rounded,
                label: _texto(
                  usuario['nmorganizacao'],
                  padrao: 'Organização não informada',
                ),
                color: ClubbarColors.info,
              ),
              _chip(
                icon: Icons.badge_outlined,
                label: _cargo(usuario['dscargo']),
                color: ClubbarColors.ambarEscuro,
              ),
              _chip(
                icon: Icons.storefront_rounded,
                label: _texto(usuario['nmloja'], padrao: 'Sem estabelecimento'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: emReset ? null : () => _resetarSenha(usuario),
              icon: emReset
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset_rounded),
              label: Text(emReset ? 'Gerando senha...' : 'Resetar senha'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ClubbarColors.ambarEscuro,
                side: const BorderSide(color: ClubbarColors.ambarEscuro),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ClubbarColors.fundo,
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    body: SafeArea(
      child: Column(
        children: [
          ClubbarPageHeader(
            titulo: 'Controle de usuários',
            subtitulo: 'Consulte acessos e redefina senhas temporárias.',
            icone: Icons.manage_accounts_rounded,
            mostrarIcone: true,
            mostrarDadosSessao: false,
            trailing: IconButton(
              tooltip: 'Atualizar',
              onPressed: _carregando ? null : _carregar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ClubbarColors.ambar,
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      children: [
                        ClubbarCard(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _organizacaoId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Organização',
                              prefixIcon: Icon(Icons.business_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Todas as organizações'),
                              ),
                              ..._organizacoes.map(
                                (organizacao) => DropdownMenuItem<int?>(
                                  value: _inteiro(
                                    organizacao['organizacao_id'],
                                  ),
                                  child: Text(
                                    _texto(
                                      organizacao['nmorganizacao'],
                                      padrao: 'Organização sem nome',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: _selecionarOrganizacao,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${_usuarios.length} ${_usuarios.length == 1 ? 'usuário cadastrado' : 'usuários cadastrados'}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        if (_usuarios.isEmpty)
                          const ClubbarCard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 42,
                                    color: ClubbarColors.textoSecundario,
                                  ),
                                  SizedBox(height: 10),
                                  Text('Nenhum usuário encontrado.'),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._usuarios.map(_cardUsuario),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
