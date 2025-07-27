import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  static const int homeIndex = 0;
  static const int meetingsIndex = 1;
  static const int prayIndex = 2;
  static const int readIndex = 3;
  static const int moreIndex = 4;

  int _currentIndex = homeIndex;

  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void reset() {
    _currentIndex = homeIndex;
    notifyListeners();
  }
}