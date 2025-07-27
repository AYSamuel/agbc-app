import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/church_branch_model.dart';

class BranchesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChurchBranch> _branches = [];
  bool _isLoading = false;
  String? _error;

  List<ChurchBranch> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all branches from the church_branches table
  Future<void> fetchBranches() async {
    _setLoading(true);
    _error = null;

    try {
      final response =
          await _supabase.from('church_branches').select('*').order('name');

      _branches = (response as List)
          .map((json) => ChurchBranch.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch branches: $e';
      if (kDebugMode) {
        print('Error fetching branches: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific branch by ID
  ChurchBranch? getBranchById(String id) {
    try {
      return _branches.firstWhere((branch) => branch.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get branch name by ID (useful for display purposes)
  String getBranchName(String? branchId) {
    if (branchId == null) return 'No Branch';
    final branch = getBranchById(branchId);
    return branch?.name ?? 'Unknown Branch';
  }

  /// Add a new branch to the database
  Future<bool> addBranch(ChurchBranch branch) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _supabase
          .from('church_branches')
          .insert(branch.toJson())
          .select()
          .single();

      final newBranch = ChurchBranch.fromJson(response);
      _branches.add(newBranch);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add branch: $e';
      if (kDebugMode) {
        print('Error adding branch: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing branch
  Future<bool> updateBranch(ChurchBranch branch) async {
    _setLoading(true);
    _error = null;

    try {
      await _supabase
          .from('church_branches')
          .update(branch.toJson())
          .eq('id', branch.id);

      final index = _branches.indexWhere((b) => b.id == branch.id);
      if (index != -1) {
        _branches[index] = branch;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update branch: $e';
      if (kDebugMode) {
        print('Error updating branch: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a branch
  Future<bool> deleteBranch(String branchId) async {
    _setLoading(true);
    _error = null;

    try {
      await _supabase.from('church_branches').delete().eq('id', branchId);

      _branches.removeWhere((branch) => branch.id == branchId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete branch: $e';
      if (kDebugMode) {
        print('Error deleting branch: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get branches as a stream for real-time updates
  Stream<List<ChurchBranch>> getBranchesStream() {
    return _supabase
        .from('church_branches')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
            (data) => data.map((json) => ChurchBranch.fromJson(json)).toList());
  }

  /// Search branches by name or location
  List<ChurchBranch> searchBranches(String query) {
    if (query.isEmpty) return _branches;

    final lowercaseQuery = query.toLowerCase();
    return _branches.where((branch) {
      return branch.name.toLowerCase().contains(lowercaseQuery) ||
          (branch.address.toLowerCase().contains(lowercaseQuery)) ||
          ((branch.location['city']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowercaseQuery) ??
              false)) ||
          (branch.location['country']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh branches data
  Future<void> refresh() async {
    await fetchBranches();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
