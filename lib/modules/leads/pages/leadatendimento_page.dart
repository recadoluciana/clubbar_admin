import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadAtendimentoPage extends StatefulWidget {
  final LeadParceiro lead;
  const LeadAtendimentoPage({super.key, required this.lead});
  @override
  State<LeadAtendimentoPage> createState() => _LeadAtendimentoPageState();
}

class _LeadAtendimentoPageState extends State<LeadAtendimentoPage> {
  final _repo = LeadParceiroRepository();
  Map<String, dynamic> _dados = {};
  bool _carregando = true;
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
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final d = await _repo.consultarAtendimento(widget.lead.leadparceiroId);
      if (mounted)
        setState(() {
          _dados = d;
          _carregando = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
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
      if (mounted)
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _mensagem() async {
    final t = await _texto('Nova mensagem', 'Mensagem para o lead');
    if (t != null && t.isNotEmpty)
      await _acao(
        () => _repo.enviarMensagem(widget.lead.leadparceiroId, t),
        'Mensagem enviada.',
      );
  }

  Future<void> _material() async {
    final t = await _texto('Novo material', 'Título');
    if (t == null || t.isEmpty) return;
    final u = await _texto('Link do material', 'https://...');
    if (u != null && u.isNotEmpty)
      await _acao(
        () => _repo.criarMaterial(widget.lead.leadparceiroId, {
          'titulo': t,
          'descricao': null,
          'tipo': 'OUTRO',
          'urlarquivo': u,
        }),
        'Material incluído.',
      );
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
                  if (hora != null)
                    setLocal(
                      () => data = DateTime(
                        dia.year,
                        dia.month,
                        dia.day,
                        hora.hour,
                        hora.minute,
                      ),
                    );
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
    if (ok == true)
      await _acao(
        () => _repo.criarAgendamento(widget.lead.leadparceiroId, {
          'tipo': tipo,
          'dtagendamento': data.toIso8601String(),
          'observacao': null,
        }),
        'Agendamento enviado.',
      );
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
  @override
  Widget build(BuildContext context) {
    final mensagens = _lista('mensagens'),
        agendas = _lista('agendamentos'),
        materiais = _lista('materiais');
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: widget.lead.nmestabelecimento,
            subtitulo:
                'Atendimento • Decisão: ' +
                (_dados['decisao']?.toString() ?? 'PENDENTE'),
            icone: Icons.forum_rounded,
            mostrarDadosSessao: false,
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _acao(
                            () => _repo.reenviarAcesso(
                              widget.lead.leadparceiroId,
                            ),
                            'Novo link enviado por e-mail.',
                          ),
                          icon: const Icon(Icons.mark_email_read),
                          label: const Text('Reenviar acesso ao portal'),
                        ),
                        const SizedBox(height: 14),
                        _secao(
                          'Conversa',
                          Icons.chat_bubble_outline,
                          _mensagem,
                          mensagens
                              .map(
                                (x) => ListTile(
                                  leading: Icon(
                                    x['origem'] == 'LEAD'
                                        ? Icons.person
                                        : Icons.support_agent,
                                  ),
                                  title: Text(x['mensagem']?.toString() ?? ''),
                                  subtitle: Text(
                                    (x['origem'] == 'LEAD'
                                            ? 'Lead'
                                            : 'Clubbar') +
                                        ' • ' +
                                        _data(x['dtcriacao']),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        _secao(
                          'Agendamentos',
                          Icons.event_available,
                          _agendamento,
                          agendas
                              .map(
                                (x) => ListTile(
                                  title: Text(
                                    x['tipo'].toString().replaceAll('_', ' '),
                                  ),
                                  subtitle: Text(
                                    _data(x['dtagendamento']) +
                                        ' • ' +
                                        x['status'].toString(),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (s) => _acao(
                                      () => _repo.alterarAgendamento(
                                        widget.lead.leadparceiroId,
                                        x['leadagendamento_id'] as int,
                                        s,
                                      ),
                                      'Agendamento atualizado.',
                                    ),
                                    itemBuilder: (_) =>
                                        ['REALIZADO', 'CANCELADO']
                                            .map(
                                              (s) => PopupMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        _secao(
                          'Materiais',
                          Icons.folder_open,
                          _material,
                          materiais
                              .map(
                                (x) => ListTile(
                                  title: Text(x['titulo']?.toString() ?? ''),
                                  subtitle: Text(
                                    x['urlarquivo']?.toString() ?? '',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _acao(
                                      () => _repo.excluirMaterial(
                                        widget.lead.leadparceiroId,
                                        x['leadmaterial_id'] as int,
                                      ),
                                      'Material excluído.',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
