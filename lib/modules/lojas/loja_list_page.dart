import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/repositories/loja_repository.dart';
import '../../core/services/storage_service.dart';
import '../../models/loja.dart';
import 'loja_form_page.dart';

class LojaListPage extends StatefulWidget {
  const LojaListPage({super.key});

  @override
  State<LojaListPage> createState() => _LojaListPageState();
}

class _LojaListPageState extends State<LojaListPage> {
  final TextEditingController _buscaController = TextEditingController();
  final LojaRepository _repository = LojaRepository();

  bool _carregando = true;
  int? _organizacaoId;
  List<Loja> _lojas = [];
  List<Loja> _lojasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarLojas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _extrairMensagemErro(Object e) {
    final texto = e.toString();

    try {
      final inicio = texto.indexOf('{');
      final fim = texto.lastIndexOf('}');

      if (inicio != -1 && fim != -1) {
        final jsonStr = texto.substring(inicio, fim + 1);
        final jsonMap = jsonDecode(jsonStr);

        if (jsonMap is Map && jsonMap['detail'] != null) {
          return jsonMap['detail'].toString();
        }
      }
    } catch (_) {}

    return texto.replaceAll('Exception:', '').trim();
  }

  Future<void> _carregarLojas() async {
    setState(() {
      _carregando = true;
    });

    try {
      final organizacaoId = await StorageService.getOrganizacaoId();

      if (organizacaoId == null) {
        throw Exception('Organização não encontrada no login');
      }

      final lista = await _repository.listar(organizacaoId);

      if (!mounted) return;

      setState(() {
        _organizacaoId = organizacaoId;
        _lojas = lista;
        _lojasFiltradas = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
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

    setState(() {
      if (busca.isEmpty) {
        _lojasFiltradas = _lojas;
      } else {
        _lojasFiltradas = _lojas.where((loja) {
          return loja.lojaId.toString().contains(busca) ||
              loja.nmloja.toLowerCase().contains(busca) ||
              (loja.dsbairroloja ?? '').toLowerCase().contains(busca) ||
              (loja.nrtelloja ?? '').toLowerCase().contains(busca) ||
              (loja.sitloja ?? '').toLowerCase().contains(busca);
        }).toList();
      }
    });
  }

  String _montarUrlLogo(Loja loja) {
    final urlLogo = (loja.urllogoloja ?? '').trim();

    if (urlLogo.isEmpty) return '';

    if (urlLogo.startsWith('http')) {
      return urlLogo;
    }

    final path = urlLogo.startsWith('/') ? urlLogo : '/$urlLogo';
    return '${ApiConfig.baseUrl}$path';
  }

  Future<void> _abrirNovaLoja() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LojaFormPage(),
      ),
    );

    if (result == true) {
      _carregarLojas();
    }
  }

  Future<void> _abrirEdicao(Loja loja) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LojaFormPage(loja: loja),
      ),
    );

    if (result == true) {
      _carregarLojas();
    }
  }

  Future<void> _confirmarExclusao(Loja loja) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir loja'),
        content: Text('Deseja excluir a loja "${loja.nmloja}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repository.excluir(loja.lojaId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loja excluída com sucesso')),
      );

      _carregarLojas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    }
  }

  Widget _buildTabela() {
    if (_lojasFiltradas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhuma loja encontrada.')),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Logo')),
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Bairro')),
              DataColumn(label: Text('Telefone')),
              DataColumn(label: Text('Horário')),
              DataColumn(label: Text('Validade')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: _lojasFiltradas.map((loja) {
              final urlCompleta = _montarUrlLogo(loja);

              return DataRow(
                cells: [
                  DataCell(
                    urlCompleta.isNotEmpty
                        ? SizedBox(
                            width: 40,
                            height: 40,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                urlCompleta,
                                key: ValueKey(urlCompleta),
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, __) {
                                  print('ERRO IMG LOJA LISTA: $urlCompleta');
                                  print('DETALHE: $error');
                                  return const Icon(Icons.store);
                                },
                              ),
                            ),
                          )
                        : const Icon(Icons.store),
                  ),
                  DataCell(Text(loja.lojaId.toString())),
                  DataCell(Text(loja.nmloja)),
                  DataCell(Text(loja.dsbairroloja ?? '-')),
                  DataCell(Text(loja.nrtelloja ?? '-')),
                  DataCell(Text(loja.dshorarioloja ?? '-')),
                  DataCell(Text(loja.nrdiavalidade?.toString() ?? '-')),
                  DataCell(Text(loja.sitloja ?? '-')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _abrirEdicao(loja),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () => _confirmarExclusao(loja),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lojas'),
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
                      labelText: 'Buscar loja',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _abrirNovaLoja,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _carregarLojas,
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