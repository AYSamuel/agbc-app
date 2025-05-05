import 'package:flutter/foundation.dart';
import '../models/church_branch_model.dart';
import '../providers/supabase_provider.dart';

class BranchesProvider extends ChangeNotifier {
  final SupabaseProvider _supabaseProvider;
  List<ChurchBranch> _branches = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  BranchesProvider(this._supabaseProvider);

  List<ChurchBranch> get branches => _branches;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      final branches = await _supabaseProvider.getAllBranches().first;
      _branches = branches;
      _isInitialized = true;
    } catch (e) {
      // Handle error silently in production
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      _isLoading = true;
      notifyListeners();

      final branches = await _supabaseProvider.getAllBranches().first;
      _branches = branches;
    } catch (e) {
      // Handle error silently in production
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
