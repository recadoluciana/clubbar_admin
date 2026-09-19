import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/superadmin_repository.dart';
import '../../core/theme/clubbar_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_card.dart';
import '../../core/widgets/clubbar_page_header.dart';

String _texto(dynamic valor) => valor?.toString().trim() ?? '';
String _documentoParceiro(dynamic valor) {
  final n = ClubbarFormatters.somenteNumeros(_texto(valor));
  if (n.length == 11) {
    return 'CPF: ${ClubbarFormatters.cpf(n)}';
  }
  if (n.length == 14) {
    return 'CNPJ: ${ClubbarFormatters.cnpj(n)}';
  }
  return 'CPF/CNPJ: ${n.isEmpty ? 'Não informado' : n}';
}

int _inteiro(dynamic valor) =>
    valor is num ? valor.toInt() : int.tryParse('$valor') ?? 0;
double _decimal(dynamic valor) =>
    valor is num ? valor.toDouble() : double.tryParse('$valor') ?? 0;
Color _corCargo(dynamic cargo) => switch (_texto(cargo).toUpperCase()) {
  'SUPERADMIN' => Colors.deepPurple,
  'ADMIN' => Colors.blue,
  'MANAGER' => Colors.deepOrange,
  'CASHIER' => Colors.green,
  'BARMAN' => Colors.amber.shade800,
  'WAITER' => Colors.teal,
  'TICKETMAN' => Colors.brown,
  'TOTEM' => Colors.cyan.shade800,
  _ => Colors.blueGrey,
};

class ParceirosAdminPage extends StatefulWidget {
  const ParceirosAdminPage({super.key});

  @override
  State<ParceirosAdminPage> createState() => _ParceirosAdminPageState();
}

class _ParceirosAdminPageState extends State<ParceirosAdminPage> {
  final _repo = SuperAdminRepository();
  final _busca = TextEditingController();
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final itens = await _repo.listarOrganizacoes();
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    final busca = _busca.text.trim().toLowerCase();
    if (busca.isEmpty) return _itens;
    return _itens
        .where(
          (item) => item.values.any(
            (valor) => _texto(valor).toLowerCase().contains(busca),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => _EstruturaModulo(
    titulo: 'Empresas Parceiras',
    subtitulo: _carregando
        ? 'Carregando empresas...'
        : '${_itens.length} empresas parceiras',
    icone: Icons.business_rounded,
    onAtualizar: _carregar,
    child: _carregando
        ? const Center(
            child: CircularProgressIndicator(color: ClubbarColors.ambar),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CampoBusca(
                controller: _busca,
                dica: 'Buscar empresa, CPF, CNPJ ou e-mail',
                onChanged: (_) => setState(() {}),
                comBorda: true,
              ),
              const SizedBox(height: 14),
              ..._filtrados.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClubbarCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TituloStatus(
                          titulo: _texto(item['nmorganizacao']),
                          status: _texto(item['sitorganizacao']),
                          icone: Icons.business_rounded,
                        ),
                        const Divider(height: 24),
                        Text(
                          _texto(item['rzsocialorganizacao']),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        if ((item['documentos_estabelecimentos'] as List? ?? [])
                            .isEmpty)
                          const Text('CPF/CNPJ: Não informado')
                        else
                          for (final documento
                              in item['documentos_estabelecimentos'] as List)
                            Text(
                              '${_documentoParceiro(documento['cpfcnpj'])} — ${_texto(documento['estabelecimento'])}',
                            ),
                        Text('E-mail: ${_texto(item['emailorganizacao'])}'),
                        Text(
                          'Telefone: ${ClubbarFormatters.telefone(_texto(item['telorganizacao']))}',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(
                              '${_inteiro(item['quantidade_lojas'])} estabelecimentos',
                              Icons.storefront_rounded,
                              cor: Colors.blue,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EstabelecimentosAdminPage(
                                    organizacaoId: _inteiro(
                                      item['organizacao_id'],
                                    ),
                                    nomeOrganizacao: _texto(
                                      item['nmorganizacao'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _Pill(
                              '${_inteiro(item['quantidade_usuarios'])} usuários',
                              Icons.people_alt_rounded,
                              cor: Colors.deepPurple,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UsuariosAdminPage(
                                    organizacaoId: _inteiro(
                                      item['organizacao_id'],
                                    ),
                                    nomeOrganizacao: _texto(
                                      item['nmorganizacao'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_filtrados.isEmpty)
                const _Vazio('Nenhuma empresa encontrada.'),
            ],
          ),
  );
}

class EstabelecimentosAdminPage extends StatefulWidget {
  final int? organizacaoId;
  final String? nomeOrganizacao;
  const EstabelecimentosAdminPage({
    super.key,
    this.organizacaoId,
    this.nomeOrganizacao,
  });
  @override
  State<EstabelecimentosAdminPage> createState() =>
      _EstabelecimentosAdminPageState();
}

class _EstabelecimentosAdminPageState extends State<EstabelecimentosAdminPage> {
  final _repo = SuperAdminRepository();
  final _busca = TextEditingController();
  List<Map<String, dynamic>> _lojas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    setState(() => _carregando = true);
    try {
      if (widget.organizacaoId != null) {
        final lojas = await _repo.listarLojas(widget.organizacaoId!);
        if (mounted) {
          setState(
            () => _lojas = lojas
                .map(
                  (loja) => <String, dynamic>{
                    ...loja,
                    'nmorganizacao': widget.nomeOrganizacao ?? '',
                  },
                )
                .toList(),
          );
        }
        return;
      }
      final organizacoes = await _repo.listarOrganizacoes();
      final grupos = await Future.wait(
        organizacoes.map((organizacao) async {
          final lojas = await _repo.listarLojas(
            _inteiro(organizacao['organizacao_id']),
          );
          return lojas
              .map(
                (loja) => <String, dynamic>{
                  ...loja,
                  'nmorganizacao': _texto(organizacao['nmorganizacao']),
                },
              )
              .toList();
        }),
      );
      _lojas = grupos.expand((lojas) => lojas).toList()
        ..sort((a, b) {
          final organizacao = _texto(
            a['nmorganizacao'],
          ).toLowerCase().compareTo(_texto(b['nmorganizacao']).toLowerCase());
          return organizacao != 0
              ? organizacao
              : _texto(
                  a['nmloja'],
                ).toLowerCase().compareTo(_texto(b['nmloja']).toLowerCase());
        });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    final busca = _busca.text.trim().toLowerCase();
    if (busca.isEmpty) return _lojas;
    return _lojas
        .where(
          (item) =>
              item.values.any((v) => _texto(v).toLowerCase().contains(busca)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => _EstruturaModulo(
    titulo: 'Estabelecimentos',
    subtitulo: _carregando
        ? 'Carregando estabelecimentos...'
        : '${_lojas.length} estabelecimentos',
    estiloTitulo: const TextStyle(color: ClubbarColors.info),
    icone: Icons.storefront_rounded,
    onAtualizar: _inicializar,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _CampoBusca(
            controller: _busca,
            dica: 'Buscar organização ou estabelecimento',
            onChanged: (_) => setState(() {}),
            comBorda: true,
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(
                  child: CircularProgressIndicator(color: ClubbarColors.ambar),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  children: [
                    ..._filtradas.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClubbarCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TituloStatus(
                                titulo:
                                    '${_texto(item['nmorganizacao'])} — ${_texto(item['nmloja'])}',
                                status: _texto(item['sitloja']),
                                icone: Icons.store_rounded,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                [
                                      [
                                            _texto(item['endloja']),
                                            _texto(item['nrendeloja']),
                                          ]
                                          .where((valor) => valor.isNotEmpty)
                                          .join(', '),
                                      _texto(item['dsbairroloja']),
                                    ]
                                    .where((valor) => valor.isNotEmpty)
                                    .join(' • '),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Telefone: ${ClubbarFormatters.telefone(_texto(item['nrtelloja']))}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_filtradas.isEmpty)
                      const _Vazio('Nenhum estabelecimento encontrado.'),
                  ],
                ),
        ),
      ],
    ),
  );
}

class UsuariosAdminPage extends StatefulWidget {
  final int organizacaoId;
  final String nomeOrganizacao;
  const UsuariosAdminPage({
    super.key,
    required this.organizacaoId,
    required this.nomeOrganizacao,
  });
  @override
  State<UsuariosAdminPage> createState() => _UsuariosAdminPageState();
}

class _UsuariosAdminPageState extends State<UsuariosAdminPage> {
  final _repo = SuperAdminRepository();
  final _busca = TextEditingController();
  List<Map<String, dynamic>> _usuarios = [];
  bool _carregando = true;
  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    setState(() => _carregando = true);
    try {
      final usuarios = await _repo.listarUsuarios(widget.organizacaoId);
      if (mounted) setState(() => _usuarios = usuarios);
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    final busca = _busca.text.trim().toLowerCase();
    if (busca.isEmpty) return _usuarios;
    return _usuarios
        .where(
          (item) =>
              item.values.any((v) => _texto(v).toLowerCase().contains(busca)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => _EstruturaModulo(
    titulo: widget.nomeOrganizacao,
    estiloTitulo: const TextStyle(color: ClubbarColors.info),
    subtitulo: _carregando
        ? 'Carregando usuários da empresa...'
        : '${_usuarios.length} ${_usuarios.length == 1 ? 'usuário' : 'usuários'} na empresa',
    icone: Icons.manage_accounts_rounded,
    onAtualizar: _inicializar,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _CampoBusca(
            controller: _busca,
            dica: 'Buscar usuário, e-mail, cargo ou estabelecimento',
            onChanged: (_) => setState(() {}),
            comBorda: true,
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(
                  child: CircularProgressIndicator(color: ClubbarColors.ambar),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  children: [
                    ..._filtrados.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClubbarCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TituloStatus(
                                titulo: _texto(item['nmusuario']),
                                status: _texto(item['situsuario']),
                                icone: Icons.person_rounded,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _texto(item['emailuser']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(
                                    _texto(item['dscargo']),
                                    Icons.badge_outlined,
                                    cor: _corCargo(item['dscargo']),
                                  ),
                                  if (_texto(item['nmloja']).isNotEmpty)
                                    _Pill(
                                      _texto(item['nmloja']),
                                      Icons.storefront_rounded,
                                    ),
                                  if (_texto(item['nmloja']).isEmpty)
                                    const _Pill(
                                      'Sem estabelecimento',
                                      Icons.public_rounded,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_filtrados.isEmpty)
                      const _Vazio('Nenhum usuário encontrado.'),
                  ],
                ),
        ),
      ],
    ),
  );
}

class VendasHojeAdminPage extends StatelessWidget {
  const VendasHojeAdminPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _MovimentoHojePage(focoFaturamento: false);
}

class FaturamentoHojeAdminPage extends StatelessWidget {
  const FaturamentoHojeAdminPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _MovimentoHojePage(focoFaturamento: true);
}

class _MovimentoHojePage extends StatefulWidget {
  final bool focoFaturamento;
  const _MovimentoHojePage({required this.focoFaturamento});
  @override
  State<_MovimentoHojePage> createState() => _MovimentoHojePageState();
}

class _MovimentoHojePageState extends State<_MovimentoHojePage> {
  final _repo = SuperAdminRepository();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  Map<String, dynamic> _dados = {};
  List<Map<String, dynamic>> _organizacoes = [];
  int? _organizacaoId, _lojaId;
  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now();
  bool _carregando = true;
  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resultados = await Future.wait([
        _repo.vendasHoje(dataInicio: _dataInicio, dataFim: _dataFim),
        _repo.listarOrganizacoes(),
      ]);
      _dados = Map<String, dynamic>.from(resultados[0] as Map);
      _organizacoes = (resultados[1] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _selecionarData() async {
    final periodo = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione um período de até 30 dias',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (periodo == null || !mounted) return;
    if (periodo.duration.inDays >= 30) {
      AppSnackBar.aviso(context, 'Selecione um período de no máximo 30 dias.');
      return;
    }
    setState(() {
      _dataInicio = periodo.start;
      _dataFim = periodo.end;
      _organizacaoId = null;
      _lojaId = null;
    });
    await _carregar();
  }

  List<Map<String, dynamic>> get _detalhes =>
      ((_dados['detalhes'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where(
            (e) =>
                (_organizacaoId == null ||
                    _inteiro(e['organizacao_id']) == _organizacaoId) &&
                (_lojaId == null || _inteiro(e['loja_id']) == _lojaId),
          )
          .toList();
  List<Map<String, dynamic>> get _lojasFiltro {
    final vistos = <int>{};
    return (((_dados['detalhes'] as List?) ?? const []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ))
        .where(
          (e) =>
              _organizacaoId == null ||
              _inteiro(e['organizacao_id']) == _organizacaoId,
        )
        .where((e) => vistos.add(_inteiro(e['loja_id'])))
        .toList();
  }

  int get _vendas =>
      _detalhes.fold(0, (s, e) => s + _inteiro(e['quantidade_vendas']));
  double get _taxasProdutos =>
      _detalhes.fold(0, (s, e) => s + _decimal(e['taxa_produtos']));
  double get _taxasIngressos =>
      _detalhes.fold(0, (s, e) => s + _decimal(e['taxa_ingressos']));
  String get _periodoSelecionado {
    final formato = DateFormat('dd/MM/yyyy', 'pt_BR');
    if (DateUtils.isSameDay(_dataInicio, _dataFim)) {
      return formato.format(_dataInicio);
    }
    return '${formato.format(_dataInicio)} a ${formato.format(_dataFim)}';
  }

  @override
  Widget build(BuildContext context) => _EstruturaModulo(
    titulo: widget.focoFaturamento ? 'Faturamento Clubbar' : 'Vendas Clubbar',
    subtitulo: _periodoSelecionado,
    icone: widget.focoFaturamento
        ? Icons.paid_rounded
        : Icons.shopping_cart_checkout_rounded,
    onAtualizar: _carregar,
    onCalendario: _selecionarData,
    child: _carregando
        ? const Center(
            child: CircularProgressIndicator(color: ClubbarColors.ambar),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SeletorOrganizacao(
                itens: _organizacoes,
                valor: _organizacaoId,
                permitirTodos: true,
                onChanged: (id) => setState(() {
                  _organizacaoId = id;
                  _lojaId = null;
                }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: _lojaId,
                decoration: const InputDecoration(
                  labelText: 'Estabelecimento',
                  prefixIcon: Icon(Icons.storefront_rounded),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos os estabelecimentos'),
                  ),
                  ..._lojasFiltro.map(
                    (e) => DropdownMenuItem<int?>(
                      value: _inteiro(e['loja_id']),
                      child: Text(_texto(e['nmloja'])),
                    ),
                  ),
                ],
                onChanged: (id) => setState(() => _lojaId = id),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Resumo(
                      titulo: 'Qtde. Vendas',
                      valor: '$_vendas',
                      icone: Icons.receipt_long_rounded,
                      cor: ClubbarColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Resumo(
                      titulo: 'Total faturado',
                      valor: _moeda.format(_taxasProdutos + _taxasIngressos),
                      icone: Icons.paid_rounded,
                      cor: ClubbarColors.sucesso,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Resumo(
                      titulo: 'Taxa de Produtos',
                      valor: _moeda.format(_taxasProdutos),
                      icone: Icons.shopping_bag_rounded,
                      cor: ClubbarColors.ambarEscuro,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Resumo(
                      titulo: 'Taxa de Ingressos',
                      valor: _moeda.format(_taxasIngressos),
                      icone: Icons.confirmation_number_rounded,
                      cor: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._detalhes.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClubbarCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _texto(item['nmorganizacao']),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _texto(item['nmloja']),
                          style: const TextStyle(
                            color: ClubbarColors.textoSecundario,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Divider(height: 22),
                        _LinhaValor(
                          'Vendas realizadas',
                          '${_inteiro(item['quantidade_vendas'])}',
                        ),
                        _LinhaValor(
                          'Taxas de produtos',
                          _moeda.format(_decimal(item['taxa_produtos'])),
                        ),
                        _LinhaValor(
                          'Taxas de ingressos',
                          _moeda.format(_decimal(item['taxa_ingressos'])),
                        ),
                        const Divider(height: 18),
                        _LinhaValor(
                          'Faturamento Clubbar',
                          _moeda.format(_decimal(item['faturamento_total'])),
                          destaque: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_detalhes.isEmpty)
                const _Vazio('Nenhuma venda paga encontrada nesta data.'),
            ],
          ),
  );
}

class _EstruturaModulo extends StatelessWidget {
  final String titulo, subtitulo;
  final TextStyle? estiloTitulo;
  final IconData icone;
  final Future<void> Function() onAtualizar;
  final VoidCallback? onCalendario;
  final Widget child;
  const _EstruturaModulo({
    required this.titulo,
    this.estiloTitulo,
    required this.subtitulo,
    required this.icone,
    required this.onAtualizar,
    this.onCalendario,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ClubbarColors.fundo,
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    body: SafeArea(
      child: Column(
        children: [
          ClubbarPageHeader(
            titulo: titulo,
            subtitulo: subtitulo,
            estiloTitulo: estiloTitulo,
            icone: icone,
            mostrarDadosSessao: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCalendario != null)
                  IconButton(
                    tooltip: 'Selecionar data',
                    onPressed: onCalendario,
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: onAtualizar,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _CampoBusca extends StatelessWidget {
  final TextEditingController controller;
  final String dica;
  final ValueChanged<String> onChanged;
  final bool comBorda;
  const _CampoBusca({
    required this.controller,
    required this.dica,
    required this.onChanged,
    this.comBorda = false,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: dica,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
            ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: comBorda
            ? const BorderSide(color: ClubbarColors.borda, width: 1)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: comBorda
            ? const BorderSide(color: ClubbarColors.borda, width: 1)
            : BorderSide.none,
      ),
    ),
  );
}

class _SeletorOrganizacao extends StatelessWidget {
  final List<Map<String, dynamic>> itens;
  final int? valor;
  final ValueChanged<int?> onChanged;
  final bool permitirTodos;
  const _SeletorOrganizacao({
    required this.itens,
    required this.valor,
    required this.onChanged,
    this.permitirTodos = false,
  });
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int?>(
    initialValue: valor,
    isExpanded: true,
    style: const TextStyle(color: ClubbarColors.textoPrincipal),
    decoration: const InputDecoration(
      labelText: 'Empresa',
      prefixIcon: Icon(Icons.business_rounded),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: ClubbarColors.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ClubbarColors.borda),
      ),
    ),
    items: [
      if (permitirTodos)
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Todas as empresas'),
        ),
      ...itens.map(
        (e) => DropdownMenuItem<int?>(
          value: _inteiro(e['organizacao_id']),
          child: Text(
            _texto(e['nmorganizacao']),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
    onChanged: onChanged,
  );
}

class _TituloStatus extends StatelessWidget {
  final String titulo, status;
  final IconData icone;
  const _TituloStatus({
    required this.titulo,
    required this.status,
    required this.icone,
  });
  @override
  Widget build(BuildContext context) {
    final ativo = {'ATIVA', 'ATIVO'}.contains(status.toUpperCase());
    final cor = ativo ? ClubbarColors.sucesso : ClubbarColors.erro;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: ClubbarColors.ambarClaro,
          foregroundColor: Colors.black,
          child: Icon(icone),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String texto;
  final IconData icone;
  final Color? cor;
  final VoidCallback? onTap;
  const _Pill(this.texto, this.icone, {this.cor, this.onTap});
  @override
  Widget build(BuildContext context) {
    final corBadge = cor;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: corBadge?.withValues(alpha: 0.14) ?? ClubbarColors.ambarClaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 15, color: corBadge),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: corBadge,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return badge;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: badge,
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final String titulo, valor;
  final IconData icone;
  final Color cor;
  const _Resumo({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });
  @override
  Widget build(BuildContext context) => ClubbarCard(
    padding: const EdgeInsets.all(13),
    child: Column(
      children: [
        Icon(icone, color: cor, size: 26),
        const SizedBox(height: 7),
        FittedBox(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: ClubbarColors.textoSecundario,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LinhaValor extends StatelessWidget {
  final String titulo, valor;
  final bool destaque;
  const _LinhaValor(this.titulo, this.valor, {this.destaque = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              fontWeight: destaque ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
            color: destaque ? ClubbarColors.sucesso : null,
          ),
        ),
      ],
    ),
  );
}

class _Vazio extends StatelessWidget {
  final String texto;
  const _Vazio(this.texto);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(30),
    child: Center(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: ClubbarColors.textoSecundario),
      ),
    ),
  );
}
