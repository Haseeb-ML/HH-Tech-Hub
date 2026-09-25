import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  /// Generates a cryptographically random salt string.
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a password combined with a salt using SHA-256.
  static String hashPassword(String password, String salt) {
    final saltedPassword = '$salt:$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a password against the stored salt and hash.
  static bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    final computedHash = hashPassword(password, salt);
    // Constant time equality check to prevent timing attacks
    if (computedHash.length != expectedHash.length) return false;
    int result = 0;
    for (int i = 0; i < computedHash.length; i++) {
      result |= computedHash.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return result == 0;
  }
}
