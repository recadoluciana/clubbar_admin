class Loja {
  final int lojaId;
  final int organizacaoId;
  final int? cidadeId;
  final String nmloja;
  final String? dsbairroloja;
  final String? nrtelloja;
  final String? dshorarioloja;
  final int? nrdiavalidade;
  final String? sitloja;
  final String? urllogoloja;

  Loja({
    required this.lojaId,
    required this.organizacaoId,
    this.cidadeId,
    required this.nmloja,
    this.dsbairroloja,
    this.nrtelloja,
    this.dshorarioloja,
    this.nrdiavalidade,
    this.sitloja,
    this.urllogoloja,
  });

  factory Loja.fromJson(Map<String, dynamic> json) {
    return Loja(
      lojaId: json['loja_id'] ?? 0,
      organizacaoId: json['organizacao_id'] ?? 0,
      cidadeId: json['cidade_id'],
      nmloja: (json['nmloja'] ?? '').toString(),
      dsbairroloja: json['dsbairroloja']?.toString(),
      nrtelloja: json['nrtelloja']?.toString(),
      dshorarioloja: json['dshorarioloja']?.toString(),
      nrdiavalidade: json['nrdiavalidade'],
      sitloja: json['sitloja']?.toString(),
      urllogoloja: json['urllogoloja']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loja_id': lojaId,
      'organizacao_id': organizacaoId,
      'cidade_id': cidadeId,
      'nmloja': nmloja,
      'dsbairroloja': dsbairroloja,
      'nrtelloja': nrtelloja,
      'dshorarioloja': dshorarioloja,
      'nrdiavalidade': nrdiavalidade,
      'sitloja': sitloja,
      'urllogoloja': urllogoloja,
    };
  }
}