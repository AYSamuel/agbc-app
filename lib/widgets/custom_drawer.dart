import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../config/theme.dart';

class DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  const DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });
}

class CustomDrawer extends StatelessWidget {
  final String title;
  final List<DrawerItem> items;
  final VoidCallback? onClose;

  const CustomDrawer({
    super.key,
    required this.title,
    required this.items,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onClose?.call();
                    },
                    icon: const Icon(Remix.close_line),
                    color: AppTheme.textMuted(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...items.map((item) => _buildDrawerItem(context, item)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, DrawerItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  color: AppTheme.accent(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                item.label,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (item.showChevron)
                Icon(
                  Remix.arrow_right_s_line,
                  color: AppTheme.textMuted(context),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
