import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/repositories/manual_repository.dart';
import 'manual_pdf_download.dart';

class ManualBackupActions extends StatefulWidget {
  const ManualBackupActions({super.key});
  @override
  State<ManualBackupActions> createState() => _ManualBackupActionsState();
}

class _ManualBackupActionsState extends State<ManualBackupActions> {
  bool _ocupado = false;
  final _repo = ManualRepository();

  void _mensagem(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _exportar() async {
    setState(() => _ocupado = true);
    try {
      final bytes = await _repo.exportarBackup();
      final data = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      await salvarArquivoManual(
        bytes,
        'clubbar-manuais-$data.json',
        mimeType: 'application/json',
        extensao: 'json',
      );
    } catch (e) {
      _mensagem('$e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _importar() async {
    setState(() => _ocupado = true);
    try {
      final selecao = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (selecao == null) return;
      final arquivo = selecao.files.single;
      if (arquivo.size > 50 * 1024 * 1024 || arquivo.bytes == null) {
        throw Exception('Selecione um backup JSON de até 50 MB.');
      }
      final dados = jsonDecode(utf8.decode(arquivo.bytes!));
      if (dados is! Map<String, dynamic> ||
          dados['tipo'] != 'clubbar.manuais' ||
          dados['formato'] != 1 ||
          dados['manuais'] is! List) {
        throw Exception('Este arquivo não é um backup dos manuais do Clubbar.');
      }
      final guias = dados['manuais'] as List;
      if (guias.length != 3 ||
          guias.any(
            (g) =>
                g is! Map ||
                g['versoes'] is! List ||
                (g['versoes'] as List).isEmpty,
          )) {
        throw Exception(
          'O backup precisa conter os três guias e seu histórico.',
        );
      }
      final versoes = guias.fold<int>(
        0,
        (total, g) => total + (g['versoes'] as List).length,
      );
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importar backup dos manuais'),
          content: Text(
            'Arquivo: ${arquivo.name}\n\n3 guias e $versoes versões.\n\nA importação substituirá todos os manuais e seus históricos pelo conteúdo deste arquivo. Os demais cadastros da base não serão alterados.\n\nExporte um backup atual antes de continuar se quiser guardar as versões existentes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurar manuais'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      final resultado = await _repo.importarBackup(dados);
      _mensagem(
        'Backup restaurado: ${resultado['manuais']} guias e ${resultado['versoes']} versões.',
      );
    } on FormatException {
      _mensagem('Arquivo JSON inválido. Nenhum manual foi alterado.');
    } catch (e) {
      _mensagem('$e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _ocupado ? null : _exportar,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar backup'),
        ),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : _importar,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Importar backup'),
        ),
        if (_ocupado)
          const Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    ),
  );
}
