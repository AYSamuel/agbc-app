import 'package:flutter/foundation.dart';
import '../models/church_branch_model.dart';
import '../providers/supabase_provider.dart';
import 'package:logging/logging.dart';
import 'dart:async';

class BranchesProvider extends ChangeNotifier {
  final SupabaseProvider _supabaseProvider;
  List<ChurchBranch> _branches = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  final _logger = Logger('BranchesProvider');
  StreamSubscription<List<ChurchBranch>>? _branchesSubscription;

  BranchesProvider(this._supabaseProvider);

  List<ChurchBranch> get branches => _branches;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    _branchesSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Cancel any existing subscription
      await _branchesSubscription?.cancel();

      // Set up the stream subscription first
      _branchesSubscription = _supabaseProvider.getAllBranches().listen(
        (branches) {
          _branches = branches;
          _isInitialized = true;
          _logger.info('Received branch update: ${branches.length} branches');
          notifyListeners();
        },
        onError: (error) {
          _logger.severe('Error listening to branch updates: $error');
          _branches = [];
          _isInitialized = true; // Mark as initialized even on error
          notifyListeners();
        },
      );

      // Get initial data
      try {
        final initialBranches = await _supabaseProvider.getAllBranches().first;
        _branches = initialBranches;
        _isInitialized = true;
        _logger.info(
            'Successfully initialized branches: ${initialBranches.length} branches loaded');
      } catch (e) {
        _logger.warning('Error getting initial branches: $e');
        _branches = [];
        _isInitialized = true; // Mark as initialized even on error
      }
    } catch (e) {
      _logger.severe('Error initializing branches: $e');
      _branches = [];
      _isInitialized = true; // Mark as initialized even on error
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
      _isInitialized = true;
      _logger.info('Refreshed branches: ${branches.length} branches loaded');
    } catch (e) {
      _logger.severe('Error refreshing branches: $e');
      _branches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getBranchName(String branchId) {
    if (!_isInitialized || _isLoading) {
      return 'Loading...';
    }

    _logger.info('Getting branch name for ID: $branchId');
    _logger.info(
        'Available branches: ${_branches.map((b) => '${b.id}: ${b.name}').join(', ')}');

    final branch = _branches.firstWhere(
      (branch) => branch.id == branchId,
      orElse: () {
        _logger.warning('Branch not found for ID: $branchId');
        return ChurchBranch(
          id: branchId,
          name: 'No branch joined yet',
          address: '',
          members: [],
          departments: [],
          location: '',
          createdBy: '',
        );
      },
    );
    return branch.name;
  }

  void setBranches(List<ChurchBranch> branches) {
    _branches = branches;
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }
}
