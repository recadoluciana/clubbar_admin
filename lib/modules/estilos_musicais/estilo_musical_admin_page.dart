import 'package:flutter/material.dart';

import '../../core/repositories/estilo_musical_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class EstiloMusicalAdminPage extends StatefulWidget {
  const EstiloMusicalAdminPage({super.key});
  @override
  State<EstiloMusicalAdminPage> createState() => _State();
}

class _State extends State<EstiloMusicalAdminPage> {
  final repo = EstiloMusicalRepository();
  final busca = TextEditingController();
  List<EstiloMusicalAdmin> itens = [];
  final Set<int> alterando = {};
  bool loading = true;

  List<EstiloMusicalAdmin> get filtrados {
    final termo = busca.text.trim().toLowerCase();
    return termo.isEmpty
        ? itens
        : itens
              .where((item) => item.nome.toLowerCase().contains(termo))
              .toList();
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => loading = true);
    try {
      itens = await repo.listar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> alternarSituacao(EstiloMusicalAdmin item, bool ativo) async {
    setState(() => alterando.add(item.id));
    try {
      await repo.alterarSituacao(item, ativo ? 'ATIVO' : 'INATIVO');
      await carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => alterando.remove(item.id));
    }
  }

  Future<void> adicionar() async {
    final nome = TextEditingController();
    final chave = GlobalKey<FormState>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adicionar estilo musical'),
        content: Form(
          key: chave,
          child: TextFormField(
            controller: nome,
            autofocus: true,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Nome do estilo',
              border: OutlineInputBorder(),
            ),
            validator: (valor) => valor == null || valor.trim().isEmpty
                ? 'Informe o nome do estilo'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (chave.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await repo.salvar(null, nome.text.trim(), 'ATIVO');
      await carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  void dispose() {
    busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    body: Column(
      children: [
        ClubbarPageHeader(
          titulo: 'Estilos musicais',
          subtitulo: 'Catálogo geral do Clubbar',
          mostrarDadosSessao: false,
          trailing: IconButton(
            onPressed: carregar,
            icon: const Icon(Icons.refresh),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: TextField(
            controller: busca,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar estilo musical',
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 6, 18, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Os nomes do catálogo não podem ser alterados e os estilos não podem ser excluídos. Somente o status pode ser modificado.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: adicionar,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar estilo'),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: carregar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = filtrados[i];
                      final ativo = e.situacao == 'ATIVO';
                      final estaAlterando = alterando.contains(e.id);
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.music_note),
                          ),
                          title: Text(
                            e.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Catálogo Clubbar'),
                          trailing: estaAlterando
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ativo
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: ativo
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      child: Text(
                                        ativo ? 'Ativo' : 'Inativo',
                                        style: TextStyle(
                                          color: ativo
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Switch.adaptive(
                                      value: ativo,
                                      activeTrackColor: Colors.green,
                                      onChanged: (valor) =>
                                          alternarSituacao(e, valor),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}
