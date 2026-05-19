import 'dart:io';

bool isNoInternetError(Object error) {
  if (error is SocketException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('no address associated with hostname') ||
      message.contains('connection timed out') ||
      message.contains('timed out') ||
      message.contains('the internet connection appears to be offline');
}

String offlineAwareErrorMessage(String noInternetMessage, Object error, {String? fallback}) {
  if (isNoInternetError(error)) {
    return noInternetMessage;
  }

  return fallback ?? error.toString();
}

String? _exceptionDetail(Object error) {
  final message = error.toString().trim();
  const prefix = 'Exception: ';
  if (message.startsWith(prefix)) {
    final detail = message.substring(prefix.length).trim();
    if (detail.isNotEmpty && detail != 'Login failed') {
      return detail;
    }
  }

  return null;
}

String authFailureMessage(String noInternetMessage, String invalidCredentialsMessage, Object? error) {
  if (error != null && isNoInternetError(error)) {
    return noInternetMessage;
  }

  if (error != null) {
    final detail = _exceptionDetail(error);
    if (detail != null) {
      return detail;
    }
  }

  return invalidCredentialsMessage;
}
