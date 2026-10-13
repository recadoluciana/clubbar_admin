import 'package:flutter/material.dart';

import '../../core/repositories/catalogo_ingresso_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class CatalogoIngressosAdminPage extends StatefulWidget {
  const CatalogoIngressosAdminPage({super.key});
  @override
  State<CatalogoIngressosAdminPage> createState() => _State();
}

class _State extends State<CatalogoIngressosAdminPage> {
  final repo = CatalogoIngressoRepository();
  List<ModalidadeCatalogo> modalidades = [];
  List<BeneficioCatalogo> beneficios = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  void aviso(Object erro) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(erro.toString().replaceFirst('Exception: ', ''))),
  );

  Future<void> carregar() async {
    setState(() => carregando = true);
    try {
      final r = await Future.wait([
        repo.listarModalidades(),
        repo.listarBeneficios(),
      ]);
      modalidades = r[0] as List<ModalidadeCatalogo>;
      beneficios = r[1] as List<BeneficioCatalogo>;
    } catch (e) {
      if (mounted) aviso(e);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> editarBeneficio([BeneficioCatalogo? atual]) async {
    final codigo = TextEditingController(text: atual?.codigo ?? '');
    final nome = TextEditingController(text: atual?.nome ?? '');
    final ordem = TextEditingController(
      text: '${atual?.ordem ?? beneficios.length + 1}',
    );
    var comprovante = atual?.exigeComprovante ?? true;
    var ativo = (atual?.situacao ?? 'ATIVO') == 'ATIVO';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(atual == null ? 'Novo benefício' : 'Editar benefício'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codigo,
                  decoration: const InputDecoration(labelText: 'Código'),
                ),
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: ordem,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ordem'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: comprovante,
                  onChanged: (v) => setDialogState(() => comprovante = v),
                  title: const Text('Exige comprovante'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: ativo,
                  onChanged: (v) => setDialogState(() => ativo = v),
                  title: const Text('Ativo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await repo.salvarBeneficio(atual, {
        'cdbeneficio': codigo.text.trim().toUpperCase(),
        'nmbeneficio': nome.text.trim(),
        'exigecomprovante': comprovante,
        'situacao': ativo ? 'ATIVO' : 'INATIVO',
        'nrordem': int.tryParse(ordem.text) ?? 1,
      });
      await carregar();
    } catch (e) {
      if (mounted) aviso(e);
    }
  }

  Future<void> editarModalidade([ModalidadeCatalogo? atual]) async {
    final codigo = TextEditingController(text: atual?.codigo ?? '');
    final nome = TextEditingController(text: atual?.nome ?? '');
    final ordem = TextEditingController(
      text: '${atual?.ordem ?? modalidades.length + 1}',
    );
    var tipo = atual?.tipo ?? 'COMERCIAL';
    var cota = atual?.aplicaCotaLegal ?? false;
    var exigeBeneficio = atual?.exigeBeneficio ?? false;
    var comprovante = atual?.exigeComprovante ?? false;
    var personaliza = atual?.permitePersonalizarNome ?? true;
    var ativo = (atual?.situacao ?? 'ATIVO') == 'ATIVO';
    final selecionados = <int>{...?atual?.beneficios.map((e) => e.id)};
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(atual == null ? 'Nova modalidade' : 'Editar modalidade'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codigo,
                    readOnly: atual != null,
                    decoration: InputDecoration(
                      labelText: atual == null ? 'Código' : 'Código (fixo)',
                      suffixIcon: atual == null
                          ? null
                          : const Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    items: const ['PADRAO', 'LEGAL', 'COMERCIAL']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => tipo = v!),
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ordem,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: cota,
                    onChanged: (v) => setDialogState(() => cota = v),
                    title: const Text('Aplica cota legal'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: exigeBeneficio,
                    onChanged: (v) => setDialogState(() => exigeBeneficio = v),
                    title: const Text('Exige escolha de benefício'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: comprovante,
                    onChanged: (v) => setDialogState(() => comprovante = v),
                    title: const Text('Exige comprovante'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: personaliza,
                    onChanged: (v) => setDialogState(() => personaliza = v),
                    title: const Text('Parceiro pode personalizar o nome'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: ativo,
                    onChanged: (v) => setDialogState(() => ativo = v),
                    title: const Text('Ativa'),
                  ),
                  if (exigeBeneficio) ...[
                    const Divider(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Benefícios permitidos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...beneficios
                        .where((b) => b.situacao == 'ATIVO')
                        .map(
                          (b) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selecionados.contains(b.id),
                            onChanged: (v) => setDialogState(() {
                              if (v == true) {
                                selecionados.add(b.id);
                              } else {
                                selecionados.remove(b.id);
                              }
                            }),
                            title: Text(b.nome),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await repo.salvarModalidade(atual, {
        'cdmodalidade': codigo.text.trim().toUpperCase(),
        'nmmodalidade': nome.text.trim(),
        'organizacao_id': null,
        'tipomodalidade': tipo,
        'aplicacotalegal': cota,
        'exigebeneficio': exigeBeneficio,
        'exigecomprovante': comprovante,
        'permitepersonalizarnome': personaliza,
        'situacao': ativo ? 'ATIVO' : 'INATIVO',
        'nrordem': int.tryParse(ordem.text) ?? 1,
        'beneficios_ids': selecionados.toList(),
      });
      await carregar();
    } catch (e) {
      if (mounted) aviso(e);
    }
  }

  Future<void> excluirModalidade(ModalidadeCatalogo item) async {
    try {
      await repo.excluirModalidade(item.id);
      await carregar();
    } catch (e) {
      if (mounted) aviso(e);
    }
  }

  Future<void> excluirBeneficio(BeneficioCatalogo item) async {
    try {
      await repo.excluirBeneficio(item.id);
      await carregar();
    } catch (e) {
      if (mounted) aviso(e);
    }
  }

  Color corDaModalidade(ModalidadeCatalogo modalidade) =>
      switch (modalidade.tipo) {
        'LEGAL' => Colors.deepOrange,
        'PADRAO' => Colors.blue,
        _ => Colors.teal,
      };

  IconData iconeDaModalidade(ModalidadeCatalogo modalidade) =>
      switch (modalidade.tipo) {
        'LEGAL' => Icons.gavel_rounded,
        'PADRAO' => Icons.confirmation_number_rounded,
        _ => Icons.local_offer_rounded,
      };

  Widget etiqueta(String texto, {Color? cor}) {
    final color = cor ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget cardModalidade(ModalidadeCatalogo modalidade) {
    final cor = corDaModalidade(modalidade);
    final beneficiosNomes = modalidade.beneficios.map((b) => b.nome).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconeDaModalidade(modalidade), color: cor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          modalidade.nome,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      etiqueta(
                        modalidade.situacao == 'ATIVO' ? 'ATIVA' : 'INATIVA',
                        cor: modalidade.situacao == 'ATIVO'
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Código fixo: ${modalidade.codigo}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      etiqueta(modalidade.tipo, cor: cor),
                      etiqueta(
                        modalidade.aplicaCotaLegal
                            ? 'Aplica cota legal'
                            : 'Não aplica cota legal',
                        cor: modalidade.aplicaCotaLegal
                            ? Colors.deepOrange
                            : Colors.blueGrey,
                      ),
                      if (modalidade.exigeBeneficio)
                        etiqueta(
                          '${beneficiosNomes.length} ${beneficiosNomes.length == 1 ? 'benefício' : 'benefícios'}',
                          cor: Colors.indigo,
                        ),
                      if (modalidade.exigeComprovante)
                        etiqueta('Exige comprovante', cor: Colors.purple),
                    ],
                  ),
                  if (beneficiosNomes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Benefícios vinculados',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: beneficiosNomes
                          .map((nome) => etiqueta(nome, cor: Colors.indigo))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  tooltip: 'Editar modalidade',
                  onPressed: () => editarModalidade(modalidade),
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                ),
                IconButton(
                  tooltip: 'Excluir modalidade',
                  onPressed: () => excluirModalidade(modalidade),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget listaModalidades() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.brown),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cada modalidade reúne as regras de venda, como tipo e cota legal. Os benefícios abaixo indicam quem pode utilizá-la.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => editarModalidade(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Cadastrar modalidade'),
      ),
      const SizedBox(height: 18),
      Text(
        '${modalidades.length} modalidades cadastradas',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      ...modalidades.map(cardModalidade),
    ],
  );

  Widget listaBeneficios() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      FilledButton.icon(
        onPressed: () => editarBeneficio(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Cadastrar benefício'),
      ),
      const SizedBox(height: 18),
      ...beneficios.map(
        (b) => Card(
          child: ListTile(
            title: Text(b.nome),
            subtitle: Text(
              '${b.codigo} • ${b.exigeComprovante ? 'Com comprovante' : 'Sem comprovante'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(label: Text(b.situacao)),
                IconButton(
                  onPressed: () => editarBeneficio(b),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => excluirBeneficio(b),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          const ClubbarPageHeader(
            titulo: 'Modalidades de ingresso',
            subtitulo: 'Configure regras de venda e os benefícios aceitos',
            mostrarDadosSessao: false,
          ),
          TabBar(
            tabs: [
              Tab(text: 'Modalidades (${modalidades.length})'),
              Tab(text: 'Catálogo de benefícios (${beneficios.length})'),
            ],
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(children: [listaModalidades(), listaBeneficios()]),
          ),
        ],
      ),
    ),
  );
}
