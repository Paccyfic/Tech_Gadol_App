import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.stackTrace});

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.stackTrace});
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode, super.stackTrace});

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.stackTrace});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.stackTrace});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.stackTrace});
}
