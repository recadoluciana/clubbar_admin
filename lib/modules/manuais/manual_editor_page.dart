import 'package:flutter/material.dart';
import '../../core/repositories/manual_repository.dart';

class _EtapaEdicao {
  _EtapaEdicao(Map<String, dynamic> data)
    : titulo = TextEditingController(text: data['titulo'] as String? ?? ''),
      caminho = TextEditingController(text: data['caminho'] as String? ?? ''),
      orientacoes = TextEditingController(
        text: data['orientacoes'] as String? ?? '',
      ),
      resultado = TextEditingController(
        text: data['resultado'] as String? ?? '',
      ),
      aviso = TextEditingController(text: data['aviso'] as String? ?? ''),
      responsavel = data['responsavel'] as String? ?? 'CLUBBAR',
      ambiente = data['ambiente'] as String? ?? 'ADMIN';
  final TextEditingController titulo, caminho, orientacoes, resultado, aviso;
  String responsavel, ambiente;
  Map<String, dynamic> toJson() => {
    'titulo': titulo.text.trim(),
    'caminho': caminho.text.trim(),
    'orientacoes': orientacoes.text.trim(),
    'resultado': resultado.text.trim(),
    'aviso': aviso.text.trim(),
    'responsavel': responsavel,
    'ambiente': ambiente,
  };
  void dispose() {
    for (final c in [titulo, caminho, orientacoes, resultado, aviso]) {
      c.dispose();
    }
  }
}

class ManualEditorPage extends StatefulWidget {
  const ManualEditorPage({super.key, required this.manual});
  final Map<String, dynamic> manual;
  @override
  State<ManualEditorPage> createState() => _ManualEditorPageState();
}

class _ManualEditorPageState extends State<ManualEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _titulo, _descricao;
  final _resumo = TextEditingController();
  late final List<_EtapaEdicao> _etapas;
  final List<_EtapaEdicao> _removidas = [];
  bool _saving = false;
  late final List<String> _publicos;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.manual['titulo'] as String);
    _descricao = TextEditingController(
      text: widget.manual['descricao'] as String,
    );
    _etapas = (widget.manual['etapas'] as List)
        .map((e) => _EtapaEdicao(Map<String, dynamic>.from(e as Map)))
        .toList();
    _publicos = widget.manual['slug'] == 'negociacao-venda'
        ? ['CLUBBAR', 'LEAD']
        : widget.manual['slug'] == 'manual-parceiro'
        ? ['PARCEIRO']
        : ['CLUBBAR'];
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _resumo.dispose();
    for (final e in [..._etapas, ..._removidas]) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ManualRepository().publicar(widget.manual['slug'] as String, {
        'versao_base': widget.manual['versao'],
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim(),
        'resumo_alteracao': _resumo.text.trim(),
        'etapas': _etapas.map((e) => e.toJson()).toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    int min = 3,
    int max = 400,
    int lines = 1,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c,
      enabled: !_saving,
      minLines: lines,
      maxLines: lines == 1 ? 2 : lines + 8,
      maxLength: max,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (v) => optional || (v?.trim().length ?? 0) >= min
          ? null
          : 'Preencha com pelo menos $min caracteres.',
    ),
  );

  void _mover(int index, int delta) => setState(() {
    final item = _etapas.removeAt(index);
    _etapas.insert(index + delta, item);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar e publicar nova versão')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Base: versão ${widget.manual['versao']}. A publicação cria uma nova versão e preserva as anteriores.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
                _campo(_titulo, 'Título do guia', max: 160),
                _campo(
                  _descricao,
                  'Apresentação do guia',
                  min: 10,
                  max: 3000,
                  lines: 3,
                ),
                for (int i = 0; i < _etapas.length; i++) _cardEtapa(i),
                OutlinedButton.icon(
                  onPressed: _saving || _etapas.length >= 80
                      ? null
                      : () => setState(
                          () => _etapas.add(
                            _EtapaEdicao({
                              'responsavel': _publicos.first,
                              'ambiente': _publicos.first == 'PARCEIRO'
                                  ? 'PARTNER'
                                  : 'ADMIN',
                            }),
                          ),
                        ),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar etapa'),
                ),
                const SizedBox(height: 24),
                _campo(
                  _resumo,
                  'O que mudou nesta versão?',
                  min: 5,
                  max: 500,
                  lines: 2,
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _salvar,
                  icon: const Icon(Icons.publish),
                  label: Text(
                    _saving ? 'Publicando...' : 'Publicar nova versão',
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _cardEtapa(int i) {
    final e = _etapas[i];
    return Card(
      key: ObjectKey(e),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Etapa ${i + 1}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mover para cima',
                  onPressed: _saving || i == 0 ? null : () => _mover(i, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Mover para baixo',
                  onPressed: _saving || i == _etapas.length - 1
                      ? null
                      : () => _mover(i, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remover etapa desta nova versão',
                  onPressed: _saving || _etapas.length == 1
                      ? null
                      : () =>
                            setState(() => _removidas.add(_etapas.removeAt(i))),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _campo(e.titulo, 'Título da etapa', max: 140),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: e.responsavel,
                    decoration: const InputDecoration(
                      labelText: 'Quem executa',
                    ),
                    items: _publicos
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              {
                                'CLUBBAR': 'Equipe Clubbar',
                                'LEAD': 'Lead / Interessado',
                                'PARCEIRO': 'Parceiro',
                              }[p]!,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => e.responsavel = v!),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: e.ambiente,
                    decoration: const InputDecoration(labelText: 'Aplicativo'),
                    items: ['SITE', 'ADMIN', 'PARTNER', 'CLIENT']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => e.ambiente = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _campo(e.caminho, 'Caminho no aplicativo'),
            _campo(
              e.orientacoes,
              'Passo a passo (separe parágrafos com uma linha em branco)',
              min: 10,
              max: 12000,
              lines: 5,
            ),
            _campo(e.resultado, 'Resultado esperado', max: 1200, lines: 2),
            _campo(
              e.aviso,
              'Observação importante (opcional)',
              max: 2000,
              lines: 2,
              optional: true,
            ),
          ],
        ),
      ),
    );
  }
}
