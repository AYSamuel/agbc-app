import 'package:flutter/foundation.dart';
import '../services/bible_verse_service.dart';

class DailyVerseProvider extends ChangeNotifier {
  final BibleVerseService _service = BibleVerseService();
  
  DailyVerse? _dailyVerse;
  bool _isLoading = false;
  String? _error;

  DailyVerse? get dailyVerse => _dailyVerse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDailyVerse() async {
    // If we already have data, don't fetch again unless explicitly forced (not implemented here)
    if (_dailyVerse != null) return;

    _isLoading = true;
    _error = null;
    // Notify listeners only if needed, but since this is mostly for splash screen, 
    // we might not have listeners yet.
    // notifyListeners(); 

    try {
      _dailyVerse = await _service.getTodayVerse();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching daily verse in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
