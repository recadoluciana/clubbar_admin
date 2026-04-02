class Usuario {
  final int usuarioId;
  final int organizacaoId;
  final int? lojaId;
  final String nmusuario;
  final String emailuser;
  final String? situsuario;

  Usuario({
    required this.usuarioId,
    required this.organizacaoId,
    this.lojaId,
    required this.nmusuario,
    required this.emailuser,
    this.situsuario,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: json['usuario_id'] ?? 0,
      organizacaoId: json['organizacao_id'] ?? 0,
      lojaId: json['loja_id'],
      nmusuario: (json['nmusuario'] ?? '').toString(),
      emailuser: (json['emailuser'] ?? '').toString(),
      situsuario: json['situsuario']?.toString(),
    );
  }
}