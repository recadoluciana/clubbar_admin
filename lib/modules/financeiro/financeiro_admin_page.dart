import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/financeiro_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class FinanceiroAdminPage extends StatefulWidget {
  const FinanceiroAdminPage({super.key});

  @override
  State<FinanceiroAdminPage> createState() => _FinanceiroAdminPageState();
}

class _FinanceiroAdminPageState extends State<FinanceiroAdminPage> {
  final _repo = FinanceiroRepository();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _repasses = [];
  String? _filtro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final dados = await _repo.listar();
      if (mounted) setState(() => _repasses = dados);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  double _total(String status) => _repasses
      .where((e) => e['status'] == status)
      .fold(0, (s, e) => s + ((e['vrrepasse'] as num?)?.toDouble() ?? 0));

  List<Map<String, dynamic>> get _repassesVisiveis => _filtro == null
      ? _repasses
      : _repasses.where((item) => item['status'] == _filtro).toList();

  Future<void> _editar(Map<String, dynamic> item) async {
    var status = item['status']?.toString() ?? 'PENDENTE';
    final transferencia = TextEditingController(
      text: item['idtransferencia']?.toString() ?? '',
    );
    final observacao = TextEditingController(
      text: item['observacao']?.toString() ?? '',
    );
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Repasse #${item['repassefinanceiro_id']}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      const [
                            'BLOQUEADO',
                            'PENDENTE',
                            'AGENDADO',
                            'PAGO',
                            'CANCELADO',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setLocal(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: transferencia,
                  decoration: const InputDecoration(
                    labelText: 'Identificação da transferência',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacao,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observação'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (salvar != true) return;
    await _repo.atualizar(item['repassefinanceiro_id'] as int, {
      'status': status,
      'idtransferencia': transferencia.text.trim().isEmpty
          ? null
          : transferencia.text.trim(),
      'observacao': observacao.text.trim().isEmpty
          ? null
          : observacao.text.trim(),
    });
    await _carregar();
  }

  Widget _indicador(String titulo, String status, Color cor) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _moeda.format(_total(status)),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: ClubbarAppBar(
      actions: [
        IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        const ClubbarPageHeader(
          titulo: 'Financeiro',
          subtitulo: 'Controle de repasses aos parceiros',
          icone: Icons.account_balance_wallet,
          mostrarDataHora: false,
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _indicador('Pendentes', 'PENDENTE', Colors.orange),
                          _indicador('Agendados', 'AGENDADO', Colors.blue),
                          _indicador('Pagos', 'PAGO', Colors.green),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children:
                            [
                                  null,
                                  'BLOQUEADO',
                                  'PENDENTE',
                                  'AGENDADO',
                                  'PAGO',
                                  'CANCELADO',
                                ]
                                .map(
                                  (s) => ChoiceChip(
                                    label: Text(s ?? 'TODOS'),
                                    selected: _filtro == s,
                                    onSelected: (_) {
                                      setState(() => _filtro = s);
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 12),
                      if (_repassesVisiveis.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('Nenhum repasse encontrado.'),
                            ),
                          ),
                        ),
                      ..._repassesVisiveis.map(
                        (r) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber.shade100,
                              child: const Icon(
                                Icons.payments,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              '${r['nmloja'] ?? 'Loja ${r['loja_id']}'} • ${_moeda.format(r['vrrepasse'] ?? 0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              'Venda #${r['venda_id']} • Bruto ${_moeda.format(r['vrbruto'] ?? 0)} • Taxa ${_moeda.format(r['vrtaxaclubbar'] ?? 0)}\nStatus: ${r['status']}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _editar(r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}
