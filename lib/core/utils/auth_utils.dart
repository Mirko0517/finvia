import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class AuthUtils {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateUser() async {
    try {
      // Verificar si el dispositivo tiene biometría o bloqueo de pantalla
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        throw PlatformException(
          code: auth_error.notAvailable,
          message:
              'No hay métodos de autenticación seguros configurados en este dispositivo.',
        );
      }

      // Obtener los tipos de biometría disponibles
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      String reason;
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        reason = 'Por favor, usa tu huella digital para acceder';
      } else if (availableBiometrics.contains(BiometricType.face)) {
        reason = 'Por favor, usa el reconocimiento facial para acceder';
      } else {
        reason = 'Por favor, auténticate para acceder';
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permitir PIN/patrón como fallback
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        print('Autenticación no disponible: ${e.message}');
      } else if (e.code == auth_error.notEnrolled) {
        print('No hay métodos de autenticación configurados');
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        print('Dispositivo bloqueado temporalmente');
      }
      rethrow; // Relanzamos la excepción para manejarla en la UI
    }
  }
}
