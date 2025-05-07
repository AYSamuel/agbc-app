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

      // Get initial data immediately
      final initialBranches = await _supabaseProvider.getAllBranches().first;
      _branches = initialBranches;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();

      // Then listen to updates
      _supabaseProvider.getAllBranches().listen(
        (branches) {
          _branches = branches;
          notifyListeners();
        },
        onError: (error) {
          // Handle error silently in production
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Handle error silently in production
    }
  }

  Future<void> refresh() async {
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

  String getBranchName(String branchId) {
    if (!_isInitialized || _isLoading) {
      return 'Loading...';
    }

    final branch = _branches.firstWhere(
      (branch) => branch.id == branchId,
      orElse: () => ChurchBranch(
        id: branchId,
        name: 'Unknown Branch',
        address: '',
        members: [],
        departments: [],
        location: '',
        createdBy: '',
      ),
    );
    return branch.name;
  }
}
