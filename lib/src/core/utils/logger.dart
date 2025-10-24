class Logger {
  const Logger(this._tag);

  final String _tag;

  void info(String message) {
    // Lightweight logging placeholder until a proper logger is wired in.
    // ignore: avoid_print
    print('INFO: [$_tag] $message');
  }

  void error(String message, [Object? error]) {
    // ignore: avoid_print
    print('ERROR: [$_tag] $message ${error != null ? 'error: $error' : ''}');
  }
}
