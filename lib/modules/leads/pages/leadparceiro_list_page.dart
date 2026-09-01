import 'package:flutter/material.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_card.dart';
import '../../../core/widgets/clubbar_page_header.dart';

import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

import 'leadparceiro_form_page.dart';
import 'leadparceiro_converter_page.dart';
import 'leadatendimento_page.dart';
import 'leadestabelecimento_form_page.dart';

class LeadParceiroListPage extends StatefulWidget {
  const LeadParceiroListPage({super.key});

  @override
  State<LeadParceiroListPage> createState() => _LeadParceiroListPageState();
}

class _LeadParceiroListPageState extends State<LeadParceiroListPage> {
  final _repository = LeadParceiroRepository();
  final _buscaController = TextEditingController();

  bool _carregando = true;
  String? _erro;

  List<LeadParceiro> _leads = [];
  List<LeadParceiro> _leadsFiltrados = [];

  String _statusSelecionado = 'TODOS';
  String _tipoSelecionado = 'TODOS';

  static const _status = [
    'TODOS',
    'NOVO',
    'CONTATADO',
    'NEGOCIANDO',
    'ACEITOU_PARCERIA',
    'CONVERTIDO',
    'RECUSOU_PARCERIA',
  ];

  static const _tipos = [
    'TODOS',
    'BAR',
    'CASA_NOTURNA',
    'PRODUTOR_EVENTOS',
    'CASA_EVENTOS',
  ];
  IconData _iconeStatus(String status) {
    switch (status) {
      case 'CONTATADO':
        return Icons.phone_in_talk_rounded;

      case 'NEGOCIANDO':
        return Icons.handshake_rounded;
      case 'ACEITOU_PARCERIA':
        return Icons.task_alt_rounded;

      case 'CONVERTIDO':
        return Icons.verified_rounded;

      case 'RECUSOU_PARCERIA':
        return Icons.cancel_outlined;

      case 'NOVO':
      default:
        return Icons.fiber_new_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _repository.listar();
      if (!mounted) return;

      setState(() {
        _leads = lista;
        _aplicarFiltros();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      final mensagem = e.toString().replaceFirst('Exception: ', '').trim();

      setState(() {
        _carregando = false;
        _erro = mensagem;
      });

      AppSnackBar.erro(context, mensagem);
    }
  }

  void _aplicarFiltros() {
    final busca = _buscaController.text.trim().toLowerCase();

    _leadsFiltrados = _leads.where((lead) {
      final atendeBusca =
          busca.isEmpty ||
          lead.nmresponsavel.toLowerCase().contains(busca) ||
          lead.nmestabelecimento.toLowerCase().contains(busca) ||
          lead.telefone.toLowerCase().contains(busca) ||
          lead.email.toLowerCase().contains(busca) ||
          lead.nmcidade.toLowerCase().contains(busca);

      final atendeStatus =
          _statusSelecionado == 'TODOS' || lead.status == _statusSelecionado;

      final atendeTipo =
          _tipoSelecionado == 'TODOS' || lead.tipo == _tipoSelecionado;

      return atendeBusca && atendeStatus && atendeTipo;
    }).toList();
  }

  void _filtrar() => setState(_aplicarFiltros);

  Future<void> _abrirEdicao(LeadParceiro lead) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LeadParceiroFormPage(lead: lead)),
    );

    if (mounted) await _carregar();
  }

  Future<void> _abrirConversao(
    LeadParceiro lead,
    LeadEstabelecimento estabelecimento,
  ) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeadParceiroConverterPage(
          lead: lead,
          estabelecimento: estabelecimento,
        ),
      ),
    );

    if (resultado == true) await _carregar();
  }

  Future<void> _reenviarConvite(LeadParceiro lead) async {
    try {
      final resultado = await _repository.reenviarConviteParceiro(
        leadparceiroId: lead.leadparceiroId,
      );
      if (!mounted) return;

      final enviado = resultado['convite_enviado'] == true;
      final email = resultado['email']?.toString() ?? lead.email;
      final senha = resultado['senha_inicial']?.toString() ?? '';

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(enviado ? 'Convite reenviado' : 'Nova senha gerada'),
          content: SelectableText(
            enviado
                ? 'O convite foi enviado para $email.\n\n'
                      'Senha inicial: $senha'
                : 'O e-mail não pôde ser enviado. Informe estes dados '
                      'manualmente ao parceiro:\n\nE-mail: $email\nSenha: $senha',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.erro(
        context,
        e.toString().replaceFirst('Exception: ', '').trim(),
      );
    }
  }

  Future<void> _abrirAtendimento(LeadParceiro lead) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LeadAtendimentoPage(lead: lead)),
    );
    if (mounted) await _carregar();
  }

  Future<void> _novoEstabelecimento(LeadParceiro lead) async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeadEstabelecimentoFormPage(lead: lead),
      ),
    );
    if (criado == true && mounted) await _carregar();
  }

  int _quantidadeStatus(String status) =>
      _leads.where((lead) => lead.status == status).length;

  String _nomeStatus(String status) {
    switch (status) {
      case 'CONTATADO':
        return 'Contatados';
      case 'NEGOCIANDO':
        return 'Negociando';
      case 'ACEITOU_PARCERIA':
        return 'Parceria aceita';
      case 'CONVERTIDO':
        return 'Convertidos';
      case 'RECUSOU_PARCERIA':
        return 'Parceria recusada';
      case 'NOVO':
        return 'Novos';
      default:
        return 'Todos';
    }
  }

  String _nomeStatusBadge(String status) {
    switch (status) {
      case 'CONTATADO':
        return 'Contatado';
      case 'NEGOCIANDO':
        return 'Negociando';
      case 'ACEITOU_PARCERIA':
        return 'Aceitou parceria';
      case 'CONVERTIDO':
        return 'Convertido';
      case 'RECUSOU_PARCERIA':
        return 'Recusou parceria';
      case 'NOVO':
        return 'Novo';
      default:
        return status;
    }
  }

  String _nomeTipo(String tipo) {
    switch (tipo) {
      case 'CASA_NOTURNA':
        return 'Casa Noturna';

      case 'PRODUTOR_EVENTOS':
        return 'Produtor de Eventos';
      case 'CASA_EVENTOS':
        return 'Casa de eventos';

      case 'BAR':
        return 'Bar';

      default:
        return 'Todos os tipos';
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'CONTATADO':
        return ClubbarColors.info;
      case 'NEGOCIANDO':
        return Colors.orange.shade800;
      case 'ACEITOU_PARCERIA':
        return Colors.teal.shade700;
      case 'CONVERTIDO':
        return ClubbarColors.sucesso;
      case 'RECUSOU_PARCERIA':
        return ClubbarColors.textoSecundario;
      default:
        return ClubbarColors.erro;
    }
  }

  Color _fundoStatus(String status) {
    switch (status) {
      case 'CONTATADO':
        return ClubbarColors.infoClaro;
      case 'NEGOCIANDO':
        return Colors.orange.shade50;
      case 'ACEITOU_PARCERIA':
        return Colors.teal.shade50;
      case 'CONVERTIDO':
        return ClubbarColors.sucessoClaro;
      case 'RECUSOU_PARCERIA':
        return Colors.grey.shade200;
      default:
        return ClubbarColors.erroClaro;
    }
  }

  String _formatarTelefone(String valor) {
    final numeros = valor.replaceAll(RegExp(r'\D'), '');

    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    }

    if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }

    return valor;
  }

  String _formatarData(DateTime data) {
    final local = data.toLocal();
    String dois(int valor) => valor.toString().padLeft(2, '0');

    return '${dois(local.day)}/${dois(local.month)}/${local.year} '
        '${dois(local.hour)}:${dois(local.minute)}';
  }

  String _textoEspera(LeadParceiro lead) {
    if (lead.status == 'NOVO') {
      if (lead.diasEspera == 0) return 'Aguardando contato desde hoje';
      if (lead.diasEspera == 1) return 'Aguardando contato há 1 dia';
      return 'Aguardando contato há ${lead.diasEspera} dias';
    }

    if (lead.diasEspera == 0) return 'Cadastrado hoje';
    if (lead.diasEspera == 1) return 'Cadastrado há 1 dia';
    return 'Cadastrado há ${lead.diasEspera} dias';
  }

  Color _corEspera(LeadParceiro lead) {
    if (lead.status != 'NOVO') return ClubbarColors.textoSecundario;
    if (lead.diasEspera >= 7) return ClubbarColors.erro;
    if (lead.diasEspera >= 3) return Colors.orange.shade800;
    return ClubbarColors.sucesso;
  }

  Widget _resumoStatus() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _status.length - 1,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final status = _status[index + 1];

          final selecionado = _statusSelecionado == status;

          final cor = _corStatus(status);

          return InkWell(
            onTap: () {
              setState(() {
                _statusSelecionado = selecionado ? 'TODOS' : status;

                _aplicarFiltros();
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 104,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: selecionado
                    ? _fundoStatus(status)
                    : ClubbarColors.branco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selecionado ? cor : ClubbarColors.borda,
                  width: selecionado ? 1.5 : 1,
                ),
                boxShadow: selecionado
                    ? [
                        BoxShadow(
                          color: cor.withValues(alpha: 0.14),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(_iconeStatus(status), size: 22, color: cor),

                  const SizedBox(height: 4),

                  Text(
                    '${_quantidadeStatus(status)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: cor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _nomeStatus(status),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _decoracaoFiltro({
    required String label,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone),
      filled: true,
      fillColor: ClubbarColors.branco,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClubbarColors.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClubbarColors.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ClubbarColors.ambar, width: 2),
      ),
    );
  }

  Widget _filtros() {
    return Column(
      children: [
        TextField(
          controller: _buscaController,
          onChanged: (_) => _filtrar(),
          decoration:
              _decoracaoFiltro(
                label: 'Buscar responsável, estabelecimento ou contato',
                icone: Icons.search_rounded,
              ).copyWith(
                suffixIcon: _buscaController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _buscaController.clear();
                          _filtrar();
                          FocusScope.of(context).unfocus();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _tipoSelecionado,
          isExpanded: true,
          decoration: _decoracaoFiltro(
            label: 'Tipo estabelecimento',
            icone: Icons.category_outlined,
          ),
          items: _tipos
              .map(
                (tipo) =>
                    DropdownMenuItem(value: tipo, child: Text(_nomeTipo(tipo))),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _tipoSelecionado = value;
              _aplicarFiltros();
            });
          },
        ),
      ],
    );
  }

  Widget _cardLead(LeadParceiro lead) {
    final urgente = lead.status == 'NOVO' && lead.diasEspera >= 7;

    return ClubbarCard(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _fundoStatus(lead.status),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  urgente
                      ? Icons.local_fire_department_rounded
                      : Icons.handshake_rounded,
                  color: _corStatus(lead.status),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.nmestabelecimento,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _fundoStatus(lead.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _nomeStatusBadge(lead.status),
                            style: TextStyle(
                              color: _corStatus(lead.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lead.nmresponsavel,
                      style: const TextStyle(
                        color: ClubbarColors.textoSecundario,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _chip(Icons.category_outlined, _nomeTipo(lead.tipo)),
                        _chip(
                          Icons.location_on_outlined,
                          '${lead.nmcidade}/${lead.sgestado}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _linha(Icons.phone_outlined, _formatarTelefone(lead.telefone)),
          const SizedBox(height: 7),
          _linha(Icons.email_outlined, lead.email),
          const SizedBox(height: 7),
          _linha(
            Icons.calendar_today_outlined,
            'Cadastrado em ${_formatarData(lead.dtcriacao)}',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _corEspera(lead).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  urgente
                      ? Icons.priority_high_rounded
                      : Icons.schedule_rounded,
                  size: 18,
                  color: _corEspera(lead),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    urgente
                        ? 'URGENTE • ${_textoEspera(lead)}'
                        : _textoEspera(lead),
                    style: TextStyle(
                      color: _corEspera(lead),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (lead.aguardandoResposta) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mark_chat_unread_rounded,
                    size: 19,
                    color: Colors.orange.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lead aguardando resposta',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirEdicao(lead),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar lead'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _abrirAtendimento(lead),
                  icon: const Icon(Icons.forum_rounded),
                  label: const Text('Atender lead'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClubbarColors.info,
                    foregroundColor: ClubbarColors.branco,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estabelecimentos',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _novoEstabelecimento(lead),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('Novo estabelecimento'),
              ),
            ],
          ),
          for (final estabelecimento in lead.estabelecimentos) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: estabelecimento.status == 'ACEITOU_PARCERIA'
                    ? () => _abrirConversao(lead, estabelecimento)
                    : null,
                icon: const Icon(Icons.storefront_rounded),
                label: Text(
                  estabelecimento.status == 'CONVERTIDO'
                      ? '${estabelecimento.nome} — convertido'
                      : 'Converter ${estabelecimento.nome}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClubbarColors.ambar,
                  foregroundColor: ClubbarColors.preto,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
          if (lead.status == 'CONVERTIDO') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _reenviarConvite(lead),
                icon: const Icon(Icons.mark_email_read_rounded),
                label: const Text('Reenviar convite de acesso'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icone, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ClubbarColors.fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: ClubbarColors.textoSecundario),
          const SizedBox(width: 5),
          Text(
            texto,
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

  Widget _linha(IconData icone, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 17, color: ClubbarColors.textoSecundario),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: ClubbarColors.textoSecundario,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _conteudoLista() {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: CircularProgressIndicator(color: ClubbarColors.ambar),
        ),
      );
    }

    if (_erro != null) {
      return ClubbarCard(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar os leads',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_leadsFiltrados.isEmpty) {
      return const ClubbarCard(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 54),
            SizedBox(height: 12),
            Text(
              'Nenhum lead encontrado',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 7),
            Text(
              'Ajuste os filtros ou aguarde novos cadastros pela landing page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ClubbarColors.textoSecundario),
            ),
          ],
        ),
      );
    }

    return Column(children: _leadsFiltrados.map(_cardLead).toList());
  }

  @override
  Widget build(BuildContext context) {
    final urgentes = _leads
        .where((lead) => lead.status == 'NOVO' && lead.diasEspera >= 7)
        .length;

    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: SafeArea(
        child: Column(
          children: [
            ClubbarPageHeader(
              titulo: 'Leads',
              subtitulo: _carregando
                  ? 'Carregando fila comercial...'
                  : '${_leads.length} lead(s) cadastrado(s)',
              icone: Icons.handshake_rounded,
              mostrarDadosSessao: false,
              trailing: IconButton(
                tooltip: 'Atualizar leads',
                onPressed: _carregando ? null : _carregar,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _carregar,
                color: ClubbarColors.ambar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    if (!_carregando && urgentes > 0) ...[
                      ClubbarCard(
                        elevation: 0,
                        backgroundColor: ClubbarColors.erroClaro,
                        borderColor: ClubbarColors.erro,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: ClubbarColors.erro,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                urgentes == 1
                                    ? '1 lead novo aguarda contato há 7 dias ou mais.'
                                    : '$urgentes leads novos aguardam contato há 7 dias ou mais.',
                                style: const TextStyle(
                                  color: ClubbarColors.erro,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _resumoStatus(),
                    const SizedBox(height: 16),
                    _filtros(),
                    const SizedBox(height: 18),
                    _conteudoLista(),
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
