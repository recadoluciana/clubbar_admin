import 'package:flutter/material.dart';

import '../../core/services/storage_service.dart';
import '../auth/login_page.dart';
import '../categorias/categoria_list_page.dart';
import '../organizacoes/organizacao_list_page.dart';
import '../produtos/produto_list_page.dart';
import '../lojas/loja_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _sair(BuildContext context) async {
    await StorageService.clearToken();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _abrirModulo(BuildContext context, String nomeModulo) async {
    Widget? destino;

    final lojaId = await StorageService.getLojaId();

    if (nomeModulo == 'Organizações') {
      destino = const OrganizacaoListPage();
    } else {
      if (lojaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loja não encontrada no login')),
        );
        return;
      }

      if (nomeModulo == 'Categorias') {
        destino = CategoriaListPage(lojaId: lojaId);
      } else if (nomeModulo == 'Produtos') {
        destino = ProdutoListPage(
          lojaId: lojaId,
          organizacaoId: 1,
        );
      } else if (nomeModulo == 'Lojas') {
        destino = const LojaListPage();
      }
    }

    if (destino != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destino!),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo "$nomeModulo" ainda não implementado.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modulos = [
      _DashboardItem(
        titulo: 'Organizações',
        subtitulo: 'Cadastro e gestão de organizações',
        icone: Icons.business,
      ),
      _DashboardItem(
        titulo: 'Lojas',
        subtitulo: 'Cadastro e gestão das lojas',
        icone: Icons.store,
      ),
      _DashboardItem(
        titulo: 'Categorias',
        subtitulo: 'Cadastro de categorias de produtos',
        icone: Icons.category,
      ),
      _DashboardItem(
        titulo: 'Produtos',
        subtitulo: 'Cadastro e listagem de produtos',
        icone: Icons.inventory_2,
      ),
      _DashboardItem(
        titulo: 'Usuários',
        subtitulo: 'Cadastro e controle de usuários',
        icone: Icons.people,
      ),
      _DashboardItem(
        titulo: 'Eventos',
        subtitulo: 'Agenda da loja e eventos',
        icone: Icons.event,
      ),
      _DashboardItem(
        titulo: 'Lotes',
        subtitulo: 'Lotes de ingressos dos eventos',
        icone: Icons.confirmation_number,
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 42),
                    SizedBox(height: 10),
                    Text(
                      'Clubbar Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Painel administrativo'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Organizações'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Organizações');
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
                      title: const Text('Categorias'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Categorias');
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
                      leading: const Icon(Icons.people),
                      title: const Text('Usuários'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Usuários');
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
                      leading: const Icon(Icons.confirmation_number),
                      title: const Text('Lotes'),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirModulo(context, 'Lotes');
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
            crossAxisCount = 3;
          } else if (constraints.maxWidth < 600) {
            crossAxisCount = 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          'Bem-vinda ao Clubbar Admin',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gerencie organizações, lojas, categorias, produtos, usuários, eventos e lotes em um único painel.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Módulos do sistema',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  itemCount: modulos.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
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
                                    'Abrir módulo',
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