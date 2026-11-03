abstract interface class BiometricService {
  /// Returns `true` if the device supports biometrics or device credentials.
  Future<bool> isAvailable();

  /// Prompts the user to authenticate and returns `true` on success.
  Future<bool> authenticate({required String localizedReason});
}

