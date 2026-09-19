/// Base exception for all OmniBrain AI errors.
///
/// Every domain-specific exception extends this class so callers can catch
/// [AppException] as a catch-all while still pattern-matching on subtypes.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// Human-readable error description.
  final String message;

  /// Optional machine-readable error code (e.g. HTTP status, vendor code).
  final String? code;

  @override
  String toString() => code != null
      ? 'AppException [$code]: $message'
      : 'AppException: $message';
}

/// Thrown when a network request fails (timeout, no connectivity, server error).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});

  /// Factory for timeout errors.
  factory NetworkException.timeout() =>
      const NetworkException('İstek zaman aşımına uğradı.', code: 'TIMEOUT');

  /// Factory for no-internet errors.
  factory NetworkException.noConnection() => const NetworkException(
        'İnternet bağlantısı bulunamadı.',
        code: 'NO_CONNECTION',
      );

  /// Factory for generic server errors.
  factory NetworkException.server([String? detail]) => NetworkException(
        detail ?? 'Sunucu hatası oluştu.',
        code: 'SERVER_ERROR',
      );

  @override
  String toString() => 'NetworkException [$code]: $message';
}

/// Thrown when authentication or authorisation fails.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  /// Factory for invalid-credentials errors.
  factory AuthException.invalidCredentials() => const AuthException(
        'Geçersiz kimlik bilgileri.',
        code: 'INVALID_CREDENTIALS',
      );

  /// Factory for expired-session errors.
  factory AuthException.sessionExpired() => const AuthException(
        'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
        code: 'SESSION_EXPIRED',
      );

  /// Factory for unauthorised-access errors.
  factory AuthException.unauthorised() => const AuthException(
        'Bu işlem için yetkiniz yok.',
        code: 'UNAUTHORISED',
      );

  @override
  String toString() => 'AuthException [$code]: $message';
}

/// Thrown when local storage (SharedPreferences, Hive, SQLite) operations fail.
class StorageException extends AppException {
  const StorageException(super.message, {super.code});

  /// Factory for read-failure.
  factory StorageException.readFailed([String? key]) => StorageException(
        key != null
            ? '"$key" anahtarı okunamadı.'
            : 'Veri okunamadı.',
        code: 'READ_FAILED',
      );

  /// Factory for write-failure.
  factory StorageException.writeFailed([String? key]) => StorageException(
        key != null
            ? '"$key" anahtarına yazılamadı.'
            : 'Veri yazılamadı.',
        code: 'WRITE_FAILED',
      );

  @override
  String toString() => 'StorageException [$code]: $message';
}

/// Thrown when OCR / text-recognition operations fail.
class OcrException extends AppException {
  const OcrException(super.message, {super.code});

  /// Factory for when no text is detected in the image.
  factory OcrException.noTextDetected() => const OcrException(
        'Görüntüde metin bulunamadı.',
        code: 'NO_TEXT',
      );

  /// Factory for unsupported image format.
  factory OcrException.unsupportedFormat() => const OcrException(
        'Desteklenmeyen görüntü formatı.',
        code: 'UNSUPPORTED_FORMAT',
      );

  @override
  String toString() => 'OcrException [$code]: $message';
}

/// Thrown when AI / LLM operations fail.
class AiException extends AppException {
  const AiException(super.message, {super.code});

  /// Factory for rate-limit errors.
  factory AiException.rateLimited() => const AiException(
        'Çok fazla istek gönderildi. Lütfen biraz bekleyin.',
        code: 'RATE_LIMITED',
      );

  /// Factory for model-unavailable errors.
  factory AiException.modelUnavailable() => const AiException(
        'AI modeli şu anda kullanılamıyor.',
        code: 'MODEL_UNAVAILABLE',
      );

  /// Factory for context-too-long errors.
  factory AiException.contextTooLong() => const AiException(
        'Girdi çok uzun. Lütfen kısaltın.',
        code: 'CONTEXT_TOO_LONG',
      );

  @override
  String toString() => 'AiException [$code]: $message';
}
