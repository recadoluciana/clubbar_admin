import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _lojaIdKey = 'loja_id';
  static const String _organizacaoIdKey = 'organizacao_id';
  static const String _usuarioIdKey = 'usuario_id';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveLojaId(int lojaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lojaIdKey, lojaId);
  }

  static Future<int?> getLojaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lojaIdKey);
  }

  static Future<void> saveOrganizacaoId(int organizacaoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_organizacaoIdKey, organizacaoId);
  }

  static Future<int?> getOrganizacaoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_organizacaoIdKey);
  }

  static Future<void> saveUsuarioId(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_usuarioIdKey, usuarioId);
  }

  static Future<int?> getUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usuarioIdKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}