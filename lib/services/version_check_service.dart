import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if the app needs an update and shows a dialog if necessary.
  /// Returns true if the app can proceed, false if a forced update is blocking usage.
  Future<bool> checkVersion(BuildContext context) async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;
      final fullCurrentVersion = currentBuildNumber.isNotEmpty
          ? '$currentVersion+$currentBuildNumber'
          : currentVersion;

      final platform = Platform.isAndroid ? 'android' : 'ios';

      // 2. Get remote version config
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .maybeSingle();

      if (response == null) {
        // No config found for this platform, assume safe to proceed
        return true;
      }

      final minVersion = response['min_version'] as String;
      final latestVersion = response['latest_version'] as String;
      final storeUrl = response['store_url'] as String;
      final forceUpdate = response['force_update'] as bool? ?? false;

      // 3. Compare versions
      final needsForceUpdate = forceUpdate ||
          _isVersionLower(currentVersion, currentBuildNumber, minVersion);
      final needsOptionalUpdate =
          _isVersionLower(currentVersion, currentBuildNumber, latestVersion);

      if (needsForceUpdate) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            isForce: true,
            storeUrl: storeUrl,
            currentVersion: fullCurrentVersion,
            targetVersion: minVersion,
          );
        }
        return false; // Blocking
      } else if (needsOptionalUpdate) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            isForce: false,
            storeUrl: storeUrl,
            currentVersion: fullCurrentVersion,
            targetVersion: latestVersion,
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Version check failed: $e');
      // On error, we usually let the user proceed rather than blocking them
      return true;
    }
  }

  /// Returns true if [currentVersion] + [currentBuild] is lower than [targetString]
  /// [targetString] can be "1.0.0" or "1.0.0+6"
  bool _isVersionLower(
      String currentVersion, String currentBuild, String targetString) {
    try {
      // Split target into version and build (if exists)
      final targetParts = targetString.split('+');
      final targetVer = targetParts[0];
      final targetBuild = targetParts.length > 1 ? targetParts[1] : null;

      // 1. Compare Version Numbers (e.g. 1.0.0 vs 1.0.1)
      final verComparison = _compareVersionNumbers(currentVersion, targetVer);
      if (verComparison < 0) return true; // Current is smaller
      if (verComparison > 0) return false; // Current is larger

      // 2. If Versions are equal, compare Build Numbers (if target has one)
      if (targetBuild != null && currentBuild.isNotEmpty) {
        final buildComparison = _compareBuildNumbers(currentBuild, targetBuild);
        if (buildComparison < 0) return true; // Current build is smaller
      }

      return false; // Equal or higher
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return false; // Fallback
    }
  }

  /// Returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersionNumbers(String v1, String v2) {
    try {
      List<int> v1Parts = v1.split('.').map(int.parse).toList();
      List<int> v2Parts = v2.split('.').map(int.parse).toList();

      // Pad with zeros
      while (v1Parts.length < 3) {
        v1Parts.add(0);
      }
      while (v2Parts.length < 3) {
        v2Parts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] < v2Parts[i]) return -1;
        if (v1Parts[i] > v2Parts[i]) return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Returns -1 if b1 < b2, 0 if equal, 1 if b1 > b2
  int _compareBuildNumbers(String b1, String b2) {
    try {
      final intBuild1 = int.tryParse(b1) ?? 0;
      final intBuild2 = int.tryParse(b2) ?? 0;
      if (intBuild1 < intBuild2) return -1;
      if (intBuild1 > intBuild2) return 1;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _showUpdateDialog(
    BuildContext context, {
    required bool isForce,
    required String storeUrl,
    required String currentVersion,
    required String targetVersion,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (context) => PopScope(
        canPop: !isForce,
        child: AlertDialog(
          title: Text(isForce ? 'Update Required' : 'Update Available'),
          content: Text(
            isForce
                ? 'You are using an older version ($currentVersion). Please update to version $targetVersion or later to continue using the app.'
                : 'A new version ($targetVersion) is available. Would you like to update?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(storeUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}
