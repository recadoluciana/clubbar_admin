import 'package:flutter/material.dart';

import '../../core/repositories/superadmin_repository.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/api_status_indicator.dart';
import '../../core/widgets/clubbar_page_header.dart';

import '../auth/login_page.dart';
import '../leads/pages/leadparceiro_list_page.dart';
import '../financeiro/financeiro_admin_page.dart';
import 'admin_modules_pages.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  final SuperAdminRepository _repo = SuperAdminRepository();

  bool _carregando = true;

  Map<String, dynamic> _dados = {};

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  void _abrirLeads() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeadParceiroListPage()));
  }

  void _abrirFinanceiro() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FinanceiroAdminPage()));

  void _abrirParceiros() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ParceirosAdminPage()));

  void _abrirEstabelecimentos() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const EstabelecimentosAdminPage()));

  void _abrirUsuarios() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const UsuariosAdminPage()));

  void _abrirVendasHoje() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const VendasHojeAdminPage()));

  Future<void> _inicializar() async {
    await _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final result = await _repo.dashboard();

      if (!mounted) return;

      setState(() {
        _dados = result;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível carregar o painel administrativo.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Future<void> _atualizar() async {
    await _carregarDashboard();

    if (!mounted) return;

    _mostrarMensagem('Painel atualizado com sucesso.');
  }

  Future<void> _sair() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Encerrar sessão',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text('Deseja realmente sair do Clubbar Admin?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (sair != true) return;

    await StorageService.clearToken();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  int _valorInteiro(String chave) {
    final valor = _dados[chave];

    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  int _totalParceiros() {
    return _valorInteiro('parceiros_ativos');
  }

  double _valorFaturamentoHoje() {
    final valor = _dados['faturamento_total'];

    if (valor == null) return 0;

    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _cardIndicador({
    required String titulo,
    required String valor,
    required IconData icone,
    VoidCallback? onTap,
  }) {
    final corIcone = switch (icone) {
      Icons.handshake_rounded => Colors.blue,
      Icons.business_rounded => Colors.deepPurple,
      Icons.storefront_rounded => Colors.deepOrange,
      Icons.manage_accounts_rounded => Colors.teal,
      Icons.point_of_sale_rounded => Colors.green,
      _ => Colors.indigo,
    };
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: corIcone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, size: 25, color: corIcone),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeNovos(int quantidade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$quantidade novo${quantidade == 1 ? '' : 's'}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _cardLeads() {
    Widget linha({
      required String titulo,
      required int total,
      required int novos,
    }) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '$titulo  $total',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          _badgeNovos(novos),
        ],
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: _abrirLeads,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  size: 25,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    linha(
                      titulo: 'Leads',
                      total: _valorInteiro('total_leads'),
                      novos: _valorInteiro('leads_novos'),
                    ),
                    const Divider(height: 18),
                    linha(
                      titulo: 'Estabelecimentos',
                      total: _valorInteiro('total_lead_estabelecimentos'),
                      novos: _valorInteiro('lead_estabelecimentos_novos'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget grade(List<Widget> itens) => Column(
          children: [
            for (int indice = 0; indice < itens.length; indice++) ...[
              itens[indice],
              if (indice < itens.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
        Widget titulo(String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titulo('Cadastros da plataforma'),
            grade([
              _cardLeads(),

              _cardIndicador(
                titulo: 'Organizações Parceiras',
                valor: '${_totalParceiros()}',
                icone: Icons.business_rounded,
                onTap: _abrirParceiros,
              ),

              _cardIndicador(
                titulo: 'Estabelecimentos Parceiros',
                valor: '${_dados['total_estabelecimentos'] ?? 0}',
                icone: Icons.storefront_rounded,
                onTap: _abrirEstabelecimentos,
              ),

              _cardIndicador(
                titulo: 'Usuários do Clubbar',
                valor: '${_dados['usuarios'] ?? 0}',
                icone: Icons.manage_accounts_rounded,
                onTap: _abrirUsuarios,
              ),
            ]),
            const SizedBox(height: 18),
            titulo('Movimento de hoje'),
            grade([
              _cardIndicador(
                titulo: 'Vendas e faturamento hoje',
                valor:
                    '${_dados['vendas_hoje'] ?? 0} vendas  •  '
                    '${_formatarMoeda(_valorFaturamentoHoje())}',
                icone: Icons.point_of_sale_rounded,
                onTap: _abrirVendasHoje,
              ),
            ]),
            const SizedBox(height: 18),
            titulo('Gestão financeira'),
            grade([
              _cardIndicador(
                titulo: 'Gerenciar repasses ao parceiro',
                valor: 'Financeiro',
                icone: Icons.account_balance_wallet_rounded,
                onTap: _abrirFinanceiro,
              ),
            ]),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),

      appBar: ClubbarAppBar(
        mostrarSair: true,
        onSair: _sair,
        actions: [const ApiStatusIndicator(versao: '1.0.1')],
      ),

      body: SafeArea(
        child: Column(
          children: [
            ClubbarPageHeader(
              titulo: 'Painel Administrativo',
              subtitulo: 'Visão geral e administração do Clubbar',
              icone: Icons.dashboard_rounded,
              mostrarDataHora: true,
              trailing: IconButton(
                tooltip: 'Atualizar painel',
                onPressed: _carregando ? null : _atualizar,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),

            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _atualizar,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: _dashboard(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
