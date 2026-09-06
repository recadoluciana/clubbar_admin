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
  List<EstiloMusicalAdmin> itens = [];
  bool loading = true;
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

  Future<void> editar([EstiloMusicalAdmin? item]) async {
    final c = TextEditingController(text: item?.nome);
    var ativo = item?.situacao != 'INATIVO';
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          title: Text(
            item == null ? 'Novo estilo musical' : 'Editar estilo musical',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c,
                decoration: const InputDecoration(labelText: 'Nome do estilo'),
                maxLength: 120,
              ),
              SwitchListTile(
                value: ativo,
                onChanged: (v) => setD(() => ativo = v),
                title: const Text('Ativo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    await repo.salvar(item, c.text.trim(), ativo ? 'ATIVO' : 'INATIVO');
    await carregar();
  }

  Future<void> excluir(EstiloMusicalAdmin item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Excluir estilo?'),
        content: Text('Deseja excluir “${item.nome}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await repo.excluir(item.id);
        await carregar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F6F6),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => editar(),
      icon: const Icon(Icons.add),
      label: const Text('Novo estilo'),
    ),
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
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: carregar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: itens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = itens[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.music_note),
                          ),
                          title: Text(
                            e.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            e.situacao == 'ATIVO' ? 'Ativo' : 'Inativo',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                onPressed: () => editar(e),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () => excluir(e),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
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
