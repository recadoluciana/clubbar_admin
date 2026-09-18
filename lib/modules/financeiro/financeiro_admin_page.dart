import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/financeiro_repository.dart';
import '../../core/theme/clubbar_colors.dart';
import '../../core/widgets/app_snackbar.dart';
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
  final _data = DateFormat('dd/MM/yyyy');
  DateTime _inicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fim = DateTime.now();
  Map<String, dynamic> _dados = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resultado = await _repo.consultarExtratoAsaas(
        inicio: _inicio,
        fim: _fim,
      );
      if (mounted) setState(() => _dados = resultado);
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _inicio, end: _fim),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione o período do extrato',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ClubbarColors.ambar,
            onPrimary: ClubbarColors.preto,
            surface: ClubbarColors.branco,
            onSurface: ClubbarColors.preto,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: ClubbarColors.branco,
          ),
        ),
        child: child!,
      ),
    );
    if (intervalo != null) {
      _inicio = intervalo.start;
      _fim = intervalo.end;
      await _carregar();
    }
  }

  double _numero(Object? valor) =>
      valor is num ? valor.toDouble() : double.tryParse('$valor') ?? 0;

  String _tipoTransacao(Object? valor) {
    final tipo = valor?.toString().toUpperCase() ?? '';
    if (tipo.contains('SPLIT')) return 'Split recebido';
    if (tipo.contains('PIX')) return 'Pix';
    if (tipo.contains('CARD')) return 'Cartão';
    return valor?.toString() ?? 'Transação';
  }

  @override
  Widget build(BuildContext context) {
    final itens = (_dados['transacoes'] as List? ?? const []).cast<Map>();
    final pendentes = (_dados['recebimentos_pendentes'] as List? ?? const [])
        .cast<Map>();
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: 'Clubbar',
            subtitulo: 'Extrato de transações Asaas',
            estiloTitulo: const TextStyle(
              color: ClubbarColors.info,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
            mostrarDadosSessao: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Alterar período',
                  onPressed: _selecionarPeriodo,
                  icon: const Icon(Icons.date_range_rounded),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          color: ClubbarColors.infoClaro,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: ClubbarColors.info,
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Saldo disponível no Asaas'),
                                      Text(
                                        _moeda.format(_numero(_dados['saldo'])),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: ClubbarColors.info,
                                        ),
                                      ),
                                      Text(
                                        '${_data.format(_inicio)} a ${_data.format(_fim)}',
                                        style: const TextStyle(
                                          color: ClubbarColors.textoSecundario,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (pendentes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Card(
                            color: ClubbarColors.avisoClaro,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFFFE0B2),
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Splits aguardando liberação',
                                        ),
                                        Text(
                                          _moeda.format(
                                            _numero(_dados['total_pendente']),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        const Text(
                                          'Valores do Clubbar confirmados que ainda não entraram no saldo disponível.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                ClubbarColors.textoSecundario,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...pendentes.map((item) {
                            final valor = _numero(item['valor_liquido']);
                            final credito = DateTime.tryParse(
                              item['data_prevista_credito']?.toString() ?? '',
                            );
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: ClubbarColors.avisoClaro,
                                  child: Icon(
                                    Icons.call_split_rounded,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                title: Text(
                                  'Split Clubbar • ${_moeda.format(valor)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  credito == null
                                      ? 'Aguardando definição da data de crédito'
                                      : 'Crédito previsto para ${_data.format(credito)}',
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        const Text(
                          'Movimentações no saldo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (itens.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'Nenhuma movimentação no saldo neste período.',
                                ),
                              ),
                            ),
                          ),
                        ...itens.map((item) {
                          final valor = _numero(item['valor']);
                          final positivo = valor >= 0;
                          final data = DateTime.tryParse(
                            item['data']?.toString() ?? '',
                          );
                          final descricao =
                              item['descricao']?.toString().trim() ?? '';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    (positivo ? Colors.green : Colors.red)
                                        .withValues(alpha: .12),
                                child: Icon(
                                  positivo
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  color: positivo ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                descricao.isNotEmpty
                                    ? descricao
                                    : _tipoTransacao(item['tipo']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                data == null
                                    ? _tipoTransacao(item['tipo'])
                                    : '${_tipoTransacao(item['tipo'])} • ${_data.format(data)}',
                              ),
                              trailing: Text(
                                _moeda.format(valor),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: positivo
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
