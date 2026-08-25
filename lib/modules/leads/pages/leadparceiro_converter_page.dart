import 'package:flutter/material.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadParceiroConverterPage extends StatefulWidget {
  final LeadParceiro lead;
  const LeadParceiroConverterPage({super.key, required this.lead});

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

  @override
  void initState() {
    super.initState();
    _organizacao = TextEditingController(text: widget.lead.nmestabelecimento);
    _loja = TextEditingController(text: widget.lead.nmestabelecimento);
    _email = TextEditingController(text: widget.lead.email);
    _tipoLoja = widget.lead.tipo;
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
        nomeOrganizacao: _organizacao.text,
        nomeLoja: _loja.text,
        tipoLoja: _tipoLoja,
        emailResponsavel: _email.text,
        taxaProdutos: produtos,
        taxaIngressos: ingressos,
      );
      if (!mounted) return;
      final convite = resultado['superadmin']?['convite_enviado'] == true;
      AppSnackBar.sucesso(
        context,
        convite
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
            titulo: 'Converter em parceiro',
            subtitulo: 'Criação inicial com documentação pendente',
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
                              'Nome da organização',
                              Icons.business_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _loja,
                            validator: _obrigatorio,
                            decoration: _decoracao(
                              'Nome da loja inicial',
                              Icons.storefront_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _tipoLoja,
                            decoration: _decoracao(
                              'Tipo da loja',
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
                  const Card(
                    color: ClubbarColors.infoClaro,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'CPF/CNPJ, razão social, endereço cadastral e documentos serão preenchidos pelo parceiro no onboarding financeiro.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _convertendo ? null : _converter,
                    icon: _convertendo
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.handshake_rounded),
                    label: Text(
                      _convertendo ? 'Convertendo...' : 'Converter em parceiro',
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
