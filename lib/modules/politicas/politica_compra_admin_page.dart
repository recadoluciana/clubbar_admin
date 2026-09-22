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

class _PoliticaCompraAdminPageState extends State<PoliticaCompraAdminPage>
    with SingleTickerProviderStateMixin {
  final _repo = PoliticaCompraRepository();
  late final TabController _abas;
  final Map<String, List<Map<String, dynamic>>> _itens = {
    'INGRESSO': [],
    'PRODUTO': [],
  };
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _abas = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  String get _tipoAtual => _abas.index == 0 ? 'INGRESSO' : 'PRODUTO';
  String get _rotuloAtual => _tipoAtual == 'INGRESSO' ? 'ingresso' : 'produto';

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resultados = await Future.wait([
        _repo.listar('INGRESSO'),
        _repo.listar('PRODUTO'),
      ]);
      _itens['INGRESSO'] = resultados[0];
      _itens['PRODUTO'] = resultados[1];
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

  int _valor(Map<String, dynamic>? item, String campo, int padrao) =>
      int.tryParse(item?[campo]?.toString() ?? '') ?? padrao;

  Future<void> _novaVersao() async {
    final tipo = _tipoAtual;
    Map<String, dynamic>? atual;
    for (final item in _itens[tipo]!) {
      if (item['sitpolitica'] == 'VIGENTE') {
        atual = item;
        break;
      }
    }
    final versao = TextEditingController();
    final titulo = TextEditingController(
      text:
          atual?['titulo']?.toString() ??
          'Política de compra de ${_rotuloAtual}',
    );
    final dias = TextEditingController(
      text: '${_valor(atual, 'qtd_dias_cancelamento', 7)}',
    );
    final horasCancelamento = TextEditingController(
      text: '${_valor(atual, 'qtd_horas_antecedencia_cancelamento', 48)}',
    );
    final alteracoes = TextEditingController(
      text: '${_valor(atual, 'qtd_alteracoes_participante', 1)}',
    );
    final horasAlteracao = TextEditingController(
      text: '${_valor(atual, 'qtd_horas_antecedencia_alteracao', 24)}',
    );
    final form = GlobalKey<FormState>();
    final criar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova versão — política de ${_rotuloAtual}'),
        content: SizedBox(
          width: 620,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _campo(
                    versao,
                    'Nova versão *',
                    'Ex.: 1.1',
                    obrigatorio: true,
                  ),
                  const SizedBox(height: 12),
                  _campo(titulo, 'Título *', null, obrigatorio: true),
                  const SizedBox(height: 12),
                  _campo(
                    dias,
                    'Dias corridos para cancelamento *',
                    null,
                    numero: true,
                  ),
                  if (tipo == 'INGRESSO') ...[
                    const SizedBox(height: 12),
                    _campo(
                      horasCancelamento,
                      'Horas de antecedência para cancelamento *',
                      null,
                      numero: true,
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      alteracoes,
                      'Quantidade máxima de alterações de participante *',
                      null,
                      numero: true,
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      horasAlteracao,
                      'Horas de antecedência para alterar participante *',
                      null,
                      numero: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'A versão será criada como RASCUNHO. Revise-a e use “Colocar vigente” quando desejar substituir a política atual.',
                    style: TextStyle(color: Colors.blue.shade800, height: 1.35),
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
            icon: const Icon(Icons.save_outlined),
            label: const Text('Criar rascunho'),
          ),
        ],
      ),
    );
    if (criar != true) return;
    try {
      await _repo.criar({
        'versao': versao.text.trim(),
        'titulo': titulo.text.trim(),
        'tipopolitica': tipo,
        'qtd_dias_cancelamento': int.parse(dias.text.trim()),
        if (tipo == 'INGRESSO') ...{
          'qtd_horas_antecedencia_cancelamento': int.parse(
            horasCancelamento.text.trim(),
          ),
          'qtd_alteracoes_participante': int.parse(alteracoes.text.trim()),
          'qtd_horas_antecedencia_alteracao': int.parse(
            horasAlteracao.text.trim(),
          ),
        },
      });
      if (mounted) _mensagem('Rascunho criado. Ele ainda não está vigente.');
      await _carregar();
    } catch (e) {
      if (mounted) _mensagem('$e', erro: true);
    }
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    String? hint, {
    bool obrigatorio = false,
    bool numero = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: numero ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
    validator: (valor) {
      if ((obrigatorio || numero) && (valor == null || valor.trim().isEmpty))
        return 'Informe este campo';
      if (numero && int.tryParse(valor!.trim()) == null)
        return 'Informe um número inteiro';
      return null;
    },
  );

  Future<void> _vigenciar(Map<String, dynamic> item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Colocar política vigente?'),
        content: Text(
          'A versão ${item['versao']} passará a valer para compras de ${_rotuloAtual}. A versão atual será encerrada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Colocar vigente'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repo.vigenciar(int.parse(item['politicacompra_id'].toString()));
      if (mounted) _mensagem('Política colocada em vigência.');
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
          titulo: 'Políticas de compra',
          subtitulo: 'Versões gerais do Clubbar para ingressos e produtos',
          mostrarDadosSessao: false,
          trailing: IconButton(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _abas,
            labelColor: Colors.green,
            tabs: const [
              Tab(
                icon: Icon(Icons.confirmation_number_outlined),
                text: 'Política de compra de ingresso',
              ),
              Tab(
                icon: Icon(Icons.shopping_bag_outlined),
                text: 'Política de compra de produto',
              ),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _abas,
                  children: [_lista('INGRESSO'), _lista('PRODUTO')],
                ),
        ),
      ],
    ),
  );

  Widget _lista(String tipo) {
    final itens = _itens[tipo] ?? [];
    if (itens.isEmpty)
      return const Center(child: Text('Nenhuma versão cadastrada.'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = itens[index];
        final vigente = item['sitpolitica'] == 'VIGENTE';
        final rascunho = item['sitpolitica'] == 'RASCUNHO';
        return Card(
          child: ExpansionTile(
            leading: Icon(
              Icons.policy_rounded,
              color: vigente
                  ? Colors.green
                  : rascunho
                  ? Colors.orange
                  : Colors.grey,
            ),
            title: Text(
              '${item['titulo']} • versão ${item['versao']}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(item['sitpolitica']?.toString() ?? ''),
            trailing: vigente ? const Chip(label: Text('Versão atual')) : null,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _parametros(item, tipo),
                    const SizedBox(height: 14),
                    SelectableText(
                      item['conteudo']?.toString() ?? '',
                      style: const TextStyle(height: 1.45),
                    ),
                    if (rascunho) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () => _vigenciar(item),
                          icon: const Icon(Icons.publish_rounded),
                          label: const Text('Colocar vigente'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _parametros(Map<String, dynamic> item, String tipo) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      Chip(
        label: Text('${item['qtd_dias_cancelamento']} dias para cancelamento'),
      ),
      if (tipo == 'INGRESSO') ...[
        Chip(
          label: Text(
            '${item['qtd_horas_antecedencia_cancelamento']} h de antecedência para cancelar',
          ),
        ),
        Chip(
          label: Text(
            '${item['qtd_alteracoes_participante']} alteração(ões) de participante',
          ),
        ),
        Chip(
          label: Text(
            '${item['qtd_horas_antecedencia_alteracao']} h para alterar participante',
          ),
        ),
      ],
    ],
  );
}
