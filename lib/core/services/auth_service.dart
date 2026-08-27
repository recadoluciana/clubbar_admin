import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static Future<void> login(String email, String senha) async {
    try {
      final response = await ApiService.post('/operadores/login', {
        'email': email,
        'senha': senha,
      });
      if (response.statusCode == 401) {
        throw const AuthException('E-mail ou senha invalidos.');
      }
      if (response.statusCode == 403) {
        throw const AuthException('Operador inativo.');
      }
      if (response.statusCode != 200) {
        throw const AuthException('Nao foi possivel realizar o login.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await StorageService.saveToken(data['access_token'].toString());
      await StorageService.saveOperador(
        id: data['operador_id'] as int,
        nome: data['nmoperador']?.toString() ?? '',
        perfil: data['perfil']?.toString() ?? '',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Nao foi possivel conectar ao servidor.');
    }
  }
}
