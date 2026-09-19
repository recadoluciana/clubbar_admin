import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clubbar_gestao/core/utils/formatters.dart';

void main() {
  group('ClubbarFormatters', () {
    test('formata CPF, CNPJ e CEP para exibição', () {
      expect(ClubbarFormatters.cpf('12345678901'), '123.456.789-01');
      expect(ClubbarFormatters.cnpj('12345678000190'), '12.345.678/0001-90');
      expect(ClubbarFormatters.cpfCnpj('12345678000190'), '12.345.678/0001-90');
      expect(ClubbarFormatters.cep('37185054'), '37185-054');
    });

    test('preserva valor incompleto sem inventar preenchimento', () {
      expect(ClubbarFormatters.cpfCnpj('1234'), '1234');
      expect(ClubbarFormatters.cep('37185'), '37185');
    });
  });

  group('formatadores de digitação', () {
    TextEditingValue editar(TextInputFormatter formatador, String texto) =>
        formatador.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: texto,
            selection: TextSelection.collapsed(offset: texto.length),
          ),
        );

    test('aplica máscara de CPF ou CNPJ e limita em 14 dígitos', () {
      expect(
        editar(const CpfCnpjInputFormatter(), '12345678901').text,
        '123.456.789-01',
      );
      expect(
        editar(const CpfCnpjInputFormatter(), '1234567800019099').text,
        '12.345.678/0001-90',
      );
    });

    test('aplica máscara de CEP e limita em 8 dígitos', () {
      expect(editar(const CepInputFormatter(), '3718505499').text, '37185-054');
    });
  });
}
