class Evento {
  final int eventoId;
  final int organizacaoId;
  final int lojaId;
  final String nmtituloevento;
  final String? dsdescevento;
  final String? nmlocalevento;
  final String? dsendlocevento;
  final String? dtinicioevento;
  final String? dtfimevento;
  final String? sitevento;
  final String? urlbannerevento;

  Evento({
    required this.eventoId,
    required this.organizacaoId,
    required this.lojaId,
    required this.nmtituloevento,
    this.dsdescevento,
    this.nmlocalevento,
    this.dsendlocevento,
    this.dtinicioevento,
    this.dtfimevento,
    this.sitevento,
    this.urlbannerevento,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      eventoId: json['evento_id'] ?? 0,
      organizacaoId: json['organizacao_id'] ?? 0,
      lojaId: json['loja_id'] ?? 0,
      nmtituloevento: (json['nmtituloevento'] ?? '').toString(),
      dsdescevento: json['dsdescevento']?.toString(),
      nmlocalevento: json['nmlocalevento']?.toString(),
      dsendlocevento: json['dsendlocevento']?.toString(),
      dtinicioevento: json['dtinicioevento']?.toString(),
      dtfimevento: json['dtfimevento']?.toString(),
      sitevento: json['sitevento']?.toString(),
      urlbannerevento: json['urlbannerevento']?.toString(),
    );
  }
}