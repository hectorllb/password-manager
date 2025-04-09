import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } on PlatformException catch (_) {
      canCheckBiometrics = false;
    }
    return canCheckBiometrics;
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = [];
    try {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      availableBiometrics = [];
    }
    return availableBiometrics;
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      authenticated = false;
    }
    return authenticated;
  }
}
