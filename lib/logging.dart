import 'dart:async';
import 'dart:developer';

import 'package:logging/logging.dart';

/// Logging stream consumer
typedef Logging = void Function(LogRecord record);

/// Keeps the old logging subscription, so we can cancel at reconfigure
StreamSubscription<LogRecord> _subscription;

/// Configures a single logger.  By default will
configureLogging({Logger logger, Level level, Logging onLog}) async {
  level ??= Level.INFO;
  logger ??= Logger.root;
  onLog ??= defaultLogging(logger);
  await _subscription?.cancel();
  _subscription = logger.onRecord.listen(onLog);
}

Logging defaultLogging(Logger logger) {
  var _sequence = 0;
  return (LogRecord rec) {
    if (rec.loggerName == logger.name && rec.level >= logger.level) {
      _sequence++;
      log(
        rec.message,
        time: rec.time,
        sequenceNumber: _sequence,
        level: rec.level.value,
        name: rec.loggerName,
        error: rec.error,
        stackTrace: rec.stackTrace,
      );
    }
  };
}
