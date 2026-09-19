import 'package:flutter/services.dart';

class ClubbarFormatters {
  const ClubbarFormatters._();

  static String somenteNumeros(String? valor) =>
      (valor ?? '').replaceAll(RegExp(r'\D'), '');

  static String cpf(String? valor) {
    final numeros = somenteNumeros(valor);
    if (numeros.length != 11) return valor?.trim() ?? '';
    return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.'
        '${numeros.substring(6, 9)}-${numeros.substring(9)}';
  }

  static String cnpj(String? valor) {
    final numeros = somenteNumeros(valor);
    if (numeros.length != 14) return valor?.trim() ?? '';
    return '${numeros.substring(0, 2)}.${numeros.substring(2, 5)}.'
        '${numeros.substring(5, 8)}/${numeros.substring(8, 12)}-'
        '${numeros.substring(12)}';
  }

  static String cpfCnpj(String? valor) {
    final numeros = somenteNumeros(valor);
    if (numeros.length == 11) return cpf(numeros);
    if (numeros.length == 14) return cnpj(numeros);
    return valor?.trim() ?? '';
  }

  static String cep(String? valor) {
    final numeros = somenteNumeros(valor);
    if (numeros.length != 8) return valor?.trim() ?? '';
    return '${numeros.substring(0, 5)}-${numeros.substring(5)}';
  }

  static String telefone(String valor) {
    final numeros = somenteNumeros(valor);
    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    }
    if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return valor;
  }
}

class CpfCnpjInputFormatter extends TextInputFormatter {
  const CpfCnpjInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numeros = ClubbarFormatters.somenteNumeros(newValue.text);
    final limitado = numeros.length > 14 ? numeros.substring(0, 14) : numeros;
    final texto = limitado.length <= 11
        ? _formatarProgressivo(limitado, const {3: '.', 6: '.', 9: '-'})
        : _formatarProgressivo(limitado, const {
            2: '.',
            5: '.',
            8: '/',
            12: '-',
          });
    return _valor(texto);
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  const CnpjInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numeros = ClubbarFormatters.somenteNumeros(newValue.text);
    final limitado = numeros.length > 14 ? numeros.substring(0, 14) : numeros;
    return _valor(
      _formatarProgressivo(limitado, const {2: '.', 5: '.', 8: '/', 12: '-'}),
    );
  }
}

class CepInputFormatter extends TextInputFormatter {
  const CepInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numeros = ClubbarFormatters.somenteNumeros(newValue.text);
    final limitado = numeros.length > 8 ? numeros.substring(0, 8) : numeros;
    return _valor(_formatarProgressivo(limitado, const {5: '-'}));
  }
}

String _formatarProgressivo(String numeros, Map<int, String> separadores) {
  final texto = StringBuffer();
  for (var indice = 0; indice < numeros.length; indice++) {
    final separador = separadores[indice];
    if (separador != null) texto.write(separador);
    texto.write(numeros[indice]);
  }
  return texto.toString();
}

TextEditingValue _valor(String texto) => TextEditingValue(
  text: texto,
  selection: TextSelection.collapsed(offset: texto.length),
);
