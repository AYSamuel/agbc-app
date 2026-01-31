import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/supabase_provider.dart';
import '../models/church_branch_model.dart';
import '../config/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/branch_details_sheet.dart';
import '../widgets/branch_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabaseProvider = Provider.of<SupabaseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : AppTheme.primary(context).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomBackButton(
                            onPressed: () => Navigator.pop(context),
                            showBackground: false,
                            showShadow: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary(context)
                                    .withValues(alpha: 0.15),
                                AppTheme.secondary(context)
                                    .withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primary(context)
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Remix.team_fill,
                            color: AppTheme.primary(context),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our Community',
                                style: GoogleFonts.roboto(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Explore our church branches',
                                style: GoogleFonts.roboto(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search branches...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted(context),
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Remix.search_line,
                            color: AppTheme.textMuted(context),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Remix.close_circle_fill,
                                    color: AppTheme.textMuted(context),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Branches List
            Expanded(
              child: StreamBuilder<List<ChurchBranch>>(
                stream: supabaseProvider.getAllBranches(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(context, snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary(context),
                      ),
                    );
                  }

                  var branches = snapshot.data!
                      .where((branch) => branch.isActive)
                      .toList();

                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    branches = branches.where((branch) {
                      final name = branch.name.toLowerCase();
                      final address = branch.address.toLowerCase();
                      final city =
                          branch.location['city']?.toString().toLowerCase() ??
                              '';
                      final country = branch.location['country']
                              ?.toString()
                              .toLowerCase() ??
                          '';
                      return name.contains(_searchQuery) ||
                          address.contains(_searchQuery) ||
                          city.contains(_searchQuery) ||
                          country.contains(_searchQuery);
                    }).toList();
                  }

                  // Sort alphabetically
                  branches.sort((a, b) => a.name.compareTo(b.name));

                  if (branches.isEmpty) {
                    return _buildEmptyState(context, _searchQuery.isNotEmpty);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return BranchCard(
                        branch: branch,
                        onView: () => _showBranchDetails(context, branch),
                        showActions: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Remix.search_line : Remix.community_line,
                size: 48,
                color: AppTheme.primary(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'No branches found' : 'No Branches Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search'
                  : 'Branches will appear here once they are added.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Remix.error_warning_line,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load branches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBranchDetails(
      BuildContext context, ChurchBranch branch) async {
    try {
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);

      // Get all users in this branch
      final users = await supabaseProvider.getAllUsers().first;
      final branchMembers =
          users.where((user) => user.branchId == branch.id).toList();

      if (!context.mounted) return;

      BranchDetailsSheet.show(
        context,
        branch: branch,
        members: branchMembers,
        showMemberEmails: false, // Hide emails for regular users
      );
    } catch (e) {
      debugPrint('Error showing branch details: $e');
    }
  }
}
