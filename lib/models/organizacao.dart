class Organizacao {
  final int organizacaoId;
  final String nmorganizacao;
  final String? sitorganizacao;
  final String? cnpjorganizacao;

  Organizacao({
    required this.organizacaoId,
    required this.nmorganizacao,
    this.sitorganizacao,
    this.cnpjorganizacao,
  });

  factory Organizacao.fromJson(Map<String, dynamic> json) {
    return Organizacao(
      organizacaoId: json['organizacao_id'] ?? 0,
      nmorganizacao: (json['nmorganizacao'] ?? '').toString(),
      sitorganizacao: json['sitorganizacao']?.toString(),
      cnpjorganizacao: json['cnpjorganizacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizacao_id': organizacaoId,
      'nmorganizacao': nmorganizacao,
      'sitorganizacao': sitorganizacao,
      'cnpjorganizacao': cnpjorganizacao,
    };
  }
}