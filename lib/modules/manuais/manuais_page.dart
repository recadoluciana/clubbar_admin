import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/manual_repository.dart';
import 'manual_editor_page.dart';
import 'manual_pdf_download.dart';

const manualAzul = Color(0xFF162D46);
const manualAmbar = Color(0xFFF4B740);
const nomesPublico = {
  'CLUBBAR': 'Equipe Clubbar',
  'LEAD': 'Lead / Interessado',
  'PARCEIRO': 'Parceiro',
};

String dataManual(dynamic value) {
  final date = DateTime.tryParse('$value');
  return date == null ? '' : DateFormat('dd/MM/yyyy').format(date);
}

class ManuaisPage extends StatefulWidget {
  const ManuaisPage({super.key});
  @override
  State<ManuaisPage> createState() => _ManuaisPageState();
}

class _ManuaisPageState extends State<ManuaisPage> {
  final _repo = ManualRepository();
  List<Map<String, dynamic>> _manuais = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final data = await _repo.listar();
      if (mounted) setState(() => _manuais = data);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F6F9),
    appBar: AppBar(
      title: const Text('Roteiro de Implantação e Manual do Parceiro'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _erro != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_erro!, textAlign: TextAlign.center),
                ),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: manualAzul,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.route_rounded, color: manualAmbar, size: 36),
                        SizedBox(height: 14),
                        Text(
                          'Do primeiro contato à primeira venda.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Escolha o guia para cada momento. Consulte as etapas, acompanhe o fluxo e gere um PDF para compartilhar com a pessoa certa.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_manuais.isEmpty)
                    const Text(
                      'Nenhum manual cadastrado. Execute a carga inicial dos manuais.',
                    ),
                  for (final manual in _manuais)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ManualDetalhePage(
                                  slug: manual['slug'] as String,
                                ),
                              ),
                            );
                            if (mounted) _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      manual['slug'] == 'negociacao-venda'
                                          ? Icons.handshake_outlined
                                          : manual['slug'] ==
                                                'roteiro-implantacao'
                                          ? Icons.checklist_rounded
                                          : Icons.menu_book_rounded,
                                      color: manualAzul,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${manual['titulo']}',
                                        style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${manual['descricao']}',
                                  style: const TextStyle(height: 1.5),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(
                                        '${manual['total_etapas']} etapas',
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        'Versão ${manual['versao']} • ${dataManual(manual['criado_em'])}',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
  );
}

class ManualDetalhePage extends StatefulWidget {
  const ManualDetalhePage({super.key, required this.slug});
  final String slug;
  @override
  State<ManualDetalhePage> createState() => _ManualDetalhePageState();
}

class _ManualDetalhePageState extends State<ManualDetalhePage> {
  final _repo = ManualRepository();
  Map<String, dynamic>? _manual;
  bool _loading = true, _exportando = false;
  String? _erro, _publico;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([int? versao]) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final data = await _repo.consultar(widget.slug, versao);
      if (mounted) setState(() => _manual = data);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mensagem(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _pdf() async {
    setState(() => _exportando = true);
    final versao = _manual!['versao'] as int;
    final publico = _publico;
    try {
      final bytes = await _repo.pdf(widget.slug, versao, publico);
      await salvarManualPdf(
        bytes,
        '${widget.slug}-v$versao${publico == null ? '' : '-${publico.toLowerCase()}'}.pdf',
      );
    } catch (e) {
      _mensagem('$e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _editar() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManualEditorPage(manual: _manual!)),
    );
    if (saved == true && mounted) {
      await _load();
      _mensagem('Nova versão publicada. Histórico preservado.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F6F9),
    appBar: AppBar(
      title: Text(_manual?['titulo']?.toString() ?? 'Manual'),
      actions: [
        IconButton(
          onPressed: _loading ? null : () => _load(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Carregar versão atual',
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _erro != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_erro!),
                FilledButton(
                  onPressed: () => _load(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        : _conteudo(),
  );

  Widget _conteudo() {
    final manual = _manual!;
    final etapas = (manual['etapas'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final filtradas = etapas
        .where(
          (e) =>
              (_publico == null || e['responsavel'] == _publico) &&
              e.values.join(' ').toLowerCase().contains(_busca.toLowerCase()),
        )
        .toList();
    final publics = etapas.map((e) => e['responsavel'] as String).toSet();
    final atual = manual['versao'] == manual['versao_atual'];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${manual['titulo']}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: manualAzul,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${manual['descricao']}',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _exportando ? null : _pdf,
                  icon: _exportando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    _exportando
                        ? 'Gerando PDF...'
                        : 'Gerar PDF${_publico == null ? '' : ' • ${nomesPublico[_publico]}'}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: atual && !_exportando ? _editar : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar e publicar nova versão'),
                ),
                DropdownButton<int>(
                  value: manual['versao'] as int,
                  items: (manual['historico'] as List)
                      .map(
                        (v) => DropdownMenuItem<int>(
                          value: v['versao'] as int,
                          child: Text(
                            'v${v['versao']} • ${dataManual(v['criado_em'])}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _exportando
                      ? null
                      : (v) {
                          if (v != null) _load(v);
                        },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${atual ? 'Versão atual' : 'Versão histórica — somente consulta'}: ${manual['resumo_alteracao']}',
              style: const TextStyle(color: manualAzul),
            ),
            const SizedBox(height: 18),
            if (publics.length > 1)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos os responsáveis'),
                    selected: _publico == null,
                    onSelected: (_) => setState(() => _publico = null),
                  ),
                  for (final p in publics)
                    ChoiceChip(
                      label: Text(nomesPublico[p]!),
                      selected: _publico == p,
                      onSelected: (_) => setState(() => _publico = p),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar no guia',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
            const SizedBox(height: 8),
            const Text(
              'O PDF inclui todas as etapas do público selecionado. A busca filtra somente a consulta na tela.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fluxo de trabalho',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (filtradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhuma etapa encontrada para este filtro.'),
              ),
            for (int i = 0; i < filtradas.length; i++) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: manualAzul,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: manualAmbar,
                      child: Text(
                        '${etapas.indexOf(filtradas[i]) + 1}',
                        style: const TextStyle(color: manualAzul),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${filtradas[i]['titulo']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${nomesPublico[filtradas[i]['responsavel']]} • ${filtradas[i]['ambiente']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < filtradas.length - 1)
                const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_downward, color: manualAzul),
                ),
            ],
            const SizedBox(height: 28),
            const Text(
              'Passo a passo',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final e in filtradas)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${etapas.indexOf(e) + 1}. ${e['titulo']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: manualAzul,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(nomesPublico[e['responsavel']]!)),
                          Chip(label: Text('${e['ambiente']}')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        'Caminho: ${e['caminho']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 28),
                      SelectableText(
                        '${e['orientacoes']}',
                        style: const TextStyle(height: 1.6, fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFFEAF4EC),
                        child: SelectableText(
                          'Resultado esperado: ${e['resultado']}',
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                      if ('${e['aviso'] ?? ''}'.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: SelectableText(
                            'Atenção: ${e['aviso']}',
                            style: const TextStyle(
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
