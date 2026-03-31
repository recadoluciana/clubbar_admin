class Organizacao {
  final int organizacaoId;
  final String nmorganizacao;
  final String? sitorganizacao;
  final String? cnpjorganizacao;
  final String? emailorganizacao;
  final String? telorganizacao;

  Organizacao({
    required this.organizacaoId,
    required this.nmorganizacao,
    this.sitorganizacao,
    this.cnpjorganizacao,
    this.emailorganizacao,
    this.telorganizacao,
  });

  factory Organizacao.fromJson(Map<String, dynamic> json) {
    return Organizacao(
      organizacaoId: json['organizacao_id'] ?? 0,
      nmorganizacao: (json['nmorganizacao'] ?? '').toString(),
      sitorganizacao: json['sitorganizacao']?.toString(),
      cnpjorganizacao: json['cnpjorganizacao']?.toString(),
      emailorganizacao: json['emailorganizacao']?.toString(),
      telorganizacao: json['telorganizacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizacao_id': organizacaoId,
      'nmorganizacao': nmorganizacao,
      'sitorganizacao': sitorganizacao,
      'cnpjorganizacao': cnpjorganizacao,
      'emailorganizacao': emailorganizacao,
      'telorganizacao': telorganizacao,
    };
  }
}