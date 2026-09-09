import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/repositories/taxa_padrao_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class TaxaPadraoAdminPage extends StatefulWidget {
  const TaxaPadraoAdminPage({super.key});
  @override
  State<TaxaPadraoAdminPage> createState() => _State();
}

class _State extends State<TaxaPadraoAdminPage> {
  final repo = TaxaPadraoRepository();
  List<Map<String, dynamic>> itens = [];
  bool carregando = true;
  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => carregando = true);
    try {
      itens = await repo.listar();
    } catch (e) {
      msg('$e', true);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  void msg(String s, [bool erro = false]) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.replaceFirst('Exception: ', '')),
          backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
  Future<void> editar([Map<String, dynamic>? item]) async {
    final p = TextEditingController(
      text: '${item?['pctaxaproduto'] ?? 5}'.replaceAll('.', ','),
    );
    final i = TextEditingController(
      text: '${item?['pctaxaingresso'] ?? 10}'.replaceAll('.', ','),
    );
    final m = TextEditingController(
      text: '${item?['vrtaxaminimaingresso'] ?? 2.99}'.replaceAll('.', ','),
    );
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          item == null
              ? 'Criar nova versão'
              : 'Editar versão ${item['nrversao']}',
        ),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              campo(p, 'Taxa de produtos (%)'),
              const SizedBox(height: 12),
              campo(i, 'Taxa de ingressos (%)'),
              const SizedBox(height: 12),
              campo(m, 'Valor mínimo por ingresso (R\$)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    double n(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', '.'));
    final d = {
      'pctaxaproduto': n(p),
      'pctaxaingresso': n(i),
      'vrtaxaminimaingresso': n(m),
    };
    try {
      if (item == null) {
        await repo.criar(d);
      } else {
        await repo.alterar(item['taxapadrao_id'], d);
      }
      await carregar();
    } catch (e) {
      msg('$e', true);
    }
  }

  Widget campo(TextEditingController c, String l) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    decoration: InputDecoration(
      labelText: l,
      border: const OutlineInputBorder(),
    ),
    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
        ? 'Informe um valor válido'
        : null,
  );
  Future<void> ativar(Map<String, dynamic> item) async {
    try {
      await repo.vigorar(item['taxapadrao_id']);
      msg('Versão ${item['nrversao']} agora está vigente.');
      await carregar();
    } catch (e) {
      msg('$e', true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => editar(),
      icon: const Icon(Icons.add),
      label: const Text('Nova versão'),
    ),
    body: Column(
      children: [
        ClubbarPageHeader(
          titulo: 'Taxas padrão',
          subtitulo: 'Regras comerciais versionadas do Clubbar',
          mostrarDadosSessao: false,
          trailing: IconButton(
            onPressed: carregar,
            icon: const Icon(Icons.refresh),
          ),
        ),
        Expanded(
          child: carregando
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: itens.length,
                  itemBuilder: (_, x) {
                    final e = itens[x];
                    final rascunho = e['sittaxapadrao'] == 'RASCUNHO';
                    final vigente = e['sittaxapadrao'] == 'VIGENTE';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.percent,
                          color: vigente ? Colors.green : Colors.grey,
                        ),
                        title: Text('Versão ${e['nrversao']}'),
                        subtitle: Text(
                          'Produtos: ${e['pctaxaproduto']}%  •  Ingressos: ${e['pctaxaingresso']}% '
                          'ou mínimo R\$ ${e['vrtaxaminimaingresso']} por ingresso\n${e['sittaxapadrao']}',
                        ),
                        isThreeLine: true,
                        trailing: rascunho
                            ? Wrap(
                                children: [
                                  IconButton(
                                    onPressed: () => editar(e),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => ativar(e),
                                    tooltip: 'Colocar em vigor',
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              )
                            : Chip(
                                label: Text(vigente ? 'Vigente' : 'Encerrada'),
                                backgroundColor: vigente
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
