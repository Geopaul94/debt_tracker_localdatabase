abstract class Failure {
  const Failure([List properties = const <dynamic>[]]);
}

// General failures
class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}

class ValidationFailure extends Failure {
  final String message;
  const ValidationFailure(this.message);
}

// Transaction specific failures
class TransactionNotFoundFailure extends Failure {}

class DuplicateTransactionFailure extends Failure {}

class InvalidTransactionDataFailure extends Failure {
  final String message;
  const InvalidTransactionDataFailure(this.message);
}

// Authentication specific failures
class BiometricNotAvailableFailure extends Failure {}

class AuthenticationFailedFailure extends Failure {}

class AuthenticationErrorFailure extends Failure {
  final String message;
  AuthenticationErrorFailure(this.message);
}
