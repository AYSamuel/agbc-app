import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyVerse {
  final String verse;
  final String reference;
  final String translationId;

  DailyVerse({
    required this.verse,
    required this.reference,
    required this.translationId,
  });
}

class BibleVerseService {
  static const String _baseUrl = 'https://bible-api.com';
  // Bump cache key to force a refresh and hit Supabase
  static const String _cacheKey = 'daily_verse_cache_v3';

  Future<DailyVerse> getTodayVerse() async {
    try {
      // 1. Check local cache first (fastest)
      final cached = await _getCachedForToday();
      if (cached != null) {
        return cached;
      }

      // 2. Check Supabase (Consistent daily verse for all users)
      final todayStr = _todayString();
      try {
        final data = await Supabase.instance.client
            .from('daily_verses')
            .select()
            .eq('date', todayStr)
            .maybeSingle();

        if (data != null) {
          final verse = DailyVerse(
            verse: data['verse_text'] as String,
            reference: data['reference'] as String,
            translationId: data['translation_id'] as String,
          );
          await _cacheToday(verse);
          return verse;
        }
      } catch (e) {
        debugPrint('Error fetching from Supabase: $e');
      }

      // 3. If not in Supabase, fetch random from API
      // This happens for the first user of the day
      final verse = await _fetchRandomKjvVerse();

      // 4. Try to insert into Supabase using RPC (safe for anon users)
      // This function handles "ON CONFLICT DO NOTHING" internally
      try {
        await Supabase.instance.client.rpc('insert_daily_verse', params: {
          'p_date': todayStr,
          'p_verse_text': verse.verse,
          'p_reference': verse.reference,
          'p_translation_id': verse.translationId,
        });
      } catch (e) {
        debugPrint('Error inserting daily verse via RPC: $e');
      }

      await _cacheToday(verse);
      return verse;
    } catch (e) {
      debugPrint('BibleVerseService error: $e');
      return DailyVerse(
        verse:
            '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
        reference: 'Jeremiah 29:11',
        translationId: 'kjv',
      );
    }
  }

  Future<DailyVerse?> _getCachedForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final dateStr = data['date'] as String?;
      final todayStr = _todayString();
      if (dateStr == todayStr) {
        final verse = data['verse'] as String? ?? '';
        final reference = data['reference'] as String? ?? '';
        final isFallback =
            reference.trim().toLowerCase().startsWith('jeremiah 29:11');
        final translationId =
            (data['translationId'] as String? ?? 'kjv').trim();
        if (!isFallback && verse.isNotEmpty && reference.isNotEmpty) {
          return DailyVerse(
            verse: verse.trim(),
            reference: reference.trim(),
            translationId: translationId,
          );
        }
      }
    } catch (e) {
      debugPrint('Daily verse cache read error: $e');
    }
    return null;
  }

  Future<void> _cacheToday(DailyVerse verse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'date': _todayString(),
        'verse': verse.verse,
        'reference': verse.reference,
        'translationId': verse.translationId,
      };
      await prefs.setString(_cacheKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('Daily verse cache write error: $e');
    }
  }

  Future<DailyVerse> _fetchRandomKjvVerse() async {
    // Restrict random verse to: Psalms, Proverbs, John, Paul's Epistles, Hebrews, James, 1-2 Peter, 1-3 John
    // Using standard USFM book identifiers
    const allowedBooks =
        'PSA,PRO,JHN,ROM,1CO,2CO,GAL,EPH,PHP,COL,1TH,2TH,1TI,2TI,TIT,PHM,HEB,JAS,1PE,2PE,1JN,2JN,3JN';
    final uri = Uri.parse('$_baseUrl/data/kjv/random/$allowedBooks');

    final res = await http.get(uri, headers: {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Bible API returned ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    // Handle multiple possible shapes defensively
    String verseText = '';
    String reference = '';
    String translationId = 'kjv';

    if (data is Map<String, dynamic>) {
      if (data['translation'] is Map<String, dynamic>) {
        final t = data['translation'] as Map<String, dynamic>;
        final id = t['identifier'] as String?;
        if (id != null && id.isNotEmpty) {
          translationId = id.toLowerCase();
        }
      }
      if (data['random_verse'] is Map<String, dynamic>) {
        final rv = data['random_verse'] as Map<String, dynamic>;
        verseText = (rv['text'] as String? ?? '').trim();
        final book = rv['book'] as String? ?? '';
        final chapter = rv['chapter'];
        final verseNum = rv['verse'];
        if (book.isNotEmpty && chapter != null && verseNum != null) {
          reference = _formatReference(book, chapter, verseNum);
        }
      }

      if (data['verses'] is List && (data['verses'] as List).isNotEmpty) {
        final first = (data['verses'] as List).first;
        if (first is Map<String, dynamic>) {
          verseText = (first['text'] as String? ?? '').trim();
          final bookName = data['book_name'] as String? ??
              first['book_name'] as String? ??
              '';
          final chapter = data['chapter'] ?? first['chapter'];
          final verseNum = first['verse'];
          if (bookName.isNotEmpty && chapter != null && verseNum != null) {
            reference = _formatReference(bookName, chapter, verseNum);
          }
        }
      }

      // If not found, try direct fields
      if (verseText.isEmpty) {
        verseText = (data['text'] as String? ?? '').trim();
      }
      if (reference.isEmpty) {
        final bookName = data['book_name'] as String? ?? '';
        final chapter = data['chapter'];
        final verseNum = data['verse'];
        if (bookName.isNotEmpty && chapter != null && verseNum != null) {
          reference = _formatReference(bookName, chapter, verseNum);
        }
      }

      // Fallback: if "reference" field exists
      if (reference.isEmpty && data['reference'] is String) {
        reference = (data['reference'] as String).trim();
      }
    }

    if (verseText.isEmpty || reference.isEmpty) {
      // As a fallback, try user-input API with a well-known verse to avoid empty UI
      return DailyVerse(
        verse:
            '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
        reference: 'Jeremiah 29:11',
        translationId: translationId,
      );
    }

    return DailyVerse(
      verse: verseText,
      reference: reference,
      translationId: translationId,
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatReference(String book, dynamic chapter, dynamic verseNum) {
    final singleChapterBooks = {
      'obadiah',
      'philemon',
      '2 john',
      '3 john',
      'jude',
    };
    final normalizedBook = book.trim().toLowerCase();
    if (singleChapterBooks.contains(normalizedBook)) {
      return '$book $verseNum';
    }
    return '$book $chapter:$verseNum';
  }
}
