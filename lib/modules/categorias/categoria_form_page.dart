import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../core/repositories/categoria_repository.dart';

class CategoriaFormPage extends StatefulWidget {
  final Categoria? categoria;
  final int lojaId;

  const CategoriaFormPage({super.key, this.categoria, required this.lojaId});

  @override
  State<CategoriaFormPage> createState() => _CategoriaFormPageState();
}

class _CategoriaFormPageState extends State<CategoriaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _ordemController = TextEditingController();
  final _repository = CategoriaRepository();

  bool _salvando = false;

  String _sitcategoria = 'ATIVA';

  bool get editando => widget.categoria != null;

  @override
  void initState() {
    super.initState();

    if (widget.categoria != null) {
      _nomeController.text = widget.categoria!.nmcategoria;
      _sitcategoria = widget.categoria!.sitcategoria ?? 'ATIVA';
      _ordemController.text = (widget.categoria!.idordcategoria ?? 1)
          .toString();
    } else {
      _ordemController.text = '1';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ordemController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final ordem = int.tryParse(_ordemController.text.trim()) ?? 1;

      if (editando) {
        await _repository.atualizar(
          widget.lojaId,
          widget.categoria!.categoriaId,
          nome,
          _sitcategoria,
          ordem,
        );
      } else {
        await _repository.criar(widget.lojaId, nome, _sitcategoria, ordem);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Categoria alterada com sucesso.'
                : 'Categoria criada com sucesso.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Alterar Categoria' : 'Nova Categoria'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da categoria',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da categoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ordemController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ordem no cardápio',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a ordem no cardápio';
                      }

                      final numero = int.tryParse(value.trim());
                      if (numero == null) {
                        return 'Informe um número válido';
                      }

                      if (numero <= 0) {
                        return 'A ordem deve ser maior que zero';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _sitcategoria,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ATIVA', child: Text('ATIVA')),
                      DropdownMenuItem(
                        value: 'INATIVA',
                        child: Text('INATIVA'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sitcategoria = value;
                        });
                      }
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
                          : Text(editando ? 'Salvar Alterações' : 'Salvar'),
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
