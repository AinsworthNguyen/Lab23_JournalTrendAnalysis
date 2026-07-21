import 'package:flutter/material.dart';
import '../../../../core/firebase/firebase_remote_config_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';

const Color _adminAccent = Color(0xFF38BDF8); // Electric Cyan (Xanh Cyan hiện đại)

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  late IFirebaseRemoteConfigService _remoteConfig;
  bool _isSaving = false;

  // Current config values displayed in sliders/inputs
  double _maxJournalsLimit = 10;
  double _maxKeywordsLimit = 20;

  static const double _minJournals = 5;
  static const double _maxJournals = 100;
  static const double _minKeywords = 5;
  static const double _maxKeywords = 100;

  @override
  void initState() {
    super.initState();
    _remoteConfig = getIt<IFirebaseRemoteConfigService>();
    _loadCurrentValues();
  }

  void _loadCurrentValues() {
    try {
      // Read from Remote Config (getInt returns default if key not set)
      _maxJournalsLimit = _remoteConfig.getInt('max_journals_limit').toDouble().clamp(_minJournals, _maxJournals);
      _maxKeywordsLimit = _remoteConfig.getInt('max_keywords_limit').toDouble().clamp(_minKeywords, _maxKeywords);
    } catch (_) {
      // Use defaults if Remote Config not loaded
      _maxJournalsLimit = 10;
      _maxKeywordsLimit = 20;
    }
    setState(() {});
  }

  Future<void> _applyChanges() async {
    setState(() => _isSaving = true);
    try {
      await _remoteConfig.setInt('max_journals_limit', _maxJournalsLimit.toInt());
      await _remoteConfig.setInt('max_keywords_limit', _maxKeywordsLimit.toInt());
      await _remoteConfig.fetchAndActivate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration applied successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.highlight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text('System Configuration', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Manage Remote Config parameters for the application',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Note card
          _buildInfoCard(context),
          const SizedBox(height: 24),

          // Config section: Display Limits
          _buildSectionHeader(context, 'Display Limits'),
          const SizedBox(height: 16),

          _buildSliderConfig(
            context,
            key: 'max_journals_limit',
            label: 'Maximum Displayed Journals',
            description: 'Limit on the number of top journals on Home',
            value: _maxJournalsLimit,
            min: _minJournals,
            max: _maxJournals,
            onChanged: (v) => setState(() => _maxJournalsLimit = v),
          ),
          const SizedBox(height: 20),

          _buildSliderConfig(
            context,
            key: 'max_keywords_limit',
            label: 'Maximum Displayed Keywords',
            description: 'Limit on trending research topics shown to users',
            value: _maxKeywordsLimit,
            min: _minKeywords,
            max: _maxKeywords,
            onChanged: (v) => setState(() => _maxKeywordsLimit = v),
          ),
          const SizedBox(height: 32),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _applyChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(_isSaving ? 'Applying...' : 'Apply Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _adminAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Reset hint
          Center(
            child: Text(
              'Changes will take effect within 5 minutes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Info Card ────────────────────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _adminAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _adminAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _adminAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Remote Config',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _adminAccent),
                ),
                const SizedBox(height: 6),
                Text(
                  'These settings are deployed via Firebase Remote Config. '
                  'Users will fetch updated parameters on their next launch '
                  'or within 5 minutes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _adminAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }

  // ─── Slider Config ────────────────────────────────────────────────────────

  Widget _buildSliderConfig(
    BuildContext context, {
    required String key,
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _adminAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _adminAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: _adminAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _adminAccent,
              inactiveTrackColor: AppColors.border,
              thumbColor: _adminAccent,
              overlayColor: _adminAccent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toInt().toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              Text(max.toInt().toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
