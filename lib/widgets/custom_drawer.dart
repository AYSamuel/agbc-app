import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../utils/theme.dart';

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
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onClose?.call();
                    },
                    icon: const Icon(Remix.close_line),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...items.map((item) => _buildDrawerItem(item)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(DrawerItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (item.showChevron)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
