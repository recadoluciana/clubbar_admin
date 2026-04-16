import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/repositories/cidade_repository.dart';
import '../../core/repositories/loja_repository.dart';
import '../../core/services/storage_service.dart';
import '../../models/cidade.dart';
import '../../models/loja.dart';

class LojaFormPage extends StatefulWidget {
  final Loja? loja;

  const LojaFormPage({super.key, this.loja});

  @override
  State<LojaFormPage> createState() => _LojaFormPageState();
}

class _LojaFormPageState extends State<LojaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = LojaRepository();
  final _cidadeRepository = CidadeRepository();
  final _picker = ImagePicker();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  final TextEditingController _diasValidadeController = TextEditingController();

  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();

  bool _salvando = false;
  bool _carregandoCidades = true;

  List<Cidade> _cidades = [];
  int? _cidadeIdSelecionada;

  XFile? _imagemSelecionada;
  Uint8List? _imagemBytes;

  bool get editando => widget.loja != null;

  @override
  void initState() {
    super.initState();

    if (widget.loja != null) {
      _nomeController.text = widget.loja!.nmloja;
      _bairroController.text = widget.loja!.dsbairroloja ?? '';
      _telefoneController.text = widget.loja!.nrtelloja ?? '';
      _horarioController.text = widget.loja!.dshorarioloja ?? '';
      _diasValidadeController.text =
          widget.loja!.nrdiavalidade?.toString() ?? '';
      _cidadeIdSelecionada = widget.loja!.cidadeId;

      _enderecoController.text = widget.loja!.endloja ?? '';
      _instagramController.text = widget.loja!.dsinstaloja ?? '';
    }

    _carregarCidades();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _bairroController.dispose();
    _telefoneController.dispose();
    _horarioController.dispose();
    _diasValidadeController.dispose();
    _enderecoController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _carregarCidades() async {
    setState(() {
      _carregandoCidades = true;
    });

    try {
      final lista = await _cidadeRepository.listar();

      if (!mounted) return;

      int? cidadeSelecionada = _cidadeIdSelecionada;

      if (lista.isNotEmpty) {
        final existeNaLista = lista.any(
          (cidade) => cidade.cidadeId == cidadeSelecionada,
        );

        if (!existeNaLista) {
          cidadeSelecionada = lista.first.cidadeId;
        }
      } else {
        cidadeSelecionada = null;
      }

      setState(() {
        _cidades = lista;
        _cidadeIdSelecionada = cidadeSelecionada;
        _carregandoCidades = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoCidades = false;
        _cidades = [];
        _cidadeIdSelecionada = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar cidades: $e')));
    }
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? arquivo = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (arquivo != null) {
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = await arquivo.readAsBytes();
        }

        setState(() {
          _imagemSelecionada = arquivo;
          _imagemBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cidadeIdSelecionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma cidade')));
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final organizacaoId = await StorageService.getOrganizacaoId();

      if (organizacaoId == null) {
        throw Exception('Organização não encontrada no login');
      }

      final diasValidadeTexto = _diasValidadeController.text.trim();
      final diasValidade = diasValidadeTexto.isEmpty
          ? null
          : int.tryParse(diasValidadeTexto);

      if (diasValidadeTexto.isNotEmpty && diasValidade == null) {
        throw Exception('Dias de validade deve ser numérico');
      }

      if (editando) {
        await _repository.atualizar(
          lojaId: widget.loja!.lojaId,
          organizacaoId: organizacaoId,
          cidadeId: _cidadeIdSelecionada!,
          nome: _nomeController.text.trim(),
          bairro: _bairroController.text.trim(),
          telefone: _telefoneController.text.trim(),
          horario: _horarioController.text.trim(),
          diasValidade: diasValidade,
          endereco: _enderecoController.text.trim(),
          instagram: _instagramController.text.trim(),
          imagem: _imagemSelecionada,
        );
      } else {
        await _repository.criar(
          organizacaoId: organizacaoId,
          cidadeId: _cidadeIdSelecionada!,
          nome: _nomeController.text.trim(),
          bairro: _bairroController.text.trim(),
          telefone: _telefoneController.text.trim(),
          horario: _horarioController.text.trim(),
          diasValidade: diasValidade,
          endereco: _enderecoController.text.trim(),
          instagram: _instagramController.text.trim(),
          imagem: _imagemSelecionada,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Loja atualizada com sucesso'
                : 'Loja criada com sucesso',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  String _montarUrlImagemAtual() {
    final imagemAtual = (widget.loja?.urllogoloja ?? '').trim();

    if (imagemAtual.isEmpty) return '';

    if (imagemAtual.startsWith('http')) {
      return imagemAtual;
    }

    final path = imagemAtual.startsWith('/') ? imagemAtual : '/$imagemAtual';
    return '${ApiConfig.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final imagemAtualUrl = _montarUrlImagemAtual();

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Loja' : 'Nova Loja'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  GestureDetector(
                    onTap: _selecionarImagem,
                    child: Container(
                      height: 140,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imagemSelecionada != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(
                                      _imagemBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.network(
                                      _imagemSelecionada!.path,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(Icons.store, size: 40),
                                          ),
                                    ),
                            )
                          : (editando && imagemAtualUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imagemAtualUrl,
                                key: ValueKey(imagemAtualUrl),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, error, __) {
                                  print('ERRO IMG LOJA: $imagemAtualUrl');
                                  print('DETALHE: $error');
                                  return const Center(
                                    child: Icon(Icons.store, size: 40),
                                  );
                                },
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40),
                                  SizedBox(height: 8),
                                  Text('Toque para selecionar a logo'),
                                ],
                              ),
                            ),
                    ),
                  ),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da loja',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da loja';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _carregandoCidades
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                          initialValue: _cidadeIdSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            border: OutlineInputBorder(),
                          ),
                          items: _cidades.map((cidade) {
                            return DropdownMenuItem<int>(
                              value: cidade.cidadeId,
                              child: Text(cidade.nmcidade),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _cidadeIdSelecionada = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione uma cidade';
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bairroController,
                    decoration: const InputDecoration(
                      labelText: 'Bairro',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _enderecoController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço da loja',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instagramController,
                    decoration: const InputDecoration(
                      labelText: 'Instagram da loja',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _horarioController,
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _diasValidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dias de validade',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final texto = value?.trim() ?? '';
                      if (texto.isEmpty) return null;
                      if (int.tryParse(texto) == null) {
                        return 'Informe um número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
