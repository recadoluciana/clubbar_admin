import 'package:flutter/material.dart';

import '../../core/repositories/cora_admin_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class CoraDuvidasAdminPage extends StatefulWidget {
  const CoraDuvidasAdminPage({super.key});
  @override
  State<CoraDuvidasAdminPage> createState() => _CoraDuvidasAdminPageState();
}

class _CoraDuvidasAdminPageState extends State<CoraDuvidasAdminPage> {
  final _repo = CoraAdminRepository();
  List<CoraDuvidaAdmin> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final itens = await _repo.listarDuvidas();
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editar([CoraDuvidaAdmin? item]) async {
    final pergunta = TextEditingController(text: item?.pergunta ?? '');
    final resposta = TextEditingController(text: item?.resposta ?? '');
    final ordem = TextEditingController(
      text: '${item?.ordem ?? _itens.length + 1}',
    );
    var ativa = item?.situacao != 'INATIVA';
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          title: Text(
            item == null ? 'Nova dúvida frequente' : 'Editar dúvida frequente',
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pergunta,
                    maxLength: 255,
                    decoration: const InputDecoration(labelText: 'Pergunta'),
                  ),
                  TextField(
                    controller: resposta,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 5000,
                    decoration: const InputDecoration(labelText: 'Resposta'),
                  ),
                  TextField(
                    controller: ordem,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ordem de exibição',
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: Colors.green,
                    value: ativa,
                    onChanged: (v) => setD(() => ativa = v),
                    title: const Text('Dúvida ativa'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final numero = int.tryParse(ordem.text.trim());
    if (pergunta.text.trim().length < 3 ||
        resposta.text.trim().length < 3 ||
        numero == null ||
        numero < 1) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha pergunta, resposta e ordem.')),
        );
      return;
    }
    try {
      await _repo.salvarDuvida(
        item,
        pergunta.text.trim(),
        resposta.text.trim(),
        numero,
        ativa ? 'ATIVA' : 'INATIVA',
      );
      await _carregar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      pergunta.dispose();
      resposta.dispose();
      ordem.dispose();
    }
  }

  Future<void> _excluir(CoraDuvidaAdmin item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Excluir dúvida?'),
        content: Text(item.pergunta),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.excluirDuvida(item.id);
      await _carregar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _editar(),
      icon: const Icon(Icons.add),
      label: const Text('Nova dúvida'),
    ),
    body: Column(
      children: [
        ClubbarPageHeader(
          titulo: 'Dúvidas frequentes',
          subtitulo: 'Perguntas e respostas exibidas pela Cora',
          mostrarDadosSessao: false,
          trailing: IconButton(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    itemCount: _itens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _itens[i];
                      final ativa = item.situacao == 'ATIVA';
                      return Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text('${item.ordem}')),
                          title: Text(item.pergunta),
                          subtitle: Text(
                            ativa ? 'Ativa' : 'Inativa',
                            style: TextStyle(
                              color: ativa ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                color: Colors.blue,
                                onPressed: () => _editar(item),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                color: Colors.red,
                                onPressed: () => _excluir(item),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(item.resposta),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}
