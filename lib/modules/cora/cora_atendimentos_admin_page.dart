import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/cora_admin_repository.dart';
import '../../core/widgets/clubbar_app_bar.dart';
import '../../core/widgets/clubbar_page_header.dart';

class CoraAtendimentosAdminPage extends StatefulWidget {
  const CoraAtendimentosAdminPage({super.key});
  @override
  State<CoraAtendimentosAdminPage> createState() =>
      _CoraAtendimentosAdminPageState();
}

class _CoraAtendimentosAdminPageState extends State<CoraAtendimentosAdminPage> {
  final _repo = CoraAdminRepository();
  List<CoraAtendimentoResumo> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final itens = await _repo.listarAtendimentos();
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(CoraAtendimentoResumo item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoraConversaAdminPage(clienteId: item.clienteId),
      ),
    );
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _itens.fold<int>(
      0,
      (total, item) => total + item.pendentes,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const ClubbarAppBar(mostrarVoltar: true),
      body: Column(
        children: [
          ClubbarPageHeader(
            titulo: 'Cora responde',
            subtitulo: '$pendentes mensagens aguardando resposta',
            mostrarDadosSessao: false,
            trailing: IconButton(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: _itens.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Icon(Icons.forum_outlined, size: 55),
                              Center(child: Text('Nenhuma conversa iniciada.')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _itens.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = _itens[i];
                              return Card(
                                child: ListTile(
                                  onTap: () => _abrir(item),
                                  leading: CircleAvatar(
                                    backgroundColor: item.pendentes > 0
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade100,
                                    child: const Icon(Icons.person_outline),
                                  ),
                                  title: Text(item.nome),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.email),
                                      Text(
                                        item.ultimaMensagem,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.data != null)
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(item.data!),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  trailing: item.pendentes > 0
                                      ? Badge(
                                          label: Text('${item.pendentes}'),
                                          backgroundColor: Colors.red,
                                        )
                                      : const Icon(Icons.chevron_right),
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

class CoraConversaAdminPage extends StatefulWidget {
  final int clienteId;
  const CoraConversaAdminPage({super.key, required this.clienteId});
  @override
  State<CoraConversaAdminPage> createState() => _CoraConversaAdminPageState();
}

class _CoraConversaAdminPageState extends State<CoraConversaAdminPage> {
  final _repo = CoraAdminRepository();
  final _texto = TextEditingController();
  CoraAtendimentoDetalhe? _detalhe;
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final detalhe = await _repo.consultarAtendimento(widget.clienteId);
      if (mounted)
        setState(() {
          _detalhe = detalhe;
          _carregando = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _repo.responder(widget.clienteId, texto);
      _texto.clear();
      await _carregar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFEAE2),
    appBar: const ClubbarAppBar(mostrarVoltar: true),
    body: Column(
      children: [
        ClubbarPageHeader(
          titulo: _detalhe?.nome ?? 'Conversa',
          subtitulo: _detalhe?.email ?? '',
          mostrarDadosSessao: false,
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _detalhe?.mensagens.length ?? 0,
                  itemBuilder: (_, i) {
                    final m = _detalhe!.mensagens[i];
                    final cliente = m.origem == 'CLIENTE';
                    return Align(
                      alignment: cliente
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cliente
                              ? Colors.white
                              : const Color(0xFFD9FDD3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente ? _detalhe!.nome : 'Cora',
                              style: TextStyle(
                                color: cliente
                                    ? Colors.blue
                                    : Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(m.mensagem),
                            if (m.data != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  DateFormat('dd/MM HH:mm').format(m.data!),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _enviar(),
                    decoration: const InputDecoration(
                      hintText: 'Responder como Cora...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _enviando ? null : _enviar,
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
