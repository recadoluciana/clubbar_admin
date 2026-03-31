class EventoLote {
  final int loteId;
  final String nmlote;
  final double vrprecolote;
  final int qttotallote;
  final int qtvendidalote;
  final String? dtiniciovenda;
  final String? dtfimvenda;
  final String? statuslote;

  EventoLote({
    required this.loteId,
    required this.nmlote,
    required this.vrprecolote,
    required this.qttotallote,
    required this.qtvendidalote,
    this.dtiniciovenda,
    this.dtfimvenda,
    this.statuslote,
  });

  factory EventoLote.fromJson(Map<String, dynamic> json) {
    return EventoLote(
      loteId: json['lote_id'],
      nmlote: json['nmlote'],
      vrprecolote: (json['vrprecolote'] as num).toDouble(),
      qttotallote: json['qttotallote'],
      qtvendidalote: json['qtvendidalote'],
      dtiniciovenda: json['dtiniciovenda'],
      dtfimvenda: json['dtfimvenda'],
      statuslote: json['statuslote'],
    );
  }
}