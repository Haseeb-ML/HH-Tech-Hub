import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  /// Generates a cryptographically random salt string.
  static String generateSalt([int length = 32]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a password combined with a salt using 10,000 key-stretching iterations (SHA-256).
  static String hashPassword(String password, String salt, [int iterations = 10000]) {
    final initialBytes = utf8.encode('$salt:$password');
    Digest currentDigest = sha256.convert(initialBytes);
    for (int i = 1; i < iterations; i++) {
      currentDigest = sha256.convert([...currentDigest.bytes, ...utf8.encode(salt)]);
    }
    return 'pbkdf2_\$$iterations\$${currentDigest.toString()}';
  }

  /// Legacy single-pass hash computation for backward compatibility
  static String hashPasswordLegacy(String password, String salt) {
    final saltedPassword = '$salt:$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a password against stored salt and expected hash (supports both PBKDF2 stretched and legacy single-pass hashes).
  static bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    if (expectedHash.startsWith('pbkdf2_\$')) {
      final computedHash = hashPassword(password, salt);
      return _constantTimeCompare(computedHash, expectedHash);
    }

    // Try new stretched hash check
    final computedStretched = hashPassword(password, salt);
    if (_constantTimeCompare(computedStretched, expectedHash)) return true;

    // Fallback to legacy single-pass hash check for existing database accounts
    final computedLegacy = hashPasswordLegacy(password, salt);
    return _constantTimeCompare(computedLegacy, expectedHash);
  }

  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
