import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/api_config.dart';
import '../../core/repositories/evento_repository.dart';
import '../../core/repositories/loja_repository.dart';
import '../../models/evento.dart';
import '../../models/loja.dart';
import 'evento_form_page.dart';
import 'evento_lote_list_page.dart';

class EventoListPage extends StatefulWidget {
  final int organizacaoId;

  const EventoListPage({
    super.key,
    required this.organizacaoId,
  });

  @override
  State<EventoListPage> createState() => _EventoListPageState();
}

class _EventoListPageState extends State<EventoListPage> {
  final EventoRepository _repository = EventoRepository();
  final LojaRepository _lojaRepository = LojaRepository();
  final TextEditingController _buscaController = TextEditingController();

  bool _carregando = true;
  bool _carregandoLojas = true;

  List<Evento> _eventos = [];
  List<Evento> _eventosFiltrados = [];

  List<Loja> _lojas = [];
  int? _lojaIdSelecionada;

  final DateFormat _formatoData = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _carregarLojas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _extrairMensagemErro(Object e) {
    final texto = e.toString();

    try {
      final inicio = texto.indexOf('{');
      final fim = texto.lastIndexOf('}');

      if (inicio != -1 && fim != -1) {
        final jsonStr = texto.substring(inicio, fim + 1);
        final jsonMap = jsonDecode(jsonStr);

        if (jsonMap is Map && jsonMap['detail'] != null) {
          return jsonMap['detail'].toString();
        }
      }
    } catch (_) {}

    return texto.replaceAll('Exception:', '').trim();
  }

  Future<void> _carregarLojas() async {
    setState(() {
      _carregandoLojas = true;
      _carregando = true;
    });

    try {
      final lojas = await _lojaRepository.listar(widget.organizacaoId);

      if (!mounted) return;

      int? lojaSelecionada = _lojaIdSelecionada;

      if (lojas.isNotEmpty) {
        final existe = lojas.any((l) => l.lojaId == lojaSelecionada);
        if (!existe) {
          lojaSelecionada = lojas.first.lojaId;
        }
      } else {
        lojaSelecionada = null;
      }

      setState(() {
        _lojas = lojas;
        _lojaIdSelecionada = lojaSelecionada;
        _carregandoLojas = false;
      });

      if (_lojaIdSelecionada != null) {
        await _carregarEventos();
      } else {
        setState(() {
          _eventos = [];
          _eventosFiltrados = [];
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoLojas = false;
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    }
  }

  Future<void> _carregarEventos() async {
    if (_lojaIdSelecionada == null) {
      setState(() {
        _eventos = [];
        _eventosFiltrados = [];
        _carregando = false;
      });
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final lista = await _repository.listar(_lojaIdSelecionada!);

      if (!mounted) return;

      setState(() {
        _eventos = lista;
        _eventosFiltrados = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _filtrar(String texto) {
    final busca = texto.trim().toLowerCase();

    setState(() {
      if (busca.isEmpty) {
        _eventosFiltrados = _eventos;
      } else {
        _eventosFiltrados = _eventos.where((evento) {
          return evento.eventoId.toString().contains(busca) ||
              evento.nmtituloevento.toLowerCase().contains(busca) ||
              (evento.statusevento ?? '').toLowerCase().contains(busca) ||
              (evento.nmlocalevento ?? '').toLowerCase().contains(busca) ||
              (evento.dsendlocevento ?? '').toLowerCase().contains(busca);
        }).toList();
      }
    });
  }

  String _formatarData(String? valor) {
    if (valor == null || valor.trim().isEmpty) return '-';

    try {
      final data = DateTime.parse(valor);
      return _formatoData.format(data);
    } catch (_) {
      return valor;
    }
  }

  String _montarUrlBanner(Evento evento) {
    final banner = (evento.urlbannerevento ?? '').trim();

    if (banner.isEmpty) return '';

    if (banner.startsWith('http')) {
      return banner;
    }

    final path = banner.startsWith('/') ? banner : '/$banner';
    return '${ApiConfig.baseUrl}$path';
  }

  Future<void> _abrirNovoEvento() async {
    if (_lojaIdSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma loja')),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventoFormPage(
          organizacaoId: widget.organizacaoId,
          lojaId: _lojaIdSelecionada!,
        ),
      ),
    );

    if (result == true) {
      _carregarEventos();
    }
  }

  Future<void> _abrirEdicao(Evento evento) async {
    if (_lojaIdSelecionada == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventoFormPage(
          organizacaoId: widget.organizacaoId,
          lojaId: _lojaIdSelecionada!,
          evento: evento,
        ),
      ),
    );

    if (result == true) {
      _carregarEventos();
    }
  }

  Future<void> _abrirLotes(Evento evento) async {
    if (_lojaIdSelecionada == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventoLoteListPage(
          eventoId: evento.eventoId,
          eventoTitulo: evento.nmtituloevento,
          organizacaoId: widget.organizacaoId,
          lojaId: _lojaIdSelecionada!,
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(Evento evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text(
          'Deseja realmente excluir o evento "${evento.nmtituloevento}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repository.excluir(evento.eventoId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído com sucesso.')),
      );

      _carregarEventos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extrairMensagemErro(e))),
      );
    }
  }

  Widget _buildTabela() {
    if (_eventosFiltrados.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhum evento encontrado.'),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Banner')),
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Título')),
            DataColumn(label: Text('Início')),
            DataColumn(label: Text('Fim')),
            DataColumn(label: Text('Local')),
            DataColumn(label: Text('Endereço')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _eventosFiltrados.map((evento) {
            final urlBanner = _montarUrlBanner(evento);

            return DataRow(
              cells: [
                DataCell(
                  urlBanner.isNotEmpty
                      ? SizedBox(
                          width: 50,
                          height: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              urlBanner,
                              key: ValueKey(urlBanner),
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, __) {
                                print('ERRO IMG EVENTO LISTA: $urlBanner');
                                print('DETALHE: $error');
                                return const Icon(Icons.image_not_supported);
                              },
                            ),
                          ),
                        )
                      : const Icon(Icons.image_not_supported),
                ),
                DataCell(Text(evento.eventoId.toString())),
                DataCell(Text(evento.nmtituloevento)),
                DataCell(Text(_formatarData(evento.dtinicioevento))),
                DataCell(Text(_formatarData(evento.dtfimevento))),
                DataCell(Text(evento.nmlocalevento ?? '-')),
                DataCell(Text(evento.dsendlocevento ?? '-')),
                DataCell(Text(evento.statusevento ?? '-')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Lotes',
                        onPressed: () => _abrirLotes(evento),
                        icon: const Icon(Icons.confirmation_number),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _abrirEdicao(evento),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(evento),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _buscaController,
                    onChanged: _filtrar,
                    decoration: const InputDecoration(
                      labelText: 'Buscar evento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _carregandoLojas
                      ? const SizedBox(
                          height: 50,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<int>(
                          initialValue: _lojaIdSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Loja',
                            border: OutlineInputBorder(),
                          ),
                          items: _lojas.map((loja) {
                            return DropdownMenuItem<int>(
                              value: loja.lojaId,
                              child: Text(loja.nmloja),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _lojaIdSelecionada = value;
                            });
                            _carregarEventos();
                          },
                        ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _abrirNovoEvento,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _carregarEventos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabela(),
            ),
          ],
        ),
      ),
    );
  }
}