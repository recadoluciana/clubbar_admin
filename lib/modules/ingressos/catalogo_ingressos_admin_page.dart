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
                    decoration: const InputDecoration(labelText: 'Código'),
                  ),
                  TextField(
                    controller: nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    items: const ['PADRAO', 'LEGAL', 'COMERCIAL']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => tipo = v!),
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  TextField(
                    controller: ordem,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                  ),
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

  Widget listaModalidades() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      OutlinedButton.icon(
        onPressed: () => editarModalidade(),
        icon: const Icon(Icons.add),
        label: const Text('Nova modalidade'),
      ),
      const SizedBox(height: 10),
      ...modalidades.map(
        (m) => Card(
          child: ListTile(
            title: Text(m.nome),
            subtitle: Text(
              '${m.codigo} • ${m.tipo}${m.beneficios.isEmpty ? '' : ' • ${m.beneficios.map((b) => b.nome).join(', ')}'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(label: Text(m.situacao)),
                IconButton(
                  onPressed: () => editarModalidade(m),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => excluirModalidade(m),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget listaBeneficios() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      OutlinedButton.icon(
        onPressed: () => editarBeneficio(),
        icon: const Icon(Icons.add),
        label: const Text('Novo benefício'),
      ),
      const SizedBox(height: 10),
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
            titulo: 'Modalidades e benefícios',
            subtitulo: 'Catálogo geral de ingressos do Clubbar',
            mostrarDadosSessao: false,
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Modalidades'),
              Tab(text: 'Benefícios'),
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
