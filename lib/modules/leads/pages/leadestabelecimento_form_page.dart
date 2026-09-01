import 'package:flutter/material.dart';

import '../../../core/theme/clubbar_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/clubbar_app_bar.dart';
import '../../../core/widgets/clubbar_page_header.dart';
import '../models/leadparceiro.dart';
import '../repositories/leadparceiro_repository.dart';

class LeadEstabelecimentoFormPage extends StatefulWidget {
  final LeadParceiro lead;

  const LeadEstabelecimentoFormPage({super.key, required this.lead});

  @override
  State<LeadEstabelecimentoFormPage> createState() =>
      _LeadEstabelecimentoFormPageState();
}

class _LeadEstabelecimentoFormPageState
    extends State<LeadEstabelecimentoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = LeadParceiroRepository();
  final _nome = TextEditingController();
  final _documento = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _cep = TextEditingController();
  final _endereco = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _mensagem = TextEditingController();

  List<Map<String, dynamic>> _estados = [];
  List<Map<String, dynamic>> _cidades = [];
  int? _estadoId;
  int? _cidadeId;
  String _tipo = 'BAR';
  String _tipoVenda = 'AMBOS';
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _telefone.text = widget.lead.telefone;
    _email.text = widget.lead.email;
    _tipo = widget.lead.tipo.isEmpty ? 'BAR' : widget.lead.tipo;
    _carregarLocalidades();
  }

  @override
  void dispose() {
    for (final controller in [
      _nome,
      _documento,
      _telefone,
      _email,
      _cep,
      _endereco,
      _numero,
      _complemento,
      _bairro,
      _mensagem,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _id(Map<String, dynamic> item, String chave) =>
      int.tryParse(item[chave]?.toString() ?? '') ?? 0;

  Future<void> _carregarLocalidades() async {
    try {
      final estados = await _repo.listarEstados();
      final estadoId = widget.lead.estadoId > 0 ? widget.lead.estadoId : null;
      final cidades = estadoId == null
          ? <Map<String, dynamic>>[]
          : await _repo.listarCidades(estadoId);
      if (!mounted) return;
      setState(() {
        _estados = estados;
        _estadoId = estadoId;
        _cidades = cidades;
        _cidadeId =
            cidades.any(
              (item) => _id(item, 'cidade_id') == widget.lead.cidadeId,
            )
            ? widget.lead.cidadeId
            : null;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _alterarEstado(int estadoId) async {
    setState(() {
      _estadoId = estadoId;
      _cidadeId = null;
      _cidades = [];
    });
    try {
      final cidades = await _repo.listarCidades(estadoId);
      if (mounted) setState(() => _cidades = cidades);
    } catch (e) {
      if (mounted) {
        AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  String? _opcional(TextEditingController controller) {
    final valor = controller.text.trim();
    return valor.isEmpty ? null : valor;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await _repo.adicionarEstabelecimento(widget.lead.leadparceiroId, {
        'nmestabelecimento': _nome.text.trim(),
        'tipo': _tipo,
        'tipovenda': _tipoVenda,
        'cpfcnpj': _opcional(_documento),
        'telefone': _opcional(_telefone),
        'email': _opcional(_email),
        'estado_id': _estadoId,
        'cidade_id': _cidadeId,
        'cep': _opcional(_cep),
        'endereco': _opcional(_endereco),
        'numero': _opcional(_numero),
        'complemento': _opcional(_complemento),
        'bairro': _opcional(_bairro),
        'mensagem': _opcional(_mensagem),
      });
      if (!mounted) return;
      AppSnackBar.sucesso(context, 'Estabelecimento cadastrado com sucesso.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      setState(() => _salvando = false);
    }
  }

  InputDecoration _decoracao(String label, IconData icone) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icone),
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClubbarColors.fundo,
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: 'Novo estabelecimento',
            subtitulo: 'Lead: ${widget.lead.nmresponsavel}',
            icone: Icons.add_business_rounded,
            mostrarDadosSessao: false,
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextFormField(
                          controller: _nome,
                          decoration: _decoracao(
                            'Nome do estabelecimento',
                            Icons.storefront_rounded,
                          ),
                          validator: (v) => (v?.trim().length ?? 0) < 2
                              ? 'Informe o nome do estabelecimento.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _tipo,
                          decoration: _decoracao(
                            'Tipo',
                            Icons.category_rounded,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'BAR', child: Text('Bar')),
                            DropdownMenuItem(
                              value: 'CASA_NOTURNA',
                              child: Text('Casa noturna'),
                            ),
                            DropdownMenuItem(
                              value: 'CASA_EVENTOS',
                              child: Text('Casa de eventos'),
                            ),
                            DropdownMenuItem(
                              value: 'PRODUTOR_EVENTOS',
                              child: Text('Produtor de eventos'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _tipo = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _tipoVenda,
                          decoration: _decoracao(
                            'O que pretende vender',
                            Icons.sell_rounded,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'AMBOS',
                              child: Text('Produtos e ingressos'),
                            ),
                            DropdownMenuItem(
                              value: 'PRODUTOS',
                              child: Text('Produtos'),
                            ),
                            DropdownMenuItem(
                              value: 'INGRESSOS',
                              child: Text('Ingressos'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _tipoVenda = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _documento,
                          decoration: _decoracao(
                            'CPF/CNPJ',
                            Icons.badge_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telefone,
                          keyboardType: TextInputType.phone,
                          decoration: _decoracao(
                            'Telefone',
                            Icons.phone_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoracao('E-mail', Icons.email_rounded),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _estadoId,
                                isExpanded: true,
                                decoration: _decoracao(
                                  'Estado',
                                  Icons.map_rounded,
                                ),
                                items: _estados
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: _id(item, 'estado_id'),
                                        child: Text(
                                          item['sgestado']?.toString() ??
                                              item['nmestado']?.toString() ??
                                              '',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                validator: (v) =>
                                    v == null ? 'Selecione o estado.' : null,
                                onChanged: (v) {
                                  if (v != null) _alterarEstado(v);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _cidadeId,
                                isExpanded: true,
                                decoration: _decoracao(
                                  'Cidade',
                                  Icons.location_city_rounded,
                                ),
                                items: _cidades
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: _id(item, 'cidade_id'),
                                        child: Text(
                                          item['nmcidade']?.toString() ?? '',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                validator: (v) =>
                                    v == null ? 'Selecione a cidade.' : null,
                                onChanged: (v) => setState(() => _cidadeId = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cep,
                          decoration: _decoracao('CEP', Icons.pin_drop_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _endereco,
                          decoration: _decoracao(
                            'Endereço',
                            Icons.route_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _numero,
                                decoration: _decoracao('Número', Icons.numbers),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _bairro,
                                decoration: _decoracao(
                                  'Bairro',
                                  Icons.location_on_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _complemento,
                          decoration: _decoracao(
                            'Complemento',
                            Icons.apartment_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mensagem,
                          maxLines: 3,
                          decoration: _decoracao(
                            'Observações',
                            Icons.notes_rounded,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _salvando ? null : _salvar,
                          icon: _salvando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _salvando
                                ? 'Salvando...'
                                : 'Cadastrar estabelecimento',
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
