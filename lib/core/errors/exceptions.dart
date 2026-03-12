/// Jerarquía de excepciones tipadas de Finding Out.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

// ─── Auth Exceptions ───

class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException()
      : super('Credenciales inválidas. Verifica tu email y contraseña.');
}

class EmailNotVerifiedException extends AppException {
  const EmailNotVerifiedException()
      : super('Tu email no ha sido verificado. Revisa tu bandeja de entrada.');
}

class EmailAlreadyInUseException extends AppException {
  const EmailAlreadyInUseException()
      : super('Este email ya está registrado.');
}

class WeakPasswordException extends AppException {
  const WeakPasswordException()
      : super('La contraseña es muy débil. Usa mínimo 8 caracteres, una mayúscula y un número.');
}

class InvalidOtpException extends AppException {
  const InvalidOtpException()
      : super('Código inválido. Intenta de nuevo.');
}

class OtpExpiredException extends AppException {
  const OtpExpiredException()
      : super('El código ha expirado. Solicita uno nuevo.');
}

// ─── Profile Exceptions ───

class UsernameAlreadyTakenException extends AppException {
  const UsernameAlreadyTakenException()
      : super('Este nombre de usuario ya está en uso.');
}

class ProfileNotFoundException extends AppException {
  const ProfileNotFoundException()
      : super('No se encontró el perfil del usuario.');
}

// ─── Network Exceptions ───

class NetworkException extends AppException {
  const NetworkException()
      : super('Error de conexión. Verifica tu internet.');
}

class RateLimitException extends AppException {
  const RateLimitException()
      : super('Demasiados intentos. Espera un momento.');
}

// ─── General ───

class UnknownException extends AppException {
  const UnknownException([super.message = 'Ocurrió un error inesperado.']);
}
