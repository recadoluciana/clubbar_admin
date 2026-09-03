import 'package:flutter/material.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/utils/formatters.dart';
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
      final leads = await _repository.listar();
      if (!mounted) return;
      setState(() {
        _leads = [...leads]
          ..sort((a, b) => a.leadparceiroId.compareTo(b.leadparceiroId));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '').trim();
        _carregando = false;
      });
    }
  }

  List<LeadParceiro> get _leadsFiltrados {
    final busca = _buscaController.text.trim().toLowerCase();
    if (busca.isEmpty) return _leads;
    return _leads.where((lead) {
      return lead.nmresponsavel.toLowerCase().contains(busca) ||
          lead.email.toLowerCase().contains(busca) ||
          lead.telefone.toLowerCase().contains(busca) ||
          (lead.nmorganizacao ?? '').toLowerCase().contains(busca);
    }).toList();
  }

  Future<void> _abrirLead(LeadParceiro lead) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            LeadEstabelecimentoListPage(leadparceiroId: lead.leadparceiroId),
      ),
    );
    if (mounted) await _carregar();
  }

  Future<void> _abrirEdicao(LeadParceiro lead) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LeadParceiroFormPage(lead: lead)),
    );
    if (mounted) await _carregar();
  }

  Widget _informacaoLead({
    required IconData icone,
    required Color cor,
    required String texto,
    FontWeight peso = FontWeight.w600,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icone, size: 17, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: ClubbarColors.textoSecundario,
                fontWeight: peso,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: ClubbarColors.ambar),
      );
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ClubbarCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 52),
                const SizedBox(height: 12),
                Text(_erro!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final leads = _leadsFiltrados;
    if (leads.isEmpty) {
      return const Center(child: Text('Nenhum lead encontrado.'));
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: ClubbarColors.ambar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return ClubbarCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _abrirLead(lead),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 5,
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: ClubbarColors.info,
                              ),
                              Text(
                                'Lead #${lead.leadparceiroId}',
                                style: const TextStyle(
                                  color: ClubbarColors.info,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                lead.nmresponsavel,
                                style: const TextStyle(
                                  color: ClubbarColors.info,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar lead',
                          onPressed: () => _abrirEdicao(lead),
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: ClubbarColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((lead.nmorganizacao ?? '').trim().isNotEmpty)
                                _informacaoLead(
                                  icone: Icons.business_rounded,
                                  cor: Colors.deepPurple,
                                  texto: lead.nmorganizacao!,
                                  peso: FontWeight.w700,
                                ),
                              _informacaoLead(
                                icone: Icons.email_rounded,
                                cor: Colors.redAccent,
                                texto: lead.email,
                              ),
                              _informacaoLead(
                                icone: Icons.phone_rounded,
                                cor: Colors.green,
                                texto: ClubbarFormatters.telefone(
                                  lead.telefone,
                                ),
                              ),
                              _informacaoLead(
                                icone: Icons.storefront_rounded,
                                cor: Colors.deepOrange,
                                texto:
                                    '${lead.estabelecimentos.length} estabelecimento(s)',
                                peso: FontWeight.w900,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    if (lead.aguardandoResposta) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: SafeArea(
        child: Column(
          children: [
            ClubbarPageHeader(
              titulo: 'Leads',
              subtitulo: _carregando
                  ? 'Carregando leads...'
                  : '${_leads.length} lead(s) cadastrado(s)',
              icone: Icons.people_alt_rounded,
              mostrarDadosSessao: false,
              trailing: IconButton(
                tooltip: 'Atualizar leads',
                onPressed: _carregando ? null : _carregar,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _buscaController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Buscar lead',
                  hintText: 'Nome, empresa, e-mail ou telefone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _buscaController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _conteudo()),
          ],
        ),
      ),
    );
  }
}

class LeadEstabelecimentoListPage extends StatefulWidget {
  final int leadparceiroId;

  const LeadEstabelecimentoListPage({super.key, required this.leadparceiroId});

  @override
  State<LeadEstabelecimentoListPage> createState() =>
      _LeadEstabelecimentoListPageState();
}

class _LeadEstabelecimentoListPageState
    extends State<LeadEstabelecimentoListPage> {
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
        return Icons.message_rounded;

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
        _leads = lista
            .where((lead) => lead.leadparceiroId == widget.leadparceiroId)
            .toList();
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
      final responsavelEncontrado =
          lead.nmresponsavel.toLowerCase().contains(busca) ||
          lead.telefone.toLowerCase().contains(busca) ||
          lead.email.toLowerCase().contains(busca) ||
          lead.nmcidade.toLowerCase().contains(busca);

      final atendeBusca =
          busca.isEmpty ||
          responsavelEncontrado ||
          lead.estabelecimentos.any(
            (estabelecimento) =>
                estabelecimento.nome.toLowerCase().contains(busca),
          );

      final atendeStatus =
          _statusSelecionado == 'TODOS' ||
          lead.estabelecimentos.any(
            (estabelecimento) => estabelecimento.status == _statusSelecionado,
          );

      final atendeTipo =
          _tipoSelecionado == 'TODOS' ||
          lead.estabelecimentos.any(
            (estabelecimento) => estabelecimento.tipo == _tipoSelecionado,
          );

      return atendeBusca && atendeStatus && atendeTipo;
    }).toList();
  }

  void _filtrar() => setState(_aplicarFiltros);

  Future<void> _abrirAtendimento(
    LeadParceiro lead,
    LeadEstabelecimento estabelecimento,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LeadAtendimentoPage(
          lead: lead,
          estabelecimentoInicialId: estabelecimento.id,
        ),
      ),
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

  Future<void> _editarDadosContratuais(
    LeadParceiro lead,
    LeadEstabelecimento estabelecimento,
  ) async {
    final atualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeadEstabelecimentoFormPage(
          lead: lead,
          estabelecimento: estabelecimento,
        ),
      ),
    );
    if (atualizado == true && mounted) await _carregar();
  }

  Future<void> _disponibilizarContrato(
    LeadEstabelecimento estabelecimento,
  ) async {
    if (!estabelecimento.dadosContratuaisCompletos) {
      AppSnackBar.aviso(
        context,
        'Complete os dados contratuais antes de gerar o contrato.',
      );
      return;
    }

    final versao = TextEditingController(text: '1.0');
    final taxaProdutos = TextEditingController(
      text: estabelecimento.taxaProdutos
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );
    final taxaIngressos = TextEditingController(
      text: estabelecimento.taxaIngressos
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contrato de ${estabelecimento.nome}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: versao,
                decoration: const InputDecoration(
                  labelText: 'Versão',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: taxaProdutos,
                      decoration: const InputDecoration(
                        labelText: 'Taxa produtos %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: taxaIngressos,
                      decoration: const InputDecoration(
                        labelText: 'Taxa ingressos %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pré-visualizar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final produtos = double.tryParse(taxaProdutos.text.replaceAll(',', '.'));
      final ingressos = double.tryParse(
        taxaIngressos.text.replaceAll(',', '.'),
      );
      if (produtos == null || ingressos == null || versao.text.trim().isEmpty) {
        AppSnackBar.aviso(context, 'Informe a versão e taxas válidas.');
      } else {
        try {
          final dados = {
            'versao': versao.text.trim(),
            'vrtaxaprod': produtos,
            'vrtaxaing': ingressos,
          };
          final conteudo = await _repository.previsualizarContrato(
            estabelecimento.id,
            dados,
          );
          if (!mounted) return;
          final disponibilizar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Prévia do contrato'),
              content: SizedBox(
                width: 680,
                height: 520,
                child: SingleChildScrollView(child: SelectableText(conteudo)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Gerar e disponibilizar'),
                ),
              ],
            ),
          );
          if (disponibilizar != true) return;
          await _repository.criarContrato(estabelecimento.id, dados);
          if (mounted) {
            AppSnackBar.sucesso(
              context,
              'Contrato disponibilizado para ${estabelecimento.nome}.',
            );
            await _carregar();
          }
        } catch (e) {
          if (mounted) {
            AppSnackBar.erro(
              context,
              e.toString().replaceFirst('Exception: ', ''),
            );
          }
        }
      }
    }
    versao.dispose();
    taxaProdutos.dispose();
    taxaIngressos.dispose();
  }

  int _quantidadeStatus(String status) => _leads.fold(
    0,
    (total, lead) =>
        total +
        lead.estabelecimentos
            .where((estabelecimento) => estabelecimento.status == status)
            .length,
  );

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

  String _formatarData(DateTime data) {
    final local = data.toLocal();
    String dois(int valor) => valor.toString().padLeft(2, '0');

    return '${dois(local.day)}/${dois(local.month)}/${local.year} '
        '${dois(local.hour)}:${dois(local.minute)}';
  }

  String _textoEspera(LeadParceiro lead, String status) {
    if (status == 'NOVO') {
      if (lead.diasEspera == 0) return 'Aguardando contato desde hoje';
      if (lead.diasEspera == 1) return 'Aguardando contato há 1 dia';
      return 'Aguardando contato há ${lead.diasEspera} dias';
    }

    if (lead.diasEspera == 0) return 'Cadastrado hoje';
    if (lead.diasEspera == 1) return 'Cadastrado há 1 dia';
    return 'Cadastrado há ${lead.diasEspera} dias';
  }

  Color _corEspera(LeadParceiro lead, String status) {
    if (status != 'NOVO') return ClubbarColors.textoSecundario;
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

  Widget _cardLead(LeadParceiro lead, LeadEstabelecimento estabelecimento) {
    final status = estabelecimento.status;
    final urgente = status == 'NOVO' && lead.diasEspera >= 7;

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
                  color: _fundoStatus(status),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  urgente
                      ? Icons.local_fire_department_rounded
                      : Icons.handshake_rounded,
                  color: _corStatus(status),
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
                            estabelecimento.nome,
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
                            color: _fundoStatus(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _nomeStatusBadge(status),
                            style: TextStyle(
                              color: _corStatus(status),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _chip(
                          Icons.category_outlined,
                          _nomeTipo(estabelecimento.tipo),
                        ),
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
          _linha(
            Icons.phone_outlined,
            ClubbarFormatters.telefone(
              estabelecimento.telefoneResponsavel ?? lead.telefone,
            ),
          ),
          const SizedBox(height: 7),
          _linha(
            Icons.email_outlined,
            estabelecimento.emailResponsavel ?? lead.email,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _linha(
                  Icons.calendar_today_outlined,
                  'Cadastrado em ${_formatarData(lead.dtcriacao)}',
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Atender estabelecimento',
                child: ElevatedButton.icon(
                  onPressed: () => _abrirAtendimento(lead, estabelecimento),
                  icon: const Icon(Icons.forum_rounded, size: 17),
                  label: const Text('Atender'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClubbarColors.info,
                    foregroundColor: ClubbarColors.branco,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _corEspera(lead, status).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  urgente
                      ? Icons.priority_high_rounded
                      : Icons.schedule_rounded,
                  size: 18,
                  color: _corEspera(lead, status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    urgente
                        ? 'URGENTE • ${_textoEspera(lead, status)}'
                        : _textoEspera(lead, status),
                    style: TextStyle(
                      color: _corEspera(lead, status),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: estabelecimento.dadosContratuaisCompletos
                  ? ClubbarColors.sucessoClaro
                  : ClubbarColors.erroClaro,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      estabelecimento.dadosContratuaisCompletos
                          ? Icons.task_alt_rounded
                          : Icons.warning_amber_rounded,
                      color: estabelecimento.dadosContratuaisCompletos
                          ? ClubbarColors.sucesso
                          : ClubbarColors.erro,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        estabelecimento.dadosContratuaisCompletos
                            ? 'Dados contratuais completos'
                            : 'Dados contratuais incompletos',
                        style: TextStyle(
                          color: estabelecimento.dadosContratuaisCompletos
                              ? ClubbarColors.sucesso
                              : ClubbarColors.erro,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: estabelecimento.dadosContratuaisCompletos
                          ? 'Editar dados do contrato'
                          : 'Completar dados para contrato',
                      onPressed: () =>
                          _editarDadosContratuais(lead, estabelecimento),
                      icon: const Icon(Icons.edit_rounded),
                      color: ClubbarColors.info,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'CPF/CNPJ: ${(estabelecimento.cpfCnpj ?? '').isEmpty ? 'não informado' : estabelecimento.cpfCnpj}',
                ),
                Text(
                  'Endereço: ${(estabelecimento.endereco ?? '').isEmpty ? 'não informado' : '${estabelecimento.endereco}, ${estabelecimento.numero ?? ''}'}',
                ),
                Text(
                  'Taxas: produtos ${estabelecimento.taxaProdutos.toStringAsFixed(2)}% • ingressos ${estabelecimento.taxaIngressos.toStringAsFixed(2)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: estabelecimento.dadosContratuaisCompletos
                  ? () => _disponibilizarContrato(estabelecimento)
                  : null,
              icon: const Icon(Icons.description_rounded),
              label: const Text('Gerar e disponibilizar contrato'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ClubbarColors.info,
                foregroundColor: ClubbarColors.branco,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: status == 'ACEITOU_PARCERIA'
                  ? () => _abrirConversao(lead, estabelecimento)
                  : null,
              icon: const Icon(Icons.storefront_rounded),
              label: Text(
                status == 'CONVERTIDO'
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
          if (status == 'CONVERTIDO') ...[
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

  List<LeadEstabelecimento> _estabelecimentosFiltrados(LeadParceiro lead) {
    final busca = _buscaController.text.trim().toLowerCase();
    final buscaNoLead =
        busca.isEmpty ||
        lead.nmresponsavel.toLowerCase().contains(busca) ||
        lead.telefone.toLowerCase().contains(busca) ||
        lead.email.toLowerCase().contains(busca) ||
        lead.nmcidade.toLowerCase().contains(busca);

    return lead.estabelecimentos.where((estabelecimento) {
      final atendeBusca =
          buscaNoLead || estabelecimento.nome.toLowerCase().contains(busca);
      final atendeStatus =
          _statusSelecionado == 'TODOS' ||
          estabelecimento.status == _statusSelecionado;
      final atendeTipo =
          _tipoSelecionado == 'TODOS' ||
          estabelecimento.tipo == _tipoSelecionado;
      return atendeBusca && atendeStatus && atendeTipo;
    }).toList();
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

    final cards = <Widget>[
      for (final lead in _leadsFiltrados)
        for (final estabelecimento in _estabelecimentosFiltrados(lead))
          _cardLead(lead, estabelecimento),
    ];

    if (cards.isEmpty) {
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

    return Column(children: cards);
  }

  @override
  Widget build(BuildContext context) {
    final urgentes = _leads.fold(
      0,
      (total, lead) =>
          total +
          (lead.diasEspera < 7
              ? 0
              : lead.estabelecimentos
                    .where(
                      (estabelecimento) => estabelecimento.status == 'NOVO',
                    )
                    .length),
    );

    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: SafeArea(
        child: Column(
          children: [
            ClubbarPageHeader(
              titulo: _carregando
                  ? 'Carregando lead...'
                  : _leads.isEmpty
                  ? 'Lead não encontrado'
                  : _leads.first.nmresponsavel,
              subtitulo: 'Estabelecimentos do lead',
              icone: Icons.storefront_rounded,
              estiloTitulo: const TextStyle(
                fontSize: 24,
                color: ClubbarColors.info,
              ),
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
