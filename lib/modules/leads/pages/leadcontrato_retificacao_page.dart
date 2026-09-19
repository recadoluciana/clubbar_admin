import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadContratoRetificacaoPage extends StatefulWidget {
  final LeadParceiro lead;
  final LeadEstabelecimento estabelecimento;

  const LeadContratoRetificacaoPage({
    super.key,
    required this.lead,
    required this.estabelecimento,
  });

  @override
  State<LeadContratoRetificacaoPage> createState() =>
      _LeadContratoRetificacaoPageState();
}

class _LeadContratoRetificacaoPageState
    extends State<LeadContratoRetificacaoPage> {
  final _repo = LeadParceiroRepository();
  final _form = GlobalKey<FormState>();
  late final TextEditingController _motivo;
  late final TextEditingController _documento;
  late final TextEditingController _nome;
  late final TextEditingController _cep;
  late final TextEditingController _endereco;
  late final TextEditingController _numero;
  late final TextEditingController _bairro;
  late final TextEditingController _complemento;
  late final TextEditingController _taxaProdutos;
  late final TextEditingController _taxaIngressos;
  late final TextEditingController _taxaMinima;
  List<Map<String, dynamic>> _contratos = [];
  List<Map<String, dynamic>> _estados = [];
  List<Map<String, dynamic>> _cidades = [];
  int? _estadoId;
  int? _cidadeId;
  bool _mesmaParte = false;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final e = widget.estabelecimento;
    _motivo = TextEditingController();
    _documento = TextEditingController(
      text: ClubbarFormatters.cpfCnpj(e.cpfCnpj),
    );
    _nome = TextEditingController(text: e.nome);
    _cep = TextEditingController(text: ClubbarFormatters.cep(e.cep));
    _endereco = TextEditingController(text: e.endereco ?? '');
    _numero = TextEditingController(text: e.numero ?? '');
    _bairro = TextEditingController(text: e.bairro ?? '');
    _complemento = TextEditingController(text: e.complemento ?? '');
    _taxaProdutos = TextEditingController(
      text: e.taxaProdutos.toStringAsFixed(2),
    );
    _taxaIngressos = TextEditingController(
      text: e.taxaIngressos.toStringAsFixed(2),
    );
    _taxaMinima = TextEditingController(text: '0.00');
    _estadoId = e.estadoId > 0 ? e.estadoId : null;
    _cidadeId = e.cidadeId > 0 ? e.cidadeId : null;
    _carregar();
  }

  @override
  void dispose() {
    for (final c in [
      _motivo,
      _documento,
      _nome,
      _cep,
      _endereco,
      _numero,
      _bairro,
      _complemento,
      _taxaProdutos,
      _taxaIngressos,
      _taxaMinima,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _id(Map<String, dynamic> item, String chave) =>
      int.tryParse('${item[chave]}');
  String _numeroTexto(dynamic valor) =>
      (double.tryParse('$valor') ?? 0).toStringAsFixed(2);
  String _mensagem(Object erro) =>
      erro.toString().replaceFirst('Exception: ', '');

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final contratos = await _repo.listarContratos(widget.estabelecimento.id);
      final estados = await _repo.listarEstados();
      final base = contratos.cast<Map<String, dynamic>?>().firstWhere(
        (c) => c?['status'] == 'ACEITO',
        orElse: () => null,
      );
      final estadoId = base == null
          ? _estadoId
          : _id(base, 'estado_id_contratante');
      final cidades = estadoId == null
          ? <Map<String, dynamic>>[]
          : await _repo.listarCidades(estadoId);
      if (!mounted) return;
      setState(() {
        _contratos = contratos;
        _estados = estados;
        _estadoId = estadoId;
        _cidades = cidades;
        _cidadeId = base == null
            ? _cidadeId
            : _id(base, 'cidade_id_contratante');
        if (base != null) {
          _documento.text = ClubbarFormatters.cpfCnpj(
            '${base['cpfcnpjcontratante'] ?? ''}',
          );
          _nome.text = '${base['nmrazaosocial'] ?? ''}';
          _cep.text = ClubbarFormatters.cep('${base['cepcontratante'] ?? ''}');
          _endereco.text = '${base['enderecocontratante'] ?? ''}';
          _numero.text = '${base['numerocontratante'] ?? ''}';
          _bairro.text = '${base['bairrocontratante'] ?? ''}';
          _complemento.text = '${base['complementocontratante'] ?? ''}';
          _taxaProdutos.text = _numeroTexto(base['vrtaxaprod']);
          _taxaIngressos.text = _numeroTexto(base['vrtaxaing']);
          _taxaMinima.text = _numeroTexto(base['vrtaxaminimaingresso']);
        }
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = _mensagem(e);
          _carregando = false;
        });
      }
    }
  }

  Future<void> _mudarEstado(int? id) async {
    setState(() {
      _estadoId = id;
      _cidadeId = null;
      _cidades = [];
    });
    if (id == null) return;
    try {
      final cidades = await _repo.listarCidades(id);
      if (mounted && _estadoId == id) setState(() => _cidades = cidades);
    } catch (e) {
      if (mounted) AppSnackBar.erro(context, _mensagem(e));
    }
  }

  Map<String, dynamic> _dados() {
    String taxa(TextEditingController c) => c.text.trim().replaceAll(',', '.');
    return {
      'motivo': _motivo.text.trim(),
      'cpfcnpj': _documento.text.replaceAll(RegExp(r'\D'), ''),
      'nmrazaosocial': _nome.text.trim(),
      'cep': _cep.text.replaceAll(RegExp(r'\D'), ''),
      'endereco': _endereco.text.trim(),
      'numero': _numero.text.trim(),
      'bairro': _bairro.text.trim(),
      'complemento': _complemento.text.trim().isEmpty
          ? null
          : _complemento.text.trim(),
      'estado_id': _estadoId,
      'cidade_id': _cidadeId,
      'vrtaxaprod': taxa(_taxaProdutos),
      'vrtaxaing': taxa(_taxaIngressos),
      'vrtaxaminimaingresso': taxa(_taxaMinima),
      'confirma_mesma_parte': _mesmaParte,
    };
  }

  Future<void> _enviar() async {
    if (_salvando || !_form.currentState!.validate()) return;
    if (_estadoId == null || _cidadeId == null) {
      AppSnackBar.aviso(context, 'Selecione estado e cidade.');
      return;
    }
    final dados = _dados();
    setState(() => _salvando = true);
    try {
      final previa = await _repo.previsualizarRetificacao(
        widget.estabelecimento.id,
        dados,
      );
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Revisar termo de retificação'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(child: SelectableText(previa)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar para assinatura'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      await _repo.criarRetificacao(widget.estabelecimento.id, dados);
      if (!mounted) return;
      AppSnackBar.sucesso(
        context,
        'Retificação enviada para assinatura do lead.',
      );
      await _carregar();
    } catch (e) {
      if (mounted) AppSnackBar.erro(context, _mensagem(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _cancelar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar retificação pendente?'),
        content: const Text(
          'O contrato original e as retificações já assinadas serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar retificação'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repo.cancelarRetificacao(id);
      await _carregar();
    } catch (e) {
      if (mounted) AppSnackBar.erro(context, _mensagem(e));
    }
  }

  Widget _campo(
    String rotulo,
    TextEditingController c, {
    int? minimo,
    TextInputType? tipo,
    int linhas = 1,
    List<TextInputFormatter>? formatadores,
    String? Function(String?)? validador,
  }) => TextFormField(
    controller: c,
    keyboardType: tipo,
    inputFormatters: formatadores,
    maxLines: linhas,
    decoration: InputDecoration(
      labelText: rotulo,
      border: const OutlineInputBorder(),
    ),
    validator:
        validador ??
        (v) =>
            (v ?? '').trim().length < (minimo ?? 1) ? 'Informe $rotulo.' : null,
  );

  @override
  Widget build(BuildContext context) {
    final pendente = _contratos.cast<Map<String, dynamic>?>().firstWhere(
      (c) =>
          c?['tipoinstrumento'] == 'RETIFICACAO' && c?['status'] == 'ENVIADO',
      orElse: () => null,
    );
    final temOriginal = _contratos.any(
      (c) => c['tipoinstrumento'] == 'ORIGINAL' && c['status'] == 'ACEITO',
    );
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: widget.estabelecimento.nome,
            subtitulo: 'Retificação de contrato',
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                ? Center(child: Text(_erro!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'O contrato assinado permanece intacto. O lead deverá ler e assinar o novo termo. As correções passam a valer após o aceite.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      for (final c in _contratos)
                        Card(
                          child: ListTile(
                            title: Text(
                              c['tipoinstrumento'] == 'RETIFICACAO'
                                  ? 'Retificação nº ${c['nrretificacao']}'
                                  : 'Contrato original • versão ${c['versao']}',
                            ),
                            subtitle: Text(
                              'Situação: ${c['status']} • Nº ${c['leadestabelecimentocontrato_id']}',
                            ),
                            trailing: c == pendente
                                ? TextButton(
                                    onPressed: () => _cancelar(
                                      _id(c, 'leadestabelecimentocontrato_id')!,
                                    ),
                                    child: const Text('Cancelar'),
                                  )
                                : null,
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Instrumento contratual'),
                                content: SizedBox(
                                  width: 620,
                                  child: SingleChildScrollView(
                                    child: SelectableText(
                                      '${c['conteudocontrato'] ?? ''}',
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Fechar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (!temOriginal)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'É necessário um contrato original aceito antes de emitir uma retificação.',
                          ),
                        ),
                      if (temOriginal && pendente != null)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Há uma retificação aguardando assinatura. Cancele-a para emitir outra.',
                          ),
                        ),
                      if (temOriginal && pendente == null)
                        Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Dados corrigidos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'Justificativa da retificação',
                                _motivo,
                                minimo: 10,
                                linhas: 2,
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'CPF/CNPJ',
                                _documento,
                                tipo: TextInputType.number,
                                formatadores: const [CpfCnpjInputFormatter()],
                                validador: (valor) {
                                  final tamanho =
                                      ClubbarFormatters.somenteNumeros(
                                        valor,
                                      ).length;
                                  return tamanho == 11 || tamanho == 14
                                      ? null
                                      : 'Informe um CPF ou CNPJ completo.';
                                },
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: _mesmaParte,
                                onChanged: (v) =>
                                    setState(() => _mesmaParte = v ?? false),
                                title: const Text(
                                  'Se o CPF/CNPJ mudou, confirme que continua sendo a mesma parte contratante',
                                ),
                                subtitle: const Text(
                                  'Se for outra pessoa ou empresa, não use retificação: emita um novo contrato após revisão jurídica.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'Nome completo ou razão social',
                                _nome,
                                minimo: 2,
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'CEP',
                                _cep,
                                tipo: TextInputType.number,
                                formatadores: const [CepInputFormatter()],
                                validador: (valor) =>
                                    ClubbarFormatters.somenteNumeros(
                                          valor,
                                        ).length ==
                                        8
                                    ? null
                                    : 'Informe um CEP completo.',
                              ),
                              const SizedBox(height: 12),
                              _campo('Endereço', _endereco),
                              const SizedBox(height: 12),
                              _campo('Número', _numero),
                              const SizedBox(height: 12),
                              _campo('Bairro', _bairro),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _complemento,
                                decoration: const InputDecoration(
                                  labelText: 'Complemento (opcional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                initialValue: _estadoId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(),
                                ),
                                items: _estados
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: _id(e, 'estado_id'),
                                        child: Text(
                                          '${e['sgestado']} - ${e['nmestado']}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _mudarEstado,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                key: ValueKey(_estadoId),
                                initialValue: _cidadeId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Cidade',
                                  border: OutlineInputBorder(),
                                ),
                                items: _cidades
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: _id(e, 'cidade_id'),
                                        child: Text('${e['nmcidade']}'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _cidadeId = v),
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'Taxa de produtos (%)',
                                _taxaProdutos,
                                tipo: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'Taxa de ingressos (%)',
                                _taxaIngressos,
                                tipo: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              _campo(
                                'Valor mínimo cobrado por ingresso (R\$)',
                                _taxaMinima,
                                tipo: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _salvando ? null : _enviar,
                                child: Text(
                                  _salvando
                                      ? 'Enviando...'
                                      : 'Revisar e enviar para assinatura',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
