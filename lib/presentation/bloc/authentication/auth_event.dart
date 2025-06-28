abstract class AuthEvent {}

class CheckAuthRequiredEvent extends AuthEvent {}

class EnableAuthEvent extends AuthEvent {}

class DisableAuthEvent extends AuthEvent {}

class AuthenticateEvent extends AuthEvent {
  final String reason;

  AuthenticateEvent({required this.reason});
}

class LoadAuthSettingsEvent extends AuthEvent {}
