class Loja {
  final int lojaId;
  final int? organizacaoId;
  final String nmloja;
  final String? sitloja;
  final String? cnpjloja;
  final String? emailloja;
  final String? telloja;

  Loja({
    required this.lojaId,
    this.organizacaoId,
    required this.nmloja,
    this.sitloja,
    this.cnpjloja,
    this.emailloja,
    this.telloja,
  });

  factory Loja.fromJson(Map<String, dynamic> json) {
    return Loja(
      lojaId: json['loja_id'] ?? 0,
      organizacaoId: json['organizacao_id'],
      nmloja: (json['nmloja'] ?? '').toString(),
      sitloja: json['sitloja']?.toString(),
      cnpjloja: json['cnpjloja']?.toString(),
      emailloja: json['emailloja']?.toString(),
      telloja: json['telloja']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loja_id': lojaId,
      'organizacao_id': organizacaoId,
      'nmloja': nmloja,
      'sitloja': sitloja,
      'cnpjloja': cnpjloja,
      'emailloja': emailloja,
      'telloja': telloja,
    };
  }
}