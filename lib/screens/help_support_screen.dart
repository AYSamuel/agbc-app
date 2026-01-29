import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:remixicon/remixicon.dart';
import '../config/theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_toast.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
                    child: Row(
                      children: [
                        if (canPop) ...[
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
                        ],
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Remix.question_line,
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
                                'Help & Support',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'We\'re here to help you',
                                style: TextStyle(
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
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Child Safety Alert - Prominent section
                  _buildChildSafetyAlert(),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _buildSectionHeader('Quick Actions'),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Remix.mail_line,
                    title: 'Email Support',
                    subtitle: 'oami.gospel@gmail.com',
                    color: AppTheme.primary(context),
                    onTap: () => _launchEmail(),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Remix.phone_line,
                    title: 'Call Church Office',
                    subtitle: '+447342920067',
                    color: AppTheme.success(context),
                    onTap: () => _launchPhone(),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Remix.bug_line,
                    title: 'Report a Problem',
                    subtitle: 'Help us improve the app',
                    color: AppTheme.warning(context),
                    onTap: () => _reportProblem(),
                  ),

                  const SizedBox(height: 24),

                  // FAQ Section
                  _buildSectionHeader('Frequently Asked Questions'),
                  const SizedBox(height: 12),
                  _buildFAQCard(
                    question: 'How do I submit a prayer request?',
                    answer:
                        'Go to the Prayer screen from the bottom navigation bar. Tap the "+" button to create a new prayer request. You can choose to make it public or private.',
                  ),
                  const SizedBox(height: 8),
                  _buildFAQCard(
                    question: 'How do I view my assigned tasks?',
                    answer:
                        'Your assigned tasks appear on the Home screen. Tap on any task to view details, add notes, or mark it as complete when finished.',
                  ),
                  const SizedBox(height: 8),
                  _buildFAQCard(
                    question: 'How do I join or RSVP to a meeting?',
                    answer:
                        'Upcoming meetings are shown on the Home screen. Tap on a meeting to view details and RSVP. You\'ll receive notifications before the meeting starts.',
                  ),
                  const SizedBox(height: 8),
                  _buildFAQCard(
                    question: 'How do I contact church administration?',
                    answer:
                        'You can email the church office at oami.gospel@gmail.com or call +447342920067. For urgent matters, use the Quick Actions section above.',
                  ),

                  const SizedBox(height: 24),

                  // Getting Started Guide
                  _buildSectionHeader('Getting Started'),
                  const SizedBox(height: 12),
                  _buildGuideCard(
                    icon: Remix.checkbox_circle_line,
                    title: 'Managing Tasks',
                    description:
                        'View assigned tasks on the Home screen. Tap any task to see details, mark as complete, or add updates.',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard(
                    icon: Remix.calendar_event_line,
                    title: 'Joining Meetings',
                    description:
                        'Check upcoming meetings on the Home screen. Tap to RSVP and view meeting details, agendas, and locations.',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard(
                    icon: Remix.group_line,
                    title: 'Understanding Your Role',
                    description:
                        'Your role (Member, Admin, etc.) determines what features you can access. Contact church leadership for role changes.',
                  ),

                  const SizedBox(height: 24),

                  // Legal & Policies
                  _buildSectionHeader('Legal & Policies'),
                  const SizedBox(height: 12),
                  _buildLinkCard(
                    icon: Remix.shield_user_line,
                    title: 'Privacy Policy',
                    onTap: () => _launchURL(
                        'https://aysamuel.github.io/agbc-app/privacy-policy.html'),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkCard(
                    icon: Remix.delete_bin_line,
                    title: 'Data Deletion Policy',
                    onTap: () => _launchURL(
                        'https://aysamuel.github.io/agbc-app/data-deletion.html'),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkCard(
                    icon: Remix.shield_check_line,
                    title: 'Child Safety Standards',
                    onTap: () => _launchURL(
                        'https://aysamuel.github.io/agbc-app/child-safety-standards.html'),
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionHeader('About'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Remix.information_line,
                    title: 'App Version',
                    subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    icon: Remix.community_line,
                    title: 'About AGBC',
                    subtitle: 'Amazing Grace Bible Church',
                    onTap: () => _showAboutDialog(),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkCard(
                    icon: Remix.star_line,
                    title: 'Rate the App',
                    onTap: () => _rateApp(),
                  ),

                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSectionHeader('Contact Information'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amazing Grace Bible Church',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(Icons.location_on_rounded,
                            'SUMMERLEE MUSEUM OF SCOTTISH INDUSTRIAL LIFE\nHERITAGE WAY, COATBRIDGE ML5 1QD'),
                        const SizedBox(height: 8),
                        _buildContactRow(
                            Icons.email_rounded, 'oami.gospel@gmail.com'),
                        const SizedBox(height: 8),
                        _buildContactRow(Icons.phone_rounded, '+447342920067'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSafetyAlert() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).brightness == Brightness.light
                ? Colors.red.shade50
                : Colors.red.shade900.withValues(alpha: 0.2),
            Theme.of(context).brightness == Brightness.light
                ? Colors.red.shade100
                : Colors.red.shade900.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Child Safety Reporting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If you suspect child abuse or have safety concerns, please report immediately:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade900,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency button
                _buildSafetyActionButton(
                  icon: Icons.emergency,
                  title: 'EMERGENCY (999/911)',
                  subtitle: 'Immediate danger - Call emergency services',
                  color: Colors.red.shade700,
                  onTap: () => _callEmergency(),
                ),
                const SizedBox(height: 10),

                // NSPCC Helpline
                _buildSafetyActionButton(
                  icon: Icons.support_agent_rounded,
                  title: 'NSPCC Helpline',
                  subtitle: '0808 800 5000 (UK)',
                  color: Colors.orange.shade700,
                  onTap: () => _callNSPCC(),
                ),
                const SizedBox(height: 10),

                // Report to church
                _buildSafetyActionButton(
                  icon: Icons.email_rounded,
                  title: 'Report to Church Leadership',
                  subtitle: 'Send urgent child safety concern email',
                  color: Colors.red.shade600,
                  onTap: () => _reportChildSafetyConcern(),
                ),
                const SizedBox(height: 12),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'All reports are taken seriously. You may report anonymously. View our full Child Safety Standards policy below.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary(context),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard({required String question, required String answer}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary(context), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary(context), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  size: 18, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary(context), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primary(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'oami.gospel@gmail.com',
      query: 'subject=GRACE PORTAL Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        CustomToast.show(context,
            message: 'Could not open email app', type: ToastType.error);
      }
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+447342920067');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        CustomToast.show(context,
            message: 'Could not open phone app', type: ToastType.error);
      }
    }
  }

  Future<void> _reportProblem() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'oami.gospel@gmail.com',
      query:
          'subject=GRACE PORTAL - Problem Report&body=Please describe the issue you encountered:\n\nApp Version: $_appVersion',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      // Use platformDefault to show browser options on Android
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: 'Could not open link', type: ToastType.error);
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AGBC'),
        content: const Text(
          'Amazing Grace Bible Church (AGBC) is committed to building a strong, connected, and engaged community of believers. GRACE PORTAL is our way of ensuring every member stays connected and involved in the life of our church.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // In production, this would open the Play Store/App Store
    CustomToast.show(context,
        message: 'Thank you! This will open the app store when published.');
  }

  Future<void> _callEmergency() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Call Emergency Services?'),
          ],
        ),
        content: const Text(
          'This will dial emergency services (999 in UK / 911 in US).\n\nOnly call if there is immediate danger to a child.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Try UK emergency number first, then US
      final Uri emergencyUri = Uri(scheme: 'tel', path: '999');
      if (await canLaunchUrl(emergencyUri)) {
        await launchUrl(emergencyUri);
      } else {
        if (mounted) {
          CustomToast.show(context,
              message: 'Could not open phone dialer', type: ToastType.error);
        }
      }
    }
  }

  Future<void> _callNSPCC() async {
    final Uri nspccUri = Uri(scheme: 'tel', path: '08088005000');
    if (await canLaunchUrl(nspccUri)) {
      await launchUrl(nspccUri);
    } else {
      if (mounted) {
        CustomToast.show(context,
            message: 'Could not open phone dialer', type: ToastType.error);
      }
    }
  }

  Future<void> _reportChildSafetyConcern() async {
    final String subject =
        Uri.encodeComponent('URGENT: Child Safety Concern - GRACE PORTAL');
    final String body =
        Uri.encodeComponent('''Please describe your child safety concern below:

[Describe the concern here]

---
This report was sent from GRACE PORTAL App
Date: ${DateTime.now().toString().split('.')[0]}

IMPORTANT REMINDERS:
• If this is an emergency, please call 999 (UK) or 911 (US) immediately
• All reports are taken seriously and investigated
• You may report anonymously if preferred
• Contact NSPCC Helpline: 0808 800 5000 (UK)

For more information, view our Child Safety Standards:
https://aysamuel.github.io/agbc-app/child-safety-standards.html
''');

    final Uri emailUri =
        Uri.parse('mailto:oami.gospel@gmail.com?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          CustomToast.show(context,
              message: 'Could not open email app', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: 'Could not open email app', type: ToastType.error);
      }
    }
  }
}
