import 'package:flutter/material.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_card.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../../manuais/manual_pdf_download.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadContratosPage extends StatefulWidget {
  final LeadParceiro lead;
  final LeadEstabelecimento estabelecimento;

  const LeadContratosPage({
    super.key,
    required this.lead,
    required this.estabelecimento,
  });

  @override
  State<LeadContratosPage> createState() => _LeadContratosPageState();
}

class _LeadContratosPageState extends State<LeadContratosPage> {
  final _repo = LeadParceiroRepository();
  bool _carregando = true;
  int? _baixandoId;
  String? _erro;
  List<Map<String, dynamic>> _documentos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  int _id(Map<String, dynamic> item) =>
      (item['leadestabelecimentocontrato_id'] as num?)?.toInt() ?? 0;

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await _repo.listarContratos(widget.estabelecimento.id);
      final assinados =
          itens
              .where(
                (item) =>
                    item['status'] == 'ACEITO' &&
                    '${item['conteudocontrato'] ?? ''}'.trim().isNotEmpty,
              )
              .toList()
            ..sort((a, b) => _id(a).compareTo(_id(b)));
      if (!mounted) return;
      setState(() {
        _documentos = assinados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  String _titulo(Map<String, dynamic> item) {
    if (item['tipoinstrumento'] == 'RETIFICACAO') {
      return 'Retificação nº ${item['nrretificacao']}';
    }
    return 'Contrato original • versão ${item['versao']}';
  }

  String _data(dynamic valor) {
    final data = DateTime.tryParse('$valor')?.toLocal();
    if (data == null) return 'Data de assinatura não informada';
    String dois(int numero) => numero.toString().padLeft(2, '0');
    return 'Assinado em ${dois(data.day)}/${dois(data.month)}/${data.year} às ${dois(data.hour)}:${dois(data.minute)}';
  }

  void _visualizar(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_titulo(item)),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: SelectableText('${item['conteudocontrato'] ?? ''}'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _baixar(Map<String, dynamic> item) async {
    final id = _id(item);
    if (id <= 0 || _baixandoId != null) return;
    setState(() => _baixandoId = id);
    try {
      final bytes = await _repo.baixarContratoPdf(id);
      final prefixo = item['tipoinstrumento'] == 'RETIFICACAO'
          ? 'retificacao-${item['nrretificacao']}'
          : 'contrato-original';
      await salvarArquivoManual(
        bytes,
        '$prefixo-clubbar-$id.pdf',
        mimeType: 'application/pdf',
        extensao: 'pdf',
      );
      if (mounted) {
        AppSnackBar.sucesso(context, 'PDF gerado com sucesso.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _baixandoId = null);
    }
  }

  Widget _card(Map<String, dynamic> item) {
    final id = _id(item);
    final hash = '${item['hashdocumento'] ?? ''}';
    return ClubbarCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: ClubbarColors.sucessoClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: ClubbarColors.sucesso,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titulo(item),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_data(item['dtaceite'])),
                    if (hash.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Hash: $hash',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ClubbarColors.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ClubbarColors.sucessoClaro,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Assinado',
                  style: TextStyle(
                    color: ClubbarColors.sucesso,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _visualizar(item),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Visualizar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _baixandoId == null ? () => _baixar(item) : null,
                  icon: _baixandoId == id
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Baixar PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: widget.estabelecimento.nome,
            subtitulo: 'Contratos e retificações',
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                ? Center(child: Text(_erro!, textAlign: TextAlign.center))
                : _documentos.isEmpty
                ? const Center(
                    child: Text('Nenhum documento contratual assinado.'),
                  )
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Histórico contratual do estabelecimento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'O contrato original e todas as retificações assinadas permanecem disponíveis para consulta.',
                          style: TextStyle(
                            color: ClubbarColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._documentos.map(_card),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
