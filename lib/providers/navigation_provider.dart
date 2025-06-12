import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  // Navigation indices as constants
  static const int homeIndex = 0;
  static const int meetingsIndex = 1;
  static const int prayIndex = 2;
  static const int readIndex = 3;
  static const int moreIndex = 4;
  static const int profileIndex = 5;
  static const int adminCenterIndex = 6;
  static const int settingsIndex = 7;
  static const int helpSupportIndex = 8;
  static const int aboutIndex = 9;

  int _currentIndex = homeIndex;

  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void navigateToHome() => navigateTo(homeIndex);
  void navigateToMeetings() => navigateTo(meetingsIndex);
  void navigateToPray() => navigateTo(prayIndex);
  void navigateToRead() => navigateTo(readIndex);
  void navigateToMore() => navigateTo(moreIndex);
  void navigateToProfile() => navigateTo(profileIndex);
  void navigateToAdminCenter() => navigateTo(adminCenterIndex);
  void navigateToSettings() => navigateTo(settingsIndex);
  void navigateToHelpSupport() => navigateTo(helpSupportIndex);
  void navigateToAbout() => navigateTo(aboutIndex);
}
