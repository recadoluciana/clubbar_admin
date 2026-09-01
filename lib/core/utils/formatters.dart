class ClubbarFormatters {
  const ClubbarFormatters._();

  static String telefone(String valor) {
    final numeros = valor.replaceAll(RegExp(r'\D'), '');
    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    }
    if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return valor;
  }
}
