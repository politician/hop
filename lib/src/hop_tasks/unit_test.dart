part of hop_tasks;

const _listFlag = 'list';
const _summaryFlag = 'summary';
const _summaryAll = 'all';
const _summaryFail = 'fail';
const _summaryPass = 'pass';
const _summaryError = 'error';

Task createUnitTestTask(Action1<unittest.Configuration> unitTestAction,
                        {Duration timeout: const Duration(seconds: 20)}) {
  return new Task.async((TaskContext ctx) {

    final summaryFlag = ctx.arguments[_summaryFlag];

    final passSummary =
        (summaryFlag == _summaryAll || summaryFlag == _summaryPass);

    final failSummary =
        (summaryFlag == _summaryAll || summaryFlag == _summaryFail);

    final errorSummary =
        (summaryFlag == _summaryAll || summaryFlag == _summaryError);

    final config = new _HopTestConfiguration(ctx, failSummary, passSummary,
        errorSummary, timeout);

    // TODO: wrap this in a try/catch
    unitTestAction(config);

    if(!ctx.arguments.rest.isEmpty) {
      ctx.info('Filtering tests by: ${ctx.arguments.rest}');

      unittest.filterTests((unittest.TestCase tc) {
        return ctx.arguments.rest.every((arg) => tc.description.contains(arg));
      });
    }

    if(ctx.arguments[_listFlag]) {
      final list = unittest.testCases
          .map((tc) => tc.description)
          .toList();

      list.sort();

      list.insert(0, 'Test cases:');

      ctx.info(list.join('\n'));

      return new Future.value(true);
    }

    unittest.runTests();
    return config.future;
  },
  config: _unittestParserConfig,
  description: 'Run unit tests in the console',
  extendedArgs: [new TaskArgument('filter', multiple: true)]);
}

void _unittestParserConfig(ArgParser parser) {
  parser.addFlag(_listFlag, abbr: 'l', defaultsTo: false,
      help: "Just list the test case names. Don't run them. Any filter is still applied.");
  parser.addOption(_summaryFlag, abbr: 's',
      help: 'Summarize the results of individual tests.',
      allowed: [_summaryAll, _summaryFail, _summaryPass, _summaryError],
      allowMultiple: false);
}

class _HopTestConfiguration extends unittest.Configuration {
  final Completer<bool> _completer = new Completer<bool>();
  final TaskContext _context;
  final bool failSummary;
  final bool passSummary;
  final bool errorSummary;
  final Duration timeout;

  _HopTestConfiguration(this._context, this.failSummary, this.passSummary,
      this.errorSummary, this.timeout) : super.blank();

  Future<bool> get future => _completer.future;

  bool get autoStart => false;

  @override
  void onInit() {
    _context.config('config: onInit');
  }

  @override
  void onStart() {
    _context.config('config: onStart');
  }

  @override
  void onTestStart(unittest.TestCase testCase) {
    _context.config('Starting ${testCase.description}');
  }

  @override
  void onLogMessage(unittest.TestCase testCase, String message) {
    String msg;
    if(testCase != null) {
      msg = '${testCase.description}\n$message';
    } else {
      msg = message;
    }
    _context.fine(msg);
  }

  @override
  void onTestResult(unittest.TestCase testCase) {
    // result should not be null here
    assert(testCase.result != null);

    if(testCase.result == unittest.PASS) {
      _context.info('${testCase.description} -- PASS');
    } else {
      var msg = '''[${testCase.result}] ${testCase.description}
${testCase.message}''';
      if(testCase.stackTrace != null) {
        msg = msg + '''
${testCase.stackTrace}''';
      }
      _context.severe(msg);
    }

    _context.fine('Duration: ${testCase.runningTime}');
  }

  @override
  void onTestResultChanged(unittest.TestCase testCase) {
    _context.severe('Result changed for ${testCase.description}');
    _context.severe(
'''[${testCase.result}] ${testCase.description}
${testCase.message}
${testCase.stackTrace}''');
  }

  @override
  void onSummary(int passed, int failed, int errors, List<unittest.TestCase> results,
              String uncaughtError) {
    final bool success = failed == 0 && errors == 0 && uncaughtError == null;
    final message = "$passed PASSED, $failed FAILED, $errors ERRORS";


    if(passSummary) {
      final summaryCtx = _context.getSubLogger('PASS');
      results.where((tc) => tc.result == unittest.PASS).forEach((tc) {
        summaryCtx.info(tc.description);
      });
    }

    if(failSummary) {
      final summaryCtx = _context.getSubLogger('FAIL');
      results.where((tc) => tc.result == unittest.FAIL).forEach((tc) {
        summaryCtx.severe(tc.description);
      });
    }

    if(errorSummary) {
      final summaryCtx = _context.getSubLogger('ERROR');
      results.where((tc) => tc.result == unittest.ERROR).forEach((tc) {
        summaryCtx.severe(tc.description);
      });
    }

    if(success) {
      _context.info(message);
    } else {
      _context.severe(message);
    }
  }

  @override
  void onDone(bool success) {
    _completer.complete(success);
  }
}

/** Indent each line in [str] by two spaces. */
String _indent(String str) =>
  str.replaceAll(new RegExp("^", multiLine: true), "  ");
