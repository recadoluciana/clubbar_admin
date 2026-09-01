class LeadEstabelecimento {
  final int id;
  final String nome;
  final String tipo;
  final String tipoVenda;
  final String status;
  final String? cpfCnpj;
  final String? telefone;
  final String? email;
  final int estadoId;
  final int cidadeId;
  final String? cep;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? mensagem;
  final double taxaProdutos;
  final double taxaIngressos;

  const LeadEstabelecimento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tipoVenda,
    required this.status,
    required this.cpfCnpj,
    required this.telefone,
    required this.email,
    required this.estadoId,
    required this.cidadeId,
    required this.cep,
    required this.endereco,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.mensagem,
    required this.taxaProdutos,
    required this.taxaIngressos,
  });

  bool get dadosContratuaisCompletos =>
      (cpfCnpj ?? '').trim().isNotEmpty &&
      (telefone ?? '').trim().isNotEmpty &&
      (email ?? '').trim().isNotEmpty &&
      estadoId > 0 &&
      cidadeId > 0 &&
      (cep ?? '').trim().isNotEmpty &&
      (endereco ?? '').trim().isNotEmpty &&
      (numero ?? '').trim().isNotEmpty &&
      (bairro ?? '').trim().isNotEmpty;

  factory LeadEstabelecimento.fromJson(
    Map<String, dynamic> json,
  ) => LeadEstabelecimento(
    id: LeadParceiro._toInt(json['leadestabelecimento_id']),
    nome: json['nmestabelecimento']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? '',
    tipoVenda: json['tipovenda']?.toString() ?? 'AMBOS',
    status: json['status']?.toString() ?? 'NOVO',
    cpfCnpj: json['cpfcnpj']?.toString(),
    telefone: json['telefone']?.toString(),
    email: json['email']?.toString(),
    estadoId: LeadParceiro._toInt(json['estado_id']),
    cidadeId: LeadParceiro._toInt(json['cidade_id']),
    cep: json['cep']?.toString(),
    endereco: json['endereco']?.toString(),
    numero: json['numero']?.toString(),
    complemento: json['complemento']?.toString(),
    bairro: json['bairro']?.toString(),
    mensagem: json['mensagem']?.toString(),
    taxaProdutos: double.tryParse(json['vrtaxaprod']?.toString() ?? '') ?? 5,
    taxaIngressos: double.tryParse(json['vrtaxaing']?.toString() ?? '') ?? 5,
  );
}

class LeadParceiro {
  final int leadparceiroId;
  final String nmresponsavel;
  final String? nmorganizacao;
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
    required this.nmorganizacao,
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
      nmorganizacao: json['nmorganizacao']?.toString(),
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
          .map(
            (item) =>
                LeadEstabelecimento.fromJson(Map<String, dynamic>.from(item)),
          )
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
