import 'dart:convert';
import '../services/api_service.dart';

class TaxaPadraoRepository {
  String _erro(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map && d['detail'] != null ? d['detail'].toString() : body;
    } catch (_) {
      return body;
    }
  }

  Future<List<Map<String, dynamic>>> listar() async {
    final r = await ApiService.get('/taxas-padrao');
    if (r.statusCode != 200) throw Exception(_erro(r.body));
    return (jsonDecode(r.body) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> criar(Map<String, dynamic> d) async {
    final r = await ApiService.post('/taxas-padrao', d);
    if (r.statusCode != 201) throw Exception(_erro(r.body));
  }

  Future<void> alterar(int id, Map<String, dynamic> d) async {
    final r = await ApiService.put('/taxas-padrao/$id', d);
    if (r.statusCode != 200) throw Exception(_erro(r.body));
  }

  Future<void> vigorar(int id) async {
    final r = await ApiService.post('/taxas-padrao/$id/vigorar', {});
    if (r.statusCode != 200) throw Exception(_erro(r.body));
  }
}
