class Cidade {
  final int cidadeId;
  final String nmcidade;

  Cidade({
    required this.cidadeId,
    required this.nmcidade,
  });

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      cidadeId: json['cidade_id'] ?? 0,
      nmcidade: (json['nmcidade'] ?? '').toString(),
    );
  }

  @override
  String toString() => nmcidade;
}