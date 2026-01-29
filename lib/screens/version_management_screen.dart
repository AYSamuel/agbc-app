import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:remixicon/remixicon.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_toast.dart';

class VersionManagementScreen extends StatefulWidget {
  const VersionManagementScreen({super.key});

  @override
  State<VersionManagementScreen> createState() =>
      _VersionManagementScreenState();
}

class _VersionManagementScreenState extends State<VersionManagementScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _versions = [];

  @override
  void initState() {
    super.initState();
    _fetchVersions();
  }

  Future<void> _fetchVersions() async {
    try {
      final data = await _supabase
          .from('app_versions')
          .select()
          .order('platform', ascending: true);

      setState(() {
        _versions = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: 'Error loading versions: $e', type: ToastType.error);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateVersion(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('app_versions').update(updates).eq('id', id);
      if (mounted) {
        CustomToast.show(context,
            message: 'Version updated successfully', type: ToastType.success);
        _fetchVersions();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: 'Error updating version: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CustomBackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Versions',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          'Manage force updates',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _versions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final version = _versions[index];
                        return _VersionCard(
                          data: version,
                          onSave: (updates) =>
                              _updateVersion(version['id'], updates),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onSave;

  const _VersionCard({required this.data, required this.onSave});

  @override
  State<_VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends State<_VersionCard> {
  late TextEditingController _minVersionController;
  late TextEditingController _latestVersionController;
  late TextEditingController _storeUrlController;
  late bool _forceUpdate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _minVersionController =
        TextEditingController(text: widget.data['min_version']);
    _latestVersionController =
        TextEditingController(text: widget.data['latest_version']);
    _storeUrlController = TextEditingController(text: widget.data['store_url']);
    _forceUpdate = widget.data['force_update'] ?? false;
  }

  @override
  void dispose() {
    _minVersionController.dispose();
    _latestVersionController.dispose();
    _storeUrlController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_VersionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data && !_isEditing) {
      _minVersionController.text = widget.data['min_version'];
      _latestVersionController.text = widget.data['latest_version'];
      _storeUrlController.text = widget.data['store_url'];
      _forceUpdate = widget.data['force_update'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = widget.data['platform'] == 'android';
    final color = isAndroid ? Colors.green : Colors.grey;
    final icon = isAndroid ? Remix.android_fill : Remix.apple_fill;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.inputBorderColor(context),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                widget.data['platform'].toString().toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isEditing ? Remix.close_line : Remix.edit_line),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      // Cancel changes
                      _minVersionController.text = widget.data['min_version'];
                      _latestVersionController.text =
                          widget.data['latest_version'];
                      _storeUrlController.text = widget.data['store_url'];
                      _forceUpdate = widget.data['force_update'] ?? false;
                    }
                    _isEditing = !_isEditing;
                  });
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Form Fields
          _buildField('Min Version', _minVersionController),
          const SizedBox(height: 12),
          _buildField('Latest Version', _latestVersionController),
          const SizedBox(height: 12),
          _buildField('Store URL', _storeUrlController),
          const SizedBox(height: 12),

          Row(
            children: [
              Switch(
                value: _forceUpdate,
                onChanged: _isEditing
                    ? (val) => setState(() => _forceUpdate = val)
                    : null,
                activeTrackColor: Colors.red,
                activeThumbColor: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Emergency Force Update',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),

          if (_isEditing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Remix.alert_line, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Warning: Changes affect all users immediately. Incorrect versions may block app access.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Changes'),
                      content: const Text(
                        'Are you sure you want to update the app version settings? This will immediately affect user experience and could potentially block users from accessing the app if configured incorrectly.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onSave({
                              'min_version': _minVersionController.text,
                              'latest_version': _latestVersionController.text,
                              'store_url': _storeUrlController.text,
                              'force_update': _forceUpdate,
                            });
                            setState(() => _isEditing = false);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Yes, Update'),
                        ),
                      ],
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary(context),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: _isEditing,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.inputBorderColor(context)),
            ),
            filled: !_isEditing,
            fillColor: _isEditing ? null : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
