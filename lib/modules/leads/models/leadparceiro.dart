class LeadEstabelecimento {
  final int id;
  final String nome;
  final String tipo;
  final String tipoVenda;
  final String status;
  final String decisao;

  const LeadEstabelecimento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tipoVenda,
    required this.status,
    required this.decisao,
  });

  factory LeadEstabelecimento.fromJson(Map<String, dynamic> json) =>
      LeadEstabelecimento(
        id: LeadParceiro._toInt(json['leadestabelecimento_id']),
        nome: json['nmestabelecimento']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? '',
        tipoVenda: json['tipovenda']?.toString() ?? 'AMBOS',
        status: json['status']?.toString() ?? 'NOVO',
        decisao: json['decisao']?.toString() ?? 'PENDENTE',
      );
}

class LeadParceiro {
  final int leadparceiroId;
  final String nmresponsavel;
  final String nmestabelecimento;
  final String tipo;
  final String telefone;
  final String email;
  final int estadoId;
  final int cidadeId;
  final String nmestado;
  final String sgestado;
  final String nmcidade;
  final String? mensagem;
  final String status;
  final DateTime dtcriacao;
  final DateTime? dtultatu;
  final int diasEspera;
  final bool aguardandoResposta;
  final List<LeadEstabelecimento> estabelecimentos;

  const LeadParceiro({
    required this.leadparceiroId,
    required this.nmresponsavel,
    required this.nmestabelecimento,
    required this.tipo,
    required this.telefone,
    required this.email,
    required this.estadoId,
    required this.cidadeId,
    required this.nmestado,
    required this.sgestado,
    required this.nmcidade,
    required this.mensagem,
    required this.status,
    required this.dtcriacao,
    required this.dtultatu,
    required this.diasEspera,
    required this.aguardandoResposta,
    required this.estabelecimentos,
  });

  factory LeadParceiro.fromJson(Map<String, dynamic> json) {
    return LeadParceiro(
      leadparceiroId: _toInt(json['leadparceiro_id']),
      nmresponsavel: json['nmresponsavel']?.toString() ?? '',
      nmestabelecimento: json['nmestabelecimento']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      estadoId: _toInt(json['estado_id']),
      cidadeId: _toInt(json['cidade_id']),
      nmestado: json['nmestado']?.toString() ?? '',
      sgestado: json['sgestado']?.toString() ?? '',
      nmcidade: json['nmcidade']?.toString() ?? '',
      mensagem: json['mensagem']?.toString(),
      status: json['status']?.toString() ?? 'NOVO',
      dtcriacao: _toDateTime(json['dtcriacao']),
      dtultatu: _toNullableDateTime(json['dtultatu']),
      diasEspera: _toInt(json['dias_espera']),
      aguardandoResposta: json['aguardando_resposta'] == true,
      estabelecimentos: (json['estabelecimentos'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => LeadEstabelecimento.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
