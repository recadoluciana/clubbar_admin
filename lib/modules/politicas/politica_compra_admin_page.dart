import 'package:flutter/material.dart';

import '../../core/repositories/politica_compra_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class PoliticaCompraAdminPage extends StatefulWidget {
  const PoliticaCompraAdminPage({super.key});

  @override
  State<PoliticaCompraAdminPage> createState() =>
      _PoliticaCompraAdminPageState();
}

class _PoliticaCompraAdminPageState extends State<PoliticaCompraAdminPage> {
  final _repo = PoliticaCompraRepository();
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _itens = await _repo.listar();
    } catch (e) {
      if (mounted) _mensagem('$e', erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto.replaceFirst('Exception: ', '')),
        backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _novaVersao() async {
    Map<String, dynamic>? atual;
    for (final item in _itens) {
      if (item['sitpolitica'] == 'VIGENTE') {
        atual = item;
        break;
      }
    }
    final versao = TextEditingController();
    final titulo = TextEditingController(
      text: atual?['titulo']?.toString() ?? 'Política de Compra Clubbar',
    );
    final conteudo = TextEditingController(
      text: atual?['conteudo']?.toString() ?? '',
    );
    final form = GlobalKey<FormState>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar política de compra'),
        content: SizedBox(
          width: 850,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: versao,
                    decoration: const InputDecoration(
                      labelText: 'Nova versão *',
                      hintText: 'Ex.: 1.1',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe a versão'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titulo,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Informe o título'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: conteudo,
                    minLines: 14,
                    maxLines: 24,
                    decoration: const InputDecoration(
                      labelText: 'Conteúdo da política *',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 20
                        ? 'Informe o conteúdo completo'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repo.publicar({
        'versao': versao.text.trim(),
        'titulo': titulo.text.trim(),
        'conteudo': conteudo.text.trim(),
      });
      if (mounted) {
        _mensagem('Nova política publicada. A versão anterior foi preservada.');
      }
      await _carregar();
    } catch (e) {
      if (mounted) _mensagem('$e', erro: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _novaVersao,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nova versão'),
    ),
    body: Column(
      children: [
        ClubbarPageHeader(
          titulo: 'Política de compra',
          subtitulo: 'Versões gerais do Clubbar para produtos e ingressos',
          mostrarDadosSessao: false,
          trailing: IconButton(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: _itens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = _itens[index];
                    final vigente = item['sitpolitica'] == 'VIGENTE';
                    return Card(
                      child: ExpansionTile(
                        leading: Icon(
                          Icons.policy_rounded,
                          color: vigente ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          '${item['titulo']} • versão ${item['versao']}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(vigente ? 'VIGENTE' : 'ENCERRADA'),
                        trailing: vigente
                            ? const Chip(label: Text('Versão atual'))
                            : null,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(
                              item['conteudo']?.toString() ?? '',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
