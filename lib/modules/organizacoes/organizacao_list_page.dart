import 'package:flutter/material.dart';

import '../../core/repositories/organizacao_repository.dart';
import '../../core/services/storage_service.dart';
import '../../models/organizacao.dart';
import 'organizacao_form_page.dart';

class OrganizacaoListPage extends StatefulWidget {
  const OrganizacaoListPage({super.key});

  @override
  State<OrganizacaoListPage> createState() => _OrganizacaoListPageState();
}

class _OrganizacaoListPageState extends State<OrganizacaoListPage> {
  final TextEditingController _buscaController = TextEditingController();
  final OrganizacaoRepository _repository = OrganizacaoRepository();

  bool _carregando = true;
  Organizacao? _organizacao;
  List<Organizacao> _organizacoesFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarOrganizacao();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarOrganizacao() async {
    setState(() {
      _carregando = true;
    });

    try {
      final usuarioId = await StorageService.getUsuarioId();

      if (usuarioId == null) {
        throw Exception('Usuário não encontrado no login');
      }

      final organizacao = await _repository.buscarPorUsuario(usuarioId);

      if (!mounted) return;

      setState(() {
        _organizacao = organizacao;
        _organizacoesFiltradas = [organizacao];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _organizacao = null;
        _organizacoesFiltradas = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar organização: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _filtrar(String texto) {
    final busca = texto.trim().toLowerCase();

    if (_organizacao == null) {
      setState(() {
        _organizacoesFiltradas = [];
      });
      return;
    }

    setState(() {
      if (busca.isEmpty) {
        _organizacoesFiltradas = [_organizacao!];
      } else {
        final id = _organizacao!.organizacaoId.toString();
        final nome = _organizacao!.nmorganizacao.toLowerCase();
        final status = (_organizacao!.sitorganizacao ?? '').toLowerCase();
        final cnpj = (_organizacao!.cnpjorganizacao ?? '').toLowerCase();
        final email = (_organizacao!.emailorganizacao ?? '').toLowerCase();
        final telefone = (_organizacao!.telorganizacao ?? '').toLowerCase();

        final bate = id.contains(busca) ||
            nome.contains(busca) ||
            status.contains(busca) ||
            cnpj.contains(busca) ||
            email.contains(busca) ||
            telefone.contains(busca);

        _organizacoesFiltradas = bate ? [_organizacao!] : [];
      }
    });
  }

  Future<void> _novaOrganizacao() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const OrganizacaoFormPage(),
      ),
    );

    if (result == true) {
      _carregarOrganizacao();
    }
  }

  Future<void> _editarOrganizacao(Organizacao organizacao) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrganizacaoFormPage(
          organizacao: organizacao,
        ),
      ),
    );

    if (result == true) {
      _carregarOrganizacao();
    }
  }

  Widget _buildTabela() {
    if (_organizacoesFiltradas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhuma organização encontrada.'),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('CNPJ')),
            DataColumn(label: Text('E-mail')),
            DataColumn(label: Text('Telefone')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _organizacoesFiltradas.map((organizacao) {
            return DataRow(
              cells: [
                DataCell(Text(organizacao.organizacaoId.toString())),
                DataCell(Text(organizacao.nmorganizacao)),
                DataCell(Text(organizacao.cnpjorganizacao ?? '-')),
                DataCell(Text(organizacao.emailorganizacao ?? '-')),
                DataCell(Text(organizacao.telorganizacao ?? '-')),
                DataCell(Text(organizacao.sitorganizacao ?? '-')),
                DataCell(
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () => _editarOrganizacao(organizacao),
                    icon: const Icon(Icons.edit),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizações'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscaController,
                    onChanged: _filtrar,
                    decoration: const InputDecoration(
                      labelText: 'Buscar organização',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _novaOrganizacao,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _carregarOrganizacao,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabela(),
            ),
          ],
        ),
      ),
    );
  }
}