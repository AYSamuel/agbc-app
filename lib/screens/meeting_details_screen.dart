import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting_model.dart';
import '../models/meeting_response_model.dart';
import '../models/user_model.dart';
import '../models/initial_notification_config.dart';
import '../providers/supabase_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_input.dart';

/// A screen that displays the details of a meeting with RSVP functionality
class MeetingDetailsScreen extends StatefulWidget {
  final MeetingModel meeting;

  const MeetingDetailsScreen({
    required this.meeting,
    super.key,
  });

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  late MeetingModel _meeting;
  UserModel? _organizer;
  MeetingResponseModel? _userResponse;
  MeetingAttendanceSummary? _attendanceSummary;
  bool _isLoading = false;
  bool _canViewAttendance = false;
  String? _reasonText;
  final TextEditingController _reasonController = TextEditingController();
  
  // Auto-save state variables
  Timer? _autoSaveTimer;
  bool _isAutoSaving = false;
  bool _autoSaveSuccess = false;
  String? _autoSaveError;
  String? _lastSavedReason;

  @override
  void initState() {
    super.initState();
    _meeting = widget.meeting;
    _loadMeetingData();
    
    // Set status bar to transparent with dark icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _reasonController.dispose();
    // Reset status bar to default when leaving the screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _loadMeetingData() async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load organizer details
      final organizerStream = supabaseProvider.getUser(_meeting.organizerId);
      organizerStream.listen((user) {
        if (mounted) {
          setState(() {
            _organizer = user;
          });
        }
      });

      // Load user's current response
      final userResponse = await supabaseProvider.getUserMeetingResponse(_meeting.id);
      if (mounted) {
        setState(() {
          _userResponse = userResponse;
          _reasonText = userResponse?.reason;
          _lastSavedReason = userResponse?.reason;
          if (_reasonText != null) {
            _reasonController.text = _reasonText!;
          }
        });
        
        // Set up auto-save listener for reason field
        _setupAutoSaveListener();
      }

      // Check if user can view attendance data
      final canView = await supabaseProvider.canViewAttendanceData(_meeting.id);
      if (mounted) {
        setState(() {
          _canViewAttendance = canView;
        });
      }

      // Load attendance summary if user can view it
      if (canView) {
        final summary = await supabaseProvider.getMeetingAttendanceSummary(_meeting.id);
        if (mounted) {
          setState(() {
            _attendanceSummary = summary;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading meeting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meeting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Sets up the auto-save listener for the reason text field
  void _setupAutoSaveListener() {
    _reasonController.addListener(_onReasonTextChanged);
  }

  /// Handles text changes in the reason field and triggers debounced auto-save
  void _onReasonTextChanged() {
    // Only auto-save if user has selected "Not Attending"
    if (_userResponse?.responseType != ResponseType.notAttending) {
      return;
    }

    final currentText = _reasonController.text.trim();
    
    // Don't auto-save if text hasn't changed from last saved version
    if (currentText == (_lastSavedReason ?? '')) {
      return;
    }

    // Cancel existing timer
    _autoSaveTimer?.cancel();
    
    // Reset auto-save status
    setState(() {
      _autoSaveSuccess = false;
      _autoSaveError = null;
    });

    // Set up new timer for debounced save (2 seconds after user stops typing)
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _autoSaveReason(currentText);
    });
  }

  /// Auto-saves the reason text
  Future<void> _autoSaveReason(String reasonText) async {
    // Don't auto-save if already saving or if user response doesn't exist
    if (_isAutoSaving || _userResponse == null) {
      return;
    }

    // Don't auto-save if not "Not Attending"
    if (_userResponse!.responseType != ResponseType.notAttending) {
      return;
    }

    setState(() {
      _isAutoSaving = true;
      _autoSaveSuccess = false;
      _autoSaveError = null;
    });

    try {
      final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
      
      await supabaseProvider.submitMeetingResponse(
        meetingId: _meeting.id,
        responseType: ResponseType.notAttending,
        reason: reasonText.isEmpty ? null : reasonText,
      );

      if (mounted) {
        setState(() {
          _lastSavedReason = reasonText;
          _autoSaveSuccess = true;
          _autoSaveError = null;
          
          // Update the user response model
          _userResponse = _userResponse!.copyWith(
            reason: reasonText.isEmpty ? null : reasonText,
            updatedAt: DateTime.now(),
          );
        });

        // Hide success indicator after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _autoSaveSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Auto-save error: $e');
      if (mounted) {
        setState(() {
          _autoSaveError = 'Failed to save: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    }
  }

  Future<void> _submitResponse(ResponseType responseType) async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    
    // Clear reason text if not selecting "Not Attending"
    if (responseType != ResponseType.notAttending) {
      _reasonController.clear();
    }
    
    // Cancel any pending auto-save and reset auto-save state
    _autoSaveTimer?.cancel();
    
    setState(() {
      _isLoading = true;
      _isAutoSaving = false;
      _autoSaveSuccess = false;
      _autoSaveError = null;
    });

    try {
      final reasonText = responseType == ResponseType.notAttending 
          ? (_reasonController.text.trim().isEmpty ? null : _reasonController.text.trim())
          : null;
          
      await supabaseProvider.submitMeetingResponse(
        meetingId: _meeting.id,
        responseType: responseType,
        reason: reasonText,
      );

      if (mounted) {
        setState(() {
          _userResponse = MeetingResponseModel(
            userId: supabaseProvider.currentUser?.id ?? '',
            meetingId: _meeting.id,
            responseType: responseType,
            reason: reasonText,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _lastSavedReason = reasonText;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: const Text('RSVP updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload attendance summary if user can view it
        if (_canViewAttendance) {
          final summary = await supabaseProvider.getMeetingAttendanceSummary(_meeting.id);
          if (mounted) {
            setState(() {
              _attendanceSummary = summary;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error submitting response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting RSVP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getResponseColor(ResponseType responseType) {
    switch (responseType) {
      case ResponseType.attending:
        return Colors.green;
      case ResponseType.maybe:
        return Colors.orange;
      case ResponseType.notAttending:
        return Colors.red;
    }
  }

  IconData _getResponseIcon(ResponseType responseType) {
    switch (responseType) {
      case ResponseType.attending:
        return Remix.check_line;
      case ResponseType.maybe:
        return Remix.question_line;
      case ResponseType.notAttending:
        return Remix.close_line;
    }
  }

  Widget _buildRSVPButton(ResponseType responseType) {
    final isSelected = _userResponse?.responseType == responseType;
    final color = _getResponseColor(responseType);
    
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : () => _submitResponse(responseType),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getResponseIcon(responseType),
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  responseType.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNeutralColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _meeting.isVirtual ? Remix.video_line : Remix.map_pin_line,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_meeting.isVirtual && _meeting.meetingLink != null && _meeting.meetingLink!.isNotEmpty)
            // Clickable Virtual Meeting Link
            InkWell(
              onTap: () => _openMeetingLink(_meeting.meetingLink!),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Virtual Meeting',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
            )
          else if (_meeting.isVirtual)
            // Non-clickable Virtual Meeting (no link provided)
            Text(
              'Virtual Meeting',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNeutralColor,
              ),
            )
          else
            // Physical Location
            Text(
              _meeting.location,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNeutralColor,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMeetingLink(String url) async {
    if (!mounted) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Opening meeting link...',
              style: GoogleFonts.inter(),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    try {
      // Validate and normalize URL
      String normalizedUrl = _normalizeUrl(url);
      final uri = Uri.parse(normalizedUrl);

      // Validate URL format
      if (!_isValidUrl(uri)) {
        _showErrorWithFallback(normalizedUrl, 'Invalid meeting link format');
        return;
      }

      // Try multiple launch modes in order of preference
      bool launched = false;

      // 1. Try external application (native meeting apps)
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          _showSuccessMessage();
        }
      } catch (e) {
        print('External application launch failed: $e');
      }

      // 2. If external app failed, try platform default
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          launched = true;
          _showSuccessMessage();
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }

      // 3. If platform default failed, try in-app web view
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          launched = true;
          _showSuccessMessage();
        } catch (e) {
          print('In-app web view launch failed: $e');
        }
      }

      // 4. If all methods failed, show fallback options
      if (!launched) {
        _showErrorWithFallback(normalizedUrl, 'Unable to open meeting link automatically');
      }

    } catch (e) {
      print('URL parsing error: $e');
      _showErrorWithFallback(url, 'Error processing meeting link: ${e.toString()}');
    }
  }

  String _normalizeUrl(String url) {
    // Ensure URL has proper protocol
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  bool _isValidUrl(Uri uri) {
    // Basic URL validation
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      return false;
    }
    
    // Check for common meeting platforms
    final validSchemes = ['http', 'https', 'zoom', 'teams', 'meet'];
    return validSchemes.contains(uri.scheme.toLowerCase());
  }

  void _showSuccessMessage() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Meeting link opened successfully',
              style: GoogleFonts.inter(),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorWithFallback(String url, String errorMessage) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Meeting Link Issue',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 16),
              Text(
                'You can try these alternatives:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '• Copy the link and paste it in your browser',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              Text(
                '• Install the meeting app (Zoom, Teams, etc.)',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              Text(
                '• Contact the meeting organizer for help',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(
                'Copy Link',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.content_copy, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Meeting link copied to clipboard',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to copy link: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAttendanceSummary() {
    if (!_canViewAttendance || _attendanceSummary == null) {
      return const SizedBox.shrink();
    }

    final summary = _attendanceSummary!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Remix.group_line,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Summary stats
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStatCard(
                  'Attending',
                  summary.attending.toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceStatCard(
                  'Maybe',
                  summary.maybe.toString(),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceStatCard(
                  'Not Attending',
                  summary.notAttending.toString(),
                  Colors.red,
                ),
              ),
            ],
          ),
          
          if (summary.responses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Responses',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkNeutralColor,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.responses.map((response) => _buildResponseItem(response)),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseItem(MeetingResponseWithUser response) {
    final color = _getResponseColor(response.responseType);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              response.userName,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.darkNeutralColor,
              ),
            ),
          ),
          Text(
            response.responseType.displayName,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStatus() {
    final config = _meeting.initialNotificationConfig;
    
    // If no notification config, don't show the section
    if (config == null) {
      return const SizedBox.shrink();
    }

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!config.enabled) {
      statusText = 'No initial notification sent';
      statusColor = Colors.grey;
      statusIcon = Remix.notification_off_line;
    } else if (config.timing == NotificationTiming.immediate) {
      if (_meeting.initialNotificationSent) {
        statusText = 'Notification sent immediately';
        statusColor = Colors.green;
        statusIcon = Remix.notification_line;
      } else {
        statusText = 'Immediate notification pending';
        statusColor = Colors.orange;
        statusIcon = Remix.notification_line;
      }
    } else if (config.timing == NotificationTiming.scheduled) {
      if (config.scheduledDateTime != null) {
        final now = DateTime.now();
        final scheduledTime = config.scheduledDateTime!;
        
        if (_meeting.initialNotificationSent) {
          statusText = 'Scheduled notification sent';
          statusColor = Colors.green;
          statusIcon = Remix.notification_line;
        } else if (scheduledTime.isAfter(now)) {
          statusText = 'Notification scheduled for ${DateFormat('MMM dd, h:mm a').format(scheduledTime)}';
          statusColor = Colors.blue;
          statusIcon = Remix.time_line;
        } else {
          statusText = 'Scheduled notification pending';
          statusColor = Colors.orange;
          statusIcon = Remix.notification_line;
        }
      } else {
        statusText = 'Scheduled notification (time not set)';
        statusColor = Colors.grey;
        statusIcon = Remix.notification_line;
      }
    } else {
      statusText = 'Unknown notification status';
      statusColor = Colors.grey;
      statusIcon = Remix.question_line;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Remix.notification_3_line,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Notification Status',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                statusIcon,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_meeting.initialNotificationSent && _meeting.initialNotificationSentAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Remix.check_line,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sent on ${DateFormat('MMM dd, h:mm a').format(_meeting.initialNotificationSentAt!)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CustomBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Meeting Details',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNeutralColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meeting Title
                    Text(
                      _meeting.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNeutralColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Meeting Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Remix.file_text_line,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _meeting.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date, Time, and Location
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Date',
                            DateFormat('MMM dd, yyyy').format(_meeting.dateTime),
                            AppTheme.primaryColor,
                            Remix.calendar_line,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            'Time',
                            DateFormat('h:mm a').format(_meeting.dateTime),
                            AppTheme.primaryColor,
                            Remix.time_line,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location and Organizer
                    Row(
                      children: [
                        Expanded(
                          child: _buildLocationCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            'Organizer',
                            _organizer?.displayName ?? _meeting.organizerName,
                            AppTheme.primaryColor,
                            Remix.user_line,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notification Status Section (only visible to pastors and admins)
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final currentUser = authService.currentUserProfile;
                        final canViewNotificationStatus = currentUser?.isAdmin == true || currentUser?.isPastor == true;
                        
                        if (canViewNotificationStatus) {
                          return Column(
                            children: [
                              _buildNotificationStatus(),
                              const SizedBox(height: 24),
                            ],
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),

                    // RSVP Section - Only show if user can RSVP to this meeting
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final currentUser = authService.currentUserProfile;
                        final canRSVP = _meeting.shouldNotify(currentUser?.branchId);
                        
                        if (canRSVP) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Remix.calendar_check_line,
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'RSVP',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // RSVP Buttons
                                Row(
                                  children: [
                                    _buildRSVPButton(ResponseType.attending),
                                    const SizedBox(width: 8),
                                    _buildRSVPButton(ResponseType.maybe),
                                    const SizedBox(width: 8),
                                    _buildRSVPButton(ResponseType.notAttending),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Reason Text Field - Only show for "Not Attending"
                                if (_userResponse?.responseType == ResponseType.notAttending)
                                  _buildReasonFieldWithAutoSave(),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Attendance Summary (for authorized users)
                    _buildAttendanceSummary(),
                    
                    // Loading indicator
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the reason text field with auto-save visual feedback
  Widget _buildReasonFieldWithAutoSave() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main text field
        CustomInput(
          controller: _reasonController,
          label: 'Reason (Optional)',
          hint: 'Add a note about your response...',
          maxLines: 3,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 8),
        
        // Auto-save status and helper text
        Row(
          children: [
            // Auto-save status indicator
            if (_isAutoSaving)
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else if (_autoSaveSuccess)
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else if (_autoSaveError != null)
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _autoSaveError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Your reason is automatically saved as you type',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ],
    );
  }
}