part of 'auth_bloc.dart';

abstract class AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class SetAuthEnabledEvent extends AuthEvent {
  final bool enabled;
  SetAuthEnabledEvent(this.enabled);
}
