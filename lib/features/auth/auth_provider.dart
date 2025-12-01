import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Importamos para acceder a la variable 'supabase'

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- REGISTRO (Sign Up) ---
  Future<String?> register({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    try {
      _setLoading(true);
      
      // Enviamos 'nombre' y 'telefono' en 'data'. 
      // Nuestro Trigger en SQL los leerá de ahí para crear el perfil automáticamente.
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'telefono': telefono, // Importante para delivery/reservas
        },
      );
      
      _setLoading(false);
      return null; // Null significa éxito (sin errores)
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message; // Devolvemos el mensaje de error
    } catch (e) {
      _setLoading(false);
      return "Ocurrió un error inesperado";
    }
  }

  // --- INICIAR SESIÓN (Login) ---
  Future<String?> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return null;
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return "Error de conexión";
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> signOut() async {
    await supabase.auth.signOut();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}