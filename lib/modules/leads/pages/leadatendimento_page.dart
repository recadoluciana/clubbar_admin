import 'package:flutter/material.dart';
import '../../../core/repositories/taxa_padrao_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadAtendimentoPage extends StatefulWidget {
  final LeadParceiro lead;
  final String? secao;
  final int? estabelecimentoInicialId;
  const LeadAtendimentoPage({
    super.key,
    required this.lead,
    this.secao,
    this.estabelecimentoInicialId,
  });
  @override
  State<LeadAtendimentoPage> createState() => _LeadAtendimentoPageState();
}

class _LeadAtendimentoPageState extends State<LeadAtendimentoPage> {
  final _repo = LeadParceiroRepository();
  final _mensagemController = TextEditingController();
  Map<String, dynamic> _dados = {};
  bool _carregando = true;
  bool _enviandoMensagem = false;
  late LeadEstabelecimento _estabelecimentoSelecionado;
  List<Map<String, dynamic>> _lista(String chave) =>
      ((_dados[chave] as List?) ?? [])
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
  String _data(dynamic valor) {
    final d = DateTime.tryParse(valor?.toString() ?? '');
    return d == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
  }

  @override
  void initState() {
    super.initState();
    _estabelecimentoSelecionado = widget.lead.estabelecimentos.firstWhere(
      (item) => item.id == widget.estabelecimentoInicialId,
      orElse: () => widget.lead.estabelecimentos.first,
    );
    _carregar();
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final d = await _repo.consultarAtendimento(
        widget.lead.leadparceiroId,
        _estabelecimentoSelecionado.id,
      );
      if (mounted) {
        setState(() {
          _dados = d;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _abrirSecao(String secao) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LeadAtendimentoPage(
          lead: widget.lead,
          secao: secao,
          estabelecimentoInicialId: _estabelecimentoSelecionado.id,
        ),
      ),
    );
    if (mounted) await _carregar();
  }

  Widget _opcao({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required String secao,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        leading: CircleAvatar(
          backgroundColor: ClubbarColors.ambar.withValues(alpha: 0.22),
          child: Icon(icone, color: ClubbarColors.ambarEscuro),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _abrirSecao(secao),
      ),
    );
  }

  Future<String?> _texto(String titulo, String dica) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: dica,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    c.dispose();
    return v;
  }

  Future<void> _acao(Future<void> Function() fn, String msg) async {
    try {
      await fn();
      if (!mounted) return;
      AppSnackBar.sucesso(context, msg);
      await _carregar();
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _enviarMensagemDireta() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _enviandoMensagem) return;
    setState(() => _enviandoMensagem = true);
    try {
      await _repo.enviarMensagem(
        widget.lead.leadparceiroId,
        _estabelecimentoSelecionado.id,
        texto,
      );
      _mensagemController.clear();
      await _carregar();
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _enviandoMensagem = false);
    }
  }

  Future<void> _excluirMensagem(int mensagemId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir mensagem?'),
        content: const Text(
          'A última mensagem enviada pelo Clubbar será excluída.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _acao(
      () => _repo.excluirMensagem(
        widget.lead.leadparceiroId,
        _estabelecimentoSelecionado.id,
        mensagemId,
      ),
      'Mensagem excluída.',
    );
  }

  Future<void> materialLegado() async {
    final t = await _texto('Novo material', 'Título');
    if (t == null || t.isEmpty) return;
    final u = await _texto('Link do material', 'https://...');
    if (u != null && u.isNotEmpty) {
      await _acao(
        () => _repo.criarMaterial(
          widget.lead.leadparceiroId,
          _estabelecimentoSelecionado.id,
          {'titulo': t, 'descricao': null, 'tipo': 'OUTRO', 'urlarquivo': u},
        ),
        'Material incluído.',
      );
    }
  }

  Future<void> _materialNovo() async {
    final titulo = TextEditingController();
    final descricao = TextEditingController();
    final link = TextEditingController();
    String modo = 'ARQUIVO';
    String tipo = 'APRESENTACAO';
    PlatformFile? arquivo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Novo material'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'ARQUIVO',
                        icon: Icon(Icons.upload_file),
                        label: Text('Enviar arquivo'),
                      ),
                      ButtonSegment(
                        value: 'LINK',
                        icon: Icon(Icons.link),
                        label: Text('Link externo'),
                      ),
                    ],
                    selected: {modo},
                    onSelectionChanged: (v) => setLocal(() => modo = v.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titulo,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descricao,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'APRESENTACAO',
                        child: Text('Apresentação'),
                      ),
                      DropdownMenuItem(
                        value: 'PROPOSTA',
                        child: Text('Proposta'),
                      ),
                      DropdownMenuItem(
                        value: 'CONTRATO',
                        child: Text('Contrato'),
                      ),
                      DropdownMenuItem(value: 'VIDEO', child: Text('Vídeo')),
                      DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                    ],
                    onChanged: (v) => tipo = v!,
                  ),
                  const SizedBox(height: 12),
                  if (modo == 'LINK')
                    TextField(
                      controller: link,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Link do YouTube, Canva ou outro HTTPS',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const [
                            'pdf',
                            'png',
                            'jpg',
                            'jpeg',
                            'webp',
                            'doc',
                            'docx',
                            'ppt',
                            'pptx',
                            'xls',
                            'xlsx',
                          ],
                          withData: kIsWeb,
                        );
                        if (r != null) setLocal(() => arquivo = r.files.single);
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        arquivo?.name ?? 'Selecionar PDF, imagem ou documento',
                      ),
                    ),
                  if (modo == 'ARQUIVO')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Tamanho máximo: 20 MB'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final uri = Uri.tryParse(link.text.trim());
                if (titulo.text.trim().isEmpty) return;
                if (modo == 'ARQUIVO' && arquivo == null) return;
                if (modo == 'LINK' && (uri == null || uri.scheme != 'https')) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Disponibilizar'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (confirmar == true) {
      if (modo == 'ARQUIVO') {
        await _acao(
          () => _repo.uploadMaterial(
            id: widget.lead.leadparceiroId,
            estabelecimentoId: _estabelecimentoSelecionado.id,
            titulo: titulo.text.trim(),
            descricao: descricao.text.trim(),
            tipo: tipo,
            arquivo: arquivo!,
          ),
          'Arquivo enviado e disponibilizado.',
        );
      } else {
        await _acao(
          () => _repo.criarMaterial(
            widget.lead.leadparceiroId,
            _estabelecimentoSelecionado.id,
            {
              'titulo': titulo.text.trim(),
              'descricao': descricao.text.trim().isEmpty
                  ? null
                  : descricao.text.trim(),
              'tipo': tipo,
              'urlarquivo': link.text.trim(),
            },
          ),
          'Link disponibilizado.',
        );
      }
    }
    titulo.dispose();
    descricao.dispose();
    link.dispose();
  }

  Future<void> _contrato() async {
    final estabelecimentosDisponiveis = widget.lead.estabelecimentos
        .where(
          (item) =>
              item.status != 'ACEITOU_PARCERIA' && item.status != 'CONVERTIDO',
        )
        .toList();
    if (estabelecimentosDisponiveis.isEmpty) {
      AppSnackBar.aviso(
        context,
        widget.lead.estabelecimentos.isEmpty
            ? 'Cadastre um estabelecimento para o lead.'
            : 'Todos os contratos já foram aceitos ou os estabelecimentos já foram convertidos.',
      );
      return;
    }
    var estabelecimento = estabelecimentosDisponiveis.first;
    Map<String, dynamic> taxaVigente;
    try {
      taxaVigente = await TaxaPadraoRepository().consultarVigente();
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }
    if (!mounted) return;
    final taxaProdutos = TextEditingController(
      text: double.parse(
        '${taxaVigente['pctaxaproduto']}',
      ).toStringAsFixed(2).replaceAll('.', ','),
    );
    final taxaIngressos = TextEditingController(
      text: double.parse(
        '${taxaVigente['pctaxaingresso']}',
      ).toStringAsFixed(2).replaceAll('.', ','),
    );
    final cpfCnpj = TextEditingController(text: estabelecimento.cpfCnpj ?? '');
    final razaoSocial = TextEditingController(
      text:
          (estabelecimento.cpfCnpj ?? '')
                  .replaceAll(RegExp(r'\D'), '')
                  .length ==
              11
          ? (estabelecimento.nomeResponsavel ?? widget.lead.nmresponsavel)
          : '',
    );
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Disponibilizar contrato'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<LeadEstabelecimento>(
                    initialValue: estabelecimento,
                    decoration: const InputDecoration(
                      labelText: 'Estabelecimento',
                      border: OutlineInputBorder(),
                    ),
                    items: estabelecimentosDisponiveis
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.nome),
                          ),
                        )
                        .toList(),
                    onChanged: (item) {
                      if (item != null) {
                        setLocal(() {
                          estabelecimento = item;
                          cpfCnpj.text = item.cpfCnpj ?? '';
                          final numeros = cpfCnpj.text.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          razaoSocial.text = numeros.length == 11
                              ? (item.nomeResponsavel ??
                                    widget.lead.nmresponsavel)
                              : '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cpfCnpj,
                    decoration: const InputDecoration(
                      labelText: 'CPF/CNPJ do contratante',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: razaoSocial,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo / razão social',
                      helperText:
                          'Para CNPJ, informe obrigatoriamente a razão social.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Será utilizada automaticamente a versão ativa do contrato padrão Clubbar.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: taxaProdutos,
                          readOnly: true,
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
                          readOnly: true,
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
      ),
    );
    if (!mounted) return;
    if (confirmar == true) {
      final produtos = double.tryParse(taxaProdutos.text.replaceAll(',', '.'));
      final ingressos = double.tryParse(
        taxaIngressos.text.replaceAll(',', '.'),
      );
      if (produtos == null || ingressos == null) {
        AppSnackBar.aviso(context, 'Informe taxas válidas.');
      } else {
        final documento = cpfCnpj.text.replaceAll(RegExp(r'\D'), '');
        if ((documento.length != 11 && documento.length != 14) ||
            razaoSocial.text.trim().isEmpty) {
          AppSnackBar.aviso(
            context,
            documento.length == 14
                ? 'Informe a razão social da empresa.'
                : 'Informe um CPF/CNPJ válido e o nome do contratante.',
          );
          taxaProdutos.dispose();
          taxaIngressos.dispose();
          cpfCnpj.dispose();
          razaoSocial.dispose();
          return;
        }
        final dados = {
          'vrtaxaprod': produtos,
          'vrtaxaing': ingressos,
          'cpfcnpj': documento,
          'nmrazaosocial': razaoSocial.text.trim(),
        };
        try {
          final conteudo = await _repo.previsualizarContrato(
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
          if (disponibilizar == true) {
            await _acao(
              () => _repo.criarContrato(estabelecimento.id, dados),
              'Contrato disponibilizado para ${estabelecimento.nome}.',
            );
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
    taxaProdutos.dispose();
    taxaIngressos.dispose();
    cpfCnpj.dispose();
    razaoSocial.dispose();
  }

  Future<void> _agendamento() async {
    DateTime data = DateTime.now().add(const Duration(days: 1));
    String tipo = 'REUNIAO_ONLINE';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Propor agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: tipo,
                items: const [
                  DropdownMenuItem(
                    value: 'DEMONSTRACAO',
                    child: Text('Demonstração'),
                  ),
                  DropdownMenuItem(value: 'LIGACAO', child: Text('Ligação')),
                  DropdownMenuItem(
                    value: 'REUNIAO_ONLINE',
                    child: Text('Reunião online'),
                  ),
                  DropdownMenuItem(value: 'VISITA', child: Text('Visita')),
                ],
                onChanged: (v) => tipo = v!,
              ),
              ListTile(
                title: Text(_data(data.toIso8601String())),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final dia = await showDatePicker(
                    context: ctx,
                    initialDate: data,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (dia == null || !ctx.mounted) return;
                  final hora = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(data),
                  );
                  if (hora != null) {
                    setLocal(
                      () => data = DateTime(
                        dia.year,
                        dia.month,
                        dia.day,
                        hora.hour,
                        hora.minute,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _acao(
        () => _repo.criarAgendamento(
          widget.lead.leadparceiroId,
          _estabelecimentoSelecionado.id,
          {
            'tipo': tipo,
            'dtagendamento': data.toIso8601String(),
            'observacao': null,
          },
        ),
        'Agendamento enviado.',
      );
    }
  }

  Widget _secao(
    String titulo,
    IconData icone,
    VoidCallback adicionar,
    List<Widget> itens,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icone, color: ClubbarColors.ambar),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: adicionar,
                icon: const Icon(Icons.add_circle),
              ),
            ],
          ),
          const Divider(),
          if (itens.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Nenhum registro.'),
            )
          else
            ...itens,
        ],
      ),
    ),
  );

  Widget _mensagemChat(
    Map<String, dynamic> mensagem, {
    required bool podeExcluir,
  }) {
    final enviadaPeloLead = mensagem['origem'] == 'LEAD';
    final cor = enviadaPeloLead ? Colors.blue : Colors.deepPurple;
    return Align(
      alignment: enviadaPeloLead ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.82,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            border: Border.all(color: cor.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(enviadaPeloLead ? 4 : 16),
              bottomRight: Radius.circular(enviadaPeloLead ? 16 : 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    enviadaPeloLead
                        ? Icons.person_rounded
                        : Icons.support_agent_rounded,
                    size: 17,
                    color: cor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    enviadaPeloLead ? 'Lead' : 'Clubbar',
                    style: TextStyle(
                      color: cor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (podeExcluir) ...[
                    const Spacer(),
                    IconButton(
                      tooltip: 'Excluir última mensagem enviada',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      onPressed: () {
                        final id = int.tryParse(
                          mensagem['leadmensagem_id']?.toString() ?? '',
                        );
                        if (id != null) _excluirMensagem(id);
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: cor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(mensagem['mensagem']?.toString() ?? ''),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _data(mensagem['dtcriacao']),
                  style: TextStyle(color: cor, fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversa(List<Map<String, dynamic>> mensagens) {
    int? ultimaMensagemClubbarId;
    for (final mensagem in mensagens.reversed) {
      if (mensagem['origem'] == 'CLUBBAR') {
        ultimaMensagemClubbarId = int.tryParse(
          mensagem['leadmensagem_id']?.toString() ?? '',
        );
        break;
      }
    }
    return Column(
      children: [
        Expanded(
          child: mensagens.isEmpty
              ? const Center(child: Text('Nenhuma mensagem até agora.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: mensagens.map((mensagem) {
                    final id = int.tryParse(
                      mensagem['leadmensagem_id']?.toString() ?? '',
                    );
                    return _mensagemChat(
                      mensagem,
                      podeExcluir:
                          mensagem['origem'] == 'CLUBBAR' &&
                          id == ultimaMensagemClubbarId,
                    );
                  }).toList(),
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensagemController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar mensagem',
                  onPressed: _enviandoMensagem ? null : _enviarMensagemDireta,
                  style: IconButton.styleFrom(
                    backgroundColor: ClubbarColors.ambar,
                    foregroundColor: ClubbarColors.preto,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: _enviandoMensagem
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded, size: 28),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _nomeStatus(dynamic valor) {
    return switch (valor?.toString()) {
      'CONTATADO' => 'Contatado',
      'NEGOCIANDO' => 'Em negociação',
      'ACEITOU_PARCERIA' => 'Parceria aceita',
      'CONVERTIDO' => 'Convertido',
      'RECUSOU_PARCERIA' => 'Recusou parceria',
      _ => 'Novo',
    };
  }

  Widget _estabelecimentoCabecalho() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Estabelecimento: ${_estabelecimentoSelecionado.nome}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ClubbarColors.info,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mensagens = _lista('mensagens'),
        agendas = _lista('agendamentos'),
        materiais = _lista('materiais');
    final aguardandoResposta =
        mensagens.isNotEmpty && mensagens.last['origem'] == 'LEAD';
    final conteudoSecao = switch (widget.secao) {
      'MENSAGENS' => null,
      'AGENDAMENTOS' => _secao(
        'Agendamentos',
        Icons.event_available,
        _agendamento,
        agendas
            .map(
              (x) => ListTile(
                title: Text(x['tipo'].toString().replaceAll('_', ' ')),
                subtitle: Text('${_data(x['dtagendamento'])} • ${x['status']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (s) => _acao(
                    () => _repo.alterarAgendamento(
                      widget.lead.leadparceiroId,
                      _estabelecimentoSelecionado.id,
                      x['leadagendamento_id'] as int,
                      s,
                    ),
                    'Agendamento atualizado.',
                  ),
                  itemBuilder: (_) => ['REALIZADO', 'CANCELADO']
                      .map((s) => PopupMenuItem(value: s, child: Text(s)))
                      .toList(),
                ),
              ),
            )
            .toList(),
      ),
      'MATERIAIS' => _secao(
        'Materiais',
        Icons.folder_open,
        _materialNovo,
        materiais
            .map(
              (x) => ListTile(
                title: Text(x['titulo']?.toString() ?? ''),
                subtitle: Text(x['urlarquivo']?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _acao(
                    () => _repo.excluirMaterial(
                      widget.lead.leadparceiroId,
                      _estabelecimentoSelecionado.id,
                      x['leadmaterial_id'] as int,
                    ),
                    'Material excluído.',
                  ),
                ),
              ),
            )
            .toList(),
      ),
      _ => null,
    };
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: widget.lead.nmresponsavel,
            subtitulo: '',
            subtituloWidget: _estabelecimentoCabecalho(),
            mostrarIcone: false,
            estiloTitulo: const TextStyle(color: ClubbarColors.info),
            mostrarDadosSessao: false,
            trailing: IconButton(
              tooltip: 'Atualizar atendimento',
              onPressed: _carregando ? null : _carregar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          if (!_carregando &&
              aguardandoResposta &&
              (widget.secao == null || widget.secao == 'MENSAGENS'))
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.mark_chat_unread_rounded,
                    color: Colors.orange.shade900,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Lead aguardando resposta da conversa',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : widget.secao == 'MENSAGENS'
                ? _conversa(mensagens)
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (conteudoSecao != null)
                          conteudoSecao
                        else ...[
                          _opcao(
                            titulo: 'Mensagens',
                            subtitulo: '${mensagens.length} mensagem(ns)',
                            icone: Icons.mark_chat_unread_rounded,
                            secao: 'MENSAGENS',
                          ),
                          _opcao(
                            titulo: 'Materiais',
                            subtitulo: '${materiais.length} material(is)',
                            icone: Icons.folder_open_rounded,
                            secao: 'MATERIAIS',
                          ),
                          _opcao(
                            titulo: 'Agendamentos',
                            subtitulo: '${agendas.length} agendamento(s)',
                            icone: Icons.event_available,
                            secao: 'AGENDAMENTOS',
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
