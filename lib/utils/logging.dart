import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class FileLogger {
  static Logger? _logger;
  static IOSink? _sink;
  static String? _logFilePath;

  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/onewheel_ble_log.txt');
      _logFilePath = logFile.path;
      
      // Debug: Print the log file path
      print('FileLogger: Initializing log file at: ${logFile.path}');
      
      // Ensure directory exists
      await directory.create(recursive: true);
      
      _sink = logFile.openWrite(mode: FileMode.append);
      _logger = Logger(
        printer: PrettyPrinter(),
        output: _FileLogOutput(_sink!),
      );
      
      print('FileLogger: Successfully initialized');
    } catch (e) {
      print('FileLogger: Error during initialization: $e');
      // Fallback to console-only logging
      _logger = Logger(
        printer: PrettyPrinter(),
        output: ConsoleOutput(),
      );
    }
  }

  static void log(String message, {Level level = Level.info}) {
    _logger?.log(level, message);
    // Also print to console for development
    print('LOG: $message');
    // Flush immediately to ensure log is written
    _sink?.flush();
  }

  static Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
  }

  static String? get logFilePath => _logFilePath;
}

class _FileLogOutput extends LogOutput {
  final IOSink sink;
  _FileLogOutput(this.sink);

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      sink.writeln(line);
    }
  }
}
