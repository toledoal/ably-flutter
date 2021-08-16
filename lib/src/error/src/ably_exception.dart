import 'package:flutter/services.dart';

import 'error_info.dart';

/// An exception generated by the native client library called by this plugin
class AblyException implements Exception {
  /// platform error code
  ///
  /// Mostly used for storing [PlatformException.code]
  final String? code;

  /// platform error message
  ///
  /// Mostly used for storing [PlatformException.message]
  final String? message;

  /// error message from ably native sdk
  final ErrorInfo? errorInfo;

  /// initializes with no defaults
  AblyException([
    this.code,
    this.message,
    this.errorInfo,
  ]);

  /// create AblyException from [PlatformException]
  AblyException.fromPlatformException(PlatformException exception)
      : code = exception.code,
        message = exception.message,
        errorInfo = exception.details as ErrorInfo?;

  AblyException.fromMessage(int code, this.message)
      : code = code.toString(),
        errorInfo = ErrorInfo(
            code: code,
            href: 'https://help.ably.io/error/40000',
            message: message);

  @override
  String toString() {
    if (message == null) {
      return 'AblyException (${(code == null) ? "" : '$code '})';
    }
    return 'AblyException: $message (${(code == null) ? "" : '$code '})';
  }
}
