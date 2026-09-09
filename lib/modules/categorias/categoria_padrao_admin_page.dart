import 'package:flutter/material.dart';

import '../../core/repositories/categoria_padrao_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class CategoriaPadraoAdminPage extends StatefulWidget {
  const CategoriaPadraoAdminPage({super.key});

  @override
  State<CategoriaPadraoAdminPage> createState() =>
      _CategoriaPadraoAdminPageState();
}

class _CategoriaPadraoAdminPageState extends State<CategoriaPadraoAdminPage> {
  final _repo = CategoriaPadraoRepository();
  final _busca = TextEditingController();
  List<CategoriaPadraoAdmin> _itens = [];
  final Set<int> _alterando = {};
  bool _carregando = true;

  static const _iconesDisponiveis = <String, IconData>{
    'category': Icons.category_rounded,
    'water_drop': Icons.water_drop_rounded,
    'local_drink': Icons.local_drink_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'bolt': Icons.bolt_rounded,
    'sports_bar': Icons.sports_bar_rounded,
    'no_drinks': Icons.no_drinks_rounded,
    'local_bar': Icons.local_bar_rounded,
    'liquor': Icons.liquor_rounded,
    'wine_bar': Icons.wine_bar_rounded,
    'coffee': Icons.coffee_rounded,
    'soup_kitchen': Icons.soup_kitchen_rounded,
    'tapas': Icons.tapas_rounded,
    'restaurant': Icons.restaurant_rounded,
    'lunch_dining': Icons.lunch_dining_rounded,
    'outdoor_grill': Icons.outdoor_grill_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_pizza': Icons.local_pizza_rounded,
    'dinner_dining': Icons.dinner_dining_rounded,
    'eco': Icons.eco_rounded,
    'cake': Icons.cake_rounded,
    'icecream': Icons.icecream_rounded,
    'inventory_2': Icons.inventory_2_rounded,
    'sell': Icons.sell_rounded,
    'celebration': Icons.celebration_rounded,
    'event_seat': Icons.event_seat_rounded,
    'event': Icons.event_rounded,
    'checkroom': Icons.checkroom_rounded,
    'redeem': Icons.redeem_rounded,
    'more_horiz': Icons.more_horiz_rounded,
  };

  IconData _icone(String nome) =>
      _iconesDisponiveis[nome] ?? Icons.category_rounded;

  List<CategoriaPadraoAdmin> get _filtrados {
    final termo = _busca.text.trim().toLowerCase();
    return termo.isEmpty
        ? _itens
        : _itens.where((e) => e.nome.toLowerCase().contains(termo)).toList();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final itens = await _repo.listar();
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alterarSituacao(CategoriaPadraoAdmin item, bool ativa) async {
    setState(() => _alterando.add(item.id));
    try {
      await _repo.alterarSituacao(item.id, ativa);
      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _alterando.remove(item.id));
    }
  }

  Future<void> _adicionar() async {
    final nome = TextEditingController();
    var icone = 'category';
    final chave = GlobalKey<FormState>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, atualizarDialog) => AlertDialog(
          title: const Text('Adicionar categoria'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: chave,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nome,
                    autofocus: true,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Nome da categoria',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                        valor == null || valor.trim().length < 2
                        ? 'Informe o nome da categoria'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: icone,
                    decoration: const InputDecoration(
                      labelText: 'Ícone',
                      border: OutlineInputBorder(),
                    ),
                    items: _iconesDisponiveis.entries
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.key,
                            child: Row(
                              children: [
                                Icon(item.value),
                                const SizedBox(width: 10),
                                Text(item.key),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) =>
                        atualizarDialog(() => icone = valor ?? 'category'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
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
      ),
    );
    if (confirmou != true) return;
    try {
      await _repo.criar(nome.text.trim(), icone);
      await _carregar();
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
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itens = _filtrados;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: 'Categorias de produtos',
            subtitulo: 'Catálogo geral do Clubbar',
            mostrarDadosSessao: false,
            trailing: IconButton(
              tooltip: 'Atualizar',
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextField(
              controller: _busca,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Buscar categoria',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'As categorias deste catálogo não podem ser alteradas ou excluídas. Somente o status pode ser modificado.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _adicionar,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar categoria'),
              ),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: itens.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 90),
                              Icon(Icons.category_outlined, size: 54),
                              Center(
                                child: Text('Nenhuma categoria encontrada.'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                            itemCount: itens.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = itens[i];
                              final ativa = item.situacao == 'ATIVA';
                              final alterando = _alterando.contains(item.id);
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: ativa
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade200,
                                    child: Icon(_icone(item.icone)),
                                  ),
                                  title: Text(
                                    item.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item.icone} • Ordem ${item.ordem}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: alterando
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: ativa
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: ativa
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                              child: Text(
                                                ativa ? 'Ativo' : 'Inativo',
                                                style: TextStyle(
                                                  color: ativa
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Switch.adaptive(
                                              value: ativa,
                                              activeTrackColor: Colors.green,
                                              onChanged: (valor) =>
                                                  _alterarSituacao(item, valor),
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
}
