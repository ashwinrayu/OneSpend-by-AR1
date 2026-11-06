import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_colors.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
  });
}

class UpdateService {
  static const String updateApiUrl = 'https://onespend-by-ar1.onrender.com/api/app/version';

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final res = await http.get(Uri.parse(updateApiUrl)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final latestVersion = data['latestVersion'] as String? ?? currentVersion;
      final latestBuild = (data['buildNumber'] as num?)?.toInt() ?? currentBuild;
      final releaseNotes = data['releaseNotes'] as String? ?? 'Bug fixes and performance improvements.';
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final isMandatory = (data['isMandatory'] as bool?) ?? false;

      final hasUpdate = latestBuild > currentBuild;

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        isMandatory: isMandatory,
      );
    } catch (e) {
      debugPrint('Check for update notice: $e');
      return null;
    }
  }

  Future<File?> downloadApk(String url, void Function(double progress) onProgress) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) return null;

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/onespend_latest_update.apk');
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      return file;
    } catch (e) {
      debugPrint('APK download error: $e');
      return null;
    }
  }

  Future<bool> installApk(File file) async {
    try {
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Install launch error: $e');
      return false;
    }
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

// Update Dialog Widget
class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    final service = UpdateService();
    final file = await service.downloadApk(
      widget.updateInfo.downloadUrl,
      (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
    );

    if (file != null && mounted) {
      final success = await service.installApk(file);
      if (!success && mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Could not launch package installer. Please verify APK install permissions.';
        });
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Download failed. Please check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161922),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF262C3A), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.income, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cloud Update Ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Version ${widget.updateInfo.latestVersion} (Build ${widget.updateInfo.latestBuildNumber})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "What's New in this Build:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1115),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF232733)),
              ),
              child: Text(
                widget.updateInfo.releaseNotes,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isDownloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Downloading update...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.income, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: const Color(0xFF232733),
                  color: AppColors.income,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.updateInfo.isMandatory && !_isDownloading)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Later', style: TextStyle(color: Colors.white54)),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: const Color(0xFF0F1115),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F1115)),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    _isDownloading ? 'Installing...' : 'Update Now',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
