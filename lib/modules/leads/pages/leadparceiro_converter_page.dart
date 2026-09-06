import 'package:flutter/material.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadParceiroConverterPage extends StatefulWidget {
  final LeadParceiro lead;
  final LeadEstabelecimento estabelecimento;
  const LeadParceiroConverterPage({
    super.key,
    required this.lead,
    required this.estabelecimento,
  });

  @override
  State<LeadParceiroConverterPage> createState() =>
      _LeadParceiroConverterPageState();
}

class _LeadParceiroConverterPageState extends State<LeadParceiroConverterPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = LeadParceiroRepository();
  late final TextEditingController _organizacao;
  late final TextEditingController _loja;
  late final TextEditingController _email;
  final _taxaProdutos = TextEditingController(text: '5,00');
  final _taxaIngressos = TextEditingController(text: '5,00');
  late String _tipoLoja;
  bool _convertendo = false;
  bool _carregandoContrato = true;
  Map<String, dynamic>? _contrato;
  String? _erroContrato;

  @override
  void initState() {
    super.initState();
    _organizacao = TextEditingController(
      text: (widget.lead.nmorganizacao?.trim().isNotEmpty ?? false)
          ? widget.lead.nmorganizacao!
          : widget.lead.nmestabelecimento,
    );
    _loja = TextEditingController(text: widget.estabelecimento.nome);
    _email = TextEditingController(text: widget.lead.email);
    _tipoLoja = widget.estabelecimento.tipo;
    _carregarContrato();
  }

  Future<void> _carregarContrato() async {
    try {
      final contratos = await _repository.listarContratos(
        widget.estabelecimento.id,
      );
      final aceitos = contratos.where((item) => item['status'] == 'ACEITO');
      final contrato = aceitos.isEmpty ? null : aceitos.first;
      if (!mounted) return;
      setState(() {
        _contrato = contrato;
        _carregandoContrato = false;
        if (contrato == null) _erroContrato = 'Contrato aceito não encontrado.';
        final razao = contrato?['nmrazaosocial']?.toString().trim() ?? '';
        if (razao.isNotEmpty) _organizacao.text = razao;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoContrato = false;
        _erroContrato = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _documentoFormatado(String valor) {
    final n = valor.replaceAll(RegExp(r'\D'), '');
    if (n.length == 11) {
      return '${n.substring(0, 3)}.${n.substring(3, 6)}.${n.substring(6, 9)}-${n.substring(9)}';
    }
    if (n.length == 14) {
      return '${n.substring(0, 2)}.${n.substring(2, 5)}.${n.substring(5, 8)}/${n.substring(8, 12)}-${n.substring(12)}';
    }
    return valor;
  }

  String get _enderecoContrato {
    final c = _contrato ?? const <String, dynamic>{};
    final partes = <String>[
      [
        c['enderecocontratante'],
        c['numerocontratante'],
      ].where((item) => item?.toString().trim().isNotEmpty == true).join(', '),
      c['complementocontratante']?.toString() ?? '',
      c['bairrocontratante']?.toString() ?? '',
      c['cepcontratante']?.toString() ?? '',
    ].where((item) => item.trim().isNotEmpty).toList();
    return partes.isEmpty ? 'Não informado' : partes.join(' • ');
  }

  @override
  void dispose() {
    _organizacao.dispose();
    _loja.dispose();
    _email.dispose();
    _taxaProdutos.dispose();
    _taxaIngressos.dispose();
    super.dispose();
  }

  double? _percentual(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _obrigatorio(String? valor) =>
      valor == null || valor.trim().isEmpty ? 'Campo obrigatório' : null;

  Future<void> _converter() async {
    if (_contrato == null) {
      AppSnackBar.aviso(
        context,
        'Carregue um contrato aceito antes de converter.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final produtos = _percentual(_taxaProdutos);
    final ingressos = _percentual(_taxaIngressos);
    if (produtos == null ||
        produtos < 0 ||
        produtos > 100 ||
        ingressos == null ||
        ingressos < 0 ||
        ingressos > 100) {
      AppSnackBar.aviso(context, 'Informe taxas entre 0% e 100%.');
      return;
    }
    setState(() => _convertendo = true);
    try {
      final resultado = await _repository.converterEmParceiro(
        leadparceiroId: widget.lead.leadparceiroId,
        leadestabelecimentoId: widget.estabelecimento.id,
        nomeOrganizacao: _organizacao.text,
        nomeLoja: _loja.text,
        tipoLoja: _tipoLoja,
        emailResponsavel: _email.text,
        taxaProdutos: produtos,
        taxaIngressos: ingressos,
      );
      if (!mounted) return;
      final convite = resultado['superadmin']?['convite_enviado'] == true;
      final criouUsuario = resultado['superadmin']?['senha_inicial'] != null;
      AppSnackBar.sucesso(
        context,
        !criouUsuario
            ? 'Estabelecimento convertido e nova estabelecimento criado.'
            : convite
            ? 'Parceiro criado e convite enviado por e-mail.'
            : 'Parceiro criado. O convite não pôde ser enviado; informe a senha inicial ao responsável.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppSnackBar.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _convertendo = false);
    }
  }

  InputDecoration _decoracao(String label, IconData icon, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          const ClubbarPageHeader(
            titulo: 'Converter estabelecimento em parceiro',
            subtitulo:
                'Criação do estabelecimento com documentação financeira pendente',
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _organizacao,
                            validator: _obrigatorio,
                            decoration: _decoracao(
                              'Nome da empresa',
                              Icons.business_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _loja,
                            validator: _obrigatorio,
                            decoration: _decoracao(
                              'Nome do estabelecimento',
                              Icons.storefront_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _tipoLoja,
                            decoration: _decoracao(
                              'Tipo do estabelecimento',
                              Icons.category_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'BAR',
                                child: Text('Bar'),
                              ),
                              DropdownMenuItem(
                                value: 'CASA_NOTURNA',
                                child: Text('Casa noturna'),
                              ),
                              DropdownMenuItem(
                                value: 'PRODUTOR_EVENTOS',
                                child: Text('Produtor de eventos'),
                              ),
                              DropdownMenuItem(
                                value: 'CASA_EVENTOS',
                                child: Text('Casa de eventos'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _tipoLoja = v!),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _email,
                            validator: (v) =>
                                _obrigatorio(v) ??
                                (v!.contains('@') ? null : 'E-mail inválido'),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoracao(
                              'E-mail do responsável',
                              Icons.alternate_email_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _taxaProdutos,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _decoracao(
                                    'Taxa de produtos',
                                    Icons.percent,
                                    suffix: '%',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _taxaIngressos,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _decoracao(
                                    'Taxa de ingressos',
                                    Icons.percent,
                                    suffix: '%',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: ClubbarColors.infoClaro,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _carregandoContrato
                          ? const Center(child: CircularProgressIndicator())
                          : _erroContrato != null
                          ? Text(_erroContrato!)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dados cadastrais do contrato',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'CPF/CNPJ: ${_documentoFormatado(_contrato?['cpfcnpjcontratante']?.toString() ?? '')}',
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_contrato?['tipopessoa'] == 'PJ' ? 'Razão social' : 'Nome completo'}: ${_contrato?['nmrazaosocial'] ?? 'Não informado'}',
                                ),
                                const SizedBox(height: 6),
                                Text('Endereço cadastral: $_enderecoContrato'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed:
                        _convertendo || _carregandoContrato || _contrato == null
                        ? null
                        : _converter,
                    icon: _convertendo
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.handshake_rounded),
                    label: Text(
                      _convertendo
                          ? 'Convertendo...'
                          : 'Converter estabelecimento em parceiro',
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
}
