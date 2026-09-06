import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/contrato_padrao_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class ContratoPadraoPage extends StatefulWidget {
  const ContratoPadraoPage({super.key});
  @override
  State<ContratoPadraoPage> createState() => _ContratoPadraoPageState();
}

class _ContratoPadraoPageState extends State<ContratoPadraoPage> {
  final _repo = ContratoPadraoRepository();
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;

  @override
  void initState() { super.initState(); _carregar(); }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try { _itens = await _repo.listar(); }
    catch (e) { if (mounted) _mensagem('$e', erro: true); }
    finally { if (mounted) setState(() => _carregando = false); }
  }

  void _mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto.replaceFirst('Exception: ', '')),
      backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  Future<void> _novaVersao() async {
    Map<String, dynamic>? atual;
    for (final item in _itens) {
      if (item['sitcontrato'] == 'ATIVO') { atual = item; break; }
    }
    final versao = TextEditingController();
    final titulo = TextEditingController(text: atual?['titulo']?.toString() ?? 'Termo de Parceria Comercial Clubbar');
    final valorAtual = atual?['vrimplantacao'];
    final valor = TextEditingController(
      text: (valorAtual is num ? valorAtual.toDouble() : double.tryParse('$valorAtual') ?? 0)
          .toStringAsFixed(2).replaceAll('.', ','),
    );
    final conteudo = TextEditingController(text: atual?['conteudomodelo']?.toString() ?? '');
    final form = GlobalKey<FormState>();
    final confirmar = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Publicar nova versão'),
      content: SizedBox(width: 850, child: Form(key: form, child: SingleChildScrollView(child: Column(children: [
        TextFormField(controller: versao, decoration: const InputDecoration(labelText: 'Nova versão *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Informe a versão' : null),
        const SizedBox(height: 12),
        TextFormField(controller: titulo, decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().length < 3 ? 'Informe o título' : null),
        const SizedBox(height: 12),
        TextFormField(controller: valor, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))], decoration: const InputDecoration(labelText: 'Taxa única de implantação', prefixText: 'R\$ ', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        const Align(alignment: Alignment.centerLeft, child: Text('Mantenha os marcadores entre {{ }} para preencher automaticamente os dados do parceiro.', style: TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        TextFormField(controller: conteudo, minLines: 18, maxLines: 26, decoration: const InputDecoration(labelText: 'Conteúdo do contrato *', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (v) => v == null || v.trim().length < 100 ? 'O contrato precisa ter conteúdo completo' : null),
      ])))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton.icon(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, true); }, icon: const Icon(Icons.publish_rounded), label: const Text('Publicar'))],
    ));
    if (confirmar != true) return;
    try {
      await _repo.publicar({'versao': versao.text.trim(), 'titulo': titulo.text.trim(), 'vrimplantacao': double.tryParse(valor.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0, 'conteudomodelo': conteudo.text.trim()});
      if (mounted) _mensagem('Nova versão publicada. A versão anterior foi preservada.');
      await _carregar();
    } catch (e) { if (mounted) _mensagem('$e', erro: true); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    floatingActionButton: FloatingActionButton.extended(onPressed: _novaVersao, icon: const Icon(Icons.add_rounded), label: const Text('Nova versão')),
    body: Column(children: [
      ClubbarPageHeader(titulo: 'Contrato padrão', subtitulo: 'Versões do contrato de parceria Clubbar', mostrarDadosSessao: false, trailing: IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh_rounded))),
      Expanded(child: _carregando ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _carregar, child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), itemCount: _itens.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, indice) { final item = _itens[indice]; final ativo = item['sitcontrato'] == 'ATIVO'; return Card(child: ExpansionTile(
          leading: CircleAvatar(backgroundColor: (ativo ? Colors.green : Colors.grey).withValues(alpha: .14), child: Icon(Icons.description_rounded, color: ativo ? Colors.green.shade700 : Colors.grey.shade700)),
          title: Text('${item['titulo']} • versão ${item['versao']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${ativo ? 'ATIVO' : 'INATIVO'}  •  Implantação ${_moeda.format(item['vrimplantacao'] ?? 0)}'),
          trailing: ativo ? const Chip(label: Text('Versão atual'), backgroundColor: Color(0xFFE8F5E9)) : null,
          children: [Padding(padding: const EdgeInsets.all(16), child: SelectableText(item['conteudomodelo']?.toString() ?? ''))],
        )); },
      ))),
    ]),
  );
}
