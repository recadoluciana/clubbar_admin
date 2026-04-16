import 'package:flutter/material.dart';

import 'package:clubbar_admin/core/services/storage_service.dart';
import 'package:clubbar_admin/modules/auth/login_page.dart';
import 'package:clubbar_admin/modules/categorias/categoria_list_page.dart';
import 'package:clubbar_admin/modules/eventos/evento_list_page.dart';
import 'package:clubbar_admin/modules/lojas/loja_list_page.dart';
import 'package:clubbar_admin/modules/organizacoes/organizacao_form_page.dart';
import 'package:clubbar_admin/modules/produtos/produto_list_page.dart';
import 'package:clubbar_admin/modules/painel_gerencial/painel_gerencial_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _nomeUsuario = 'Usuário';
  String _nomeOrganizacao = 'Organização';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final nomeUsuario = await StorageService.getNomeUsuario();
    final nomeOrganizacao = await StorageService.getNomeOrganizacao();

    if (!mounted) return;

    setState(() {
      _nomeUsuario = nomeUsuario ?? 'Usuário';
      _nomeOrganizacao = nomeOrganizacao ?? 'Organização';
    });
  }

  Future<void> _sair(BuildContext context) async {
    await StorageService.clearToken();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<int?> _getOrganizacaoId() async {
    return await StorageService.getOrganizacaoId();
  }

  Future<void> _abrirModulo(BuildContext context, String nomeModulo) async {
    final organizacaoId = await _getOrganizacaoId();

    if (organizacaoId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organização não encontrada no login.')),
      );
      return;
    }

    Widget? destino;

    if (nomeModulo == 'Minha organização') {
      destino = const OrganizacaoFormPage();
    } else if (nomeModulo == 'Lojas') {
      destino = LojaListPage(organizacaoId: organizacaoId);
    } else if (nomeModulo == 'Categorias de produto') {
      destino = CategoriaListPage(organizacaoId: organizacaoId);
    } else if (nomeModulo == 'Produtos') {
      destino = ProdutoListPage(organizacaoId: organizacaoId);
    } else if (nomeModulo == 'Eventos') {
      destino = EventoListPage(organizacaoId: organizacaoId);
    } else if (nomeModulo == 'Painel gerencial') {
      destino = const PainelGerencialPage();
    }

    if (destino == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Módulo "$nomeModulo" ainda não implementado.')),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino!));
  }

  @override
  Widget build(BuildContext context) {
    final modulos = [
      _DashboardItem(
        titulo: 'Minha organização',
        subtitulo: 'Altere os dados da sua organização',
        icone: Icons.business,
      ),
      _DashboardItem(
        titulo: 'Lojas',
        subtitulo: 'Cadastre e gerencie as lojas da sua organização',
        icone: Icons.store,
      ),
      _DashboardItem(
        titulo: 'Categorias de Produto',
        subtitulo: 'Cadastre e gerencie as categorias dos produtos das lojas',
        icone: Icons.category,
      ),
      _DashboardItem(
        titulo: 'Produtos',
        subtitulo: 'Cadastre e gerencie os produtos das lojas',
        icone: Icons.inventory_2,
      ),
      _DashboardItem(
        titulo: 'Eventos',
        subtitulo: 'Cadastre e gerencie eventos e lotes',
        icone: Icons.event,
      ),
      _DashboardItem(
        titulo: 'Painel de Controle',
        subtitulo: 'Indicadores e gráficos gerenciais',
        icone: Icons.analytics,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubbar Admin'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.orange.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      _nomeUsuario,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_nomeOrganizacao),
                    const SizedBox(height: 4),
                    const Text('Administrador'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Início'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Minha organização'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Minha organização');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.store),
                      title: const Text('Lojas'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Lojas');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('Categorias de Produto'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Categorias de Produto');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: const Text('Produtos'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Produtos');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Eventos'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Eventos');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text('Painel de Controle'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Painel de Controle');
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () => _sair(context),
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;

          if (constraints.maxWidth >= 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 800) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 600) {
            crossAxisCount = 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $_nomeUsuario 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Você está gerenciando: $_nomeOrganizacao',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primeiros passos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Revise sua organização, cadastre lojas, depois categorias, produtos e eventos.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  itemCount: modulos.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (context, index) {
                    final item = modulos[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _abrirModulo(context, item.titulo),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                child: Icon(item.icone, size: 26),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                item.titulo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  item.subtitulo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Text(
                                    'Abrir',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardItem {
  final String titulo;
  final String subtitulo;
  final IconData icone;

  _DashboardItem({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
  });
}
