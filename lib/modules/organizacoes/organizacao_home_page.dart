import 'package:flutter/material.dart';

import '../lojas/loja_list_page.dart';
import '../usuarios/usuario_list_page.dart';
import 'organizacao_form_page.dart';

class OrganizacaoHomePage extends StatelessWidget {
  final int organizacaoId;
  final String nomeOrganizacao;

  const OrganizacaoHomePage({
    super.key,
    required this.organizacaoId,
    required this.nomeOrganizacao,
  });

  void _abrirDadosOrganizacao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrganizacaoFormPage(),
      ),
    );
  }

  void _abrirUsuarios(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsuarioListPage(
          organizacaoId: organizacaoId,
        ),
      ),
    );
  }

  void _abrirLojas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LojaListPage(
          organizacaoId: organizacaoId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _OrgHomeItem(
        titulo: 'Dados da organização',
        subtitulo: 'Edite nome, CNPJ, e outras informações da organização.',
        icone: Icons.business,
        onTap: () => _abrirDadosOrganizacao(context),
      ),
      _OrgHomeItem(
        titulo: 'Usuários',
        subtitulo: 'Gerencie os usuários vinculados a esta organização.',
        icone: Icons.people,
        onTap: () => _abrirUsuarios(context),
      ),
      _OrgHomeItem(
        titulo: 'Lojas',
        subtitulo: 'Cadastre e gerencie as lojas da organização.',
        icone: Icons.store,
        onTap: () => _abrirLojas(context),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(nomeOrganizacao),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth >= 1000) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 2;
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeOrganizacao,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escolha abaixo o que deseja gerenciar nesta organização.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gestão da organização',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  itemCount: cards.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (_, index) {
                    final item = cards[index];

                    return InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(18),
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

class _OrgHomeItem {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final VoidCallback onTap;

  _OrgHomeItem({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.onTap,
  });
}