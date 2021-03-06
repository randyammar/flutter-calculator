import 'package:calculator/data/database.dart';
import 'package:calculator/data/models/calculation.dart';
import 'package:flutter/foundation.dart';
import 'package:math_expressions/math_expressions.dart';

class HomeViewModel with ChangeNotifier {
  var _database;
  HomeViewModel() {
    initDB();
  }

  void initDB() async {
    _database =
        await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  }

  List<String> _buttons = [
    'C',
    '⌫',
    '%',
    '÷',
    '7',
    '8',
    '9',
    'x',
    '4',
    '5',
    '6',
    '-',
    '1',
    '2',
    '3',
    '+',
    '00',
    '0',
    '.',
    '=',
  ];
  String _result = "0";
  String _equation = "0";
  String _expression = "";
  double _resultFontSize = 60.0;
  double _equationFontSize = 30.0;

  List<String> get buttons => _buttons;
  String get result => _result;
  String get equation => _equation;
  double get resultFontSize => _resultFontSize;
  double get equationFontSize => _equationFontSize;

  bool isOperator(String val) {
    if (val == '%' ||
        val == '÷' ||
        val == 'x' ||
        val == '-' ||
        val == '+' ||
        val == '=') {
      return true;
    }
    return false;
  }

  bool isOperator2(String val) {
    if (val == '÷' || val == 'x' || val == '-' || val == '+' || val == '=') {
      return true;
    }
    return false;
  }

  bool isOperand(String val) {
    if (val == '÷' || val == 'x' || val == '-' || val == '+') {
      return true;
    }
    return false;
  }

  void buttonPressed(String buttonText) {
    var lastChar = _equation.substring(_equation.length - 1);
    if (buttonText == "C") {
      _equation = "0";
      _result = "0";
    } else if (buttonText == "⌫") {
      _equation = _equation.substring(0, _equation.length - 1);
      if (_equation == "") {
        _equation = "0";
      }
    } else if (buttonText == "%") {
      if (_equation != "0") {
        // _result = calcPercent(_equation);

        _equation = calcPercent(solve(_equation));
      }
    } else if (buttonText == "=") {
      solveEquation();
    } else if (buttonText == ".") {
      if (lastChar != ".") {
        var arr = _equation.replaceAll(new RegExp(r'[-+÷x]'), 'i').split('i');
        if (!arr.last.contains(".")) {
          _equation += buttonText;
        }
      }
    } else if (isOperand(buttonText)) {
      if (!isOperand(lastChar)) {
        _equation += buttonText;
      }
    } else {
      if (_equation == "0") {
        _equation = buttonText;
      } else {
        _equation += buttonText;
      }

      if (!isOperator2(lastChar)) {
        // solveEquation();
      }
    }

    notifyListeners();
  }

  calcPercent(String x) => (double.parse(x) / 100).toString();

  solveEquation() {
    _expression = _equation;
    _expression = _expression.replaceAll('x', '*');
    _expression = _expression.replaceAll('÷', '/');
    try {
      Parser parser = new Parser();
      Expression expression = parser.parse(_expression);

      ContextModel context = ContextModel();
      String answerString =
          expression.evaluate(EvaluationType.REAL, context).toString();
      double answer = double.parse(answerString);
      // print(answer);
      _result = answerString.length >= 9
          ? answer.toStringAsExponential(2)
          : answer.toString();

      // Save to history
      saveCalc(_equation, _result);
    } catch (e) {
      _result = "Error";
    }

    notifyListeners();
  }

  solve(String exp) {
    var ex = exp.replaceAll('x', '*');
    String result = "";
    ex.replaceAll('÷', '/');
    try {
      Parser parser = new Parser();
      Expression expression = parser.parse(ex);

      ContextModel context = ContextModel();
      String answerString =
          expression.evaluate(EvaluationType.REAL, context).toString();
      double answer = double.parse(answerString);
      result = answer.toStringAsFixed(5);
    } catch (e) {
      result = "Error";
      print(e);
    }
    return result;
  }

  Stream<List<Calculation>> getHistory() {
    return _database.calculationDao.indexStream();
  }

  saveCalc(equation, result) async {
    Calculation calc = new Calculation(equation, result);
    await _database.calculationDao.save(calc);
  }

  clearHistory() async {
    await _database.calculationDao.clear();
    notifyListeners();
  }
}
