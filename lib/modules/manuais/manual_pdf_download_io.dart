import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> salvarManualPdf(Uint8List bytes, String nome) async {
  final desktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar PDF do manual',
    fileName: nome,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    bytes: desktop ? null : bytes,
  );
  if (desktop && path != null) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
}
