import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _token = 'admin_auth_token';
  static const _id = 'operador_id';
  static const _nome = 'operador_nome';
  static const _perfil = 'operador_perfil';

  static Future<void> saveToken(String value) async =>
      (await SharedPreferences.getInstance()).setString(_token, value);
  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_token);
  static Future<void> saveOperador({
    required int id,
    required String nome,
    required String perfil,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_id, id);
    await prefs.setString(_nome, nome);
    await prefs.setString(_perfil, perfil);
  }

  static Future<int?> getOperadorId() async =>
      (await SharedPreferences.getInstance()).getInt(_id);
  static Future<int?> getUsuarioId() async => getOperadorId();
  static Future<String?> getNomeOperador() async =>
      (await SharedPreferences.getInstance()).getString(_nome);
  static Future<String?> getPerfil() async =>
      (await SharedPreferences.getInstance()).getString(_perfil);
  static Future<String?> getCargo() async => getPerfil();
  static Future<bool> isSuperAdmin() async =>
      (await getToken())?.isNotEmpty == true;
  static Future<String?> getNomeUsuario() async => getNomeOperador();
  static Future<String?> getNomeOrganizacao() async => 'Clubbar';
  static Future<int?> getOrganizacaoId() async => null;
  static Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).clear();
}
