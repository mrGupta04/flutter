import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';
import 'admin_ambulance_list_screen.dart';
import 'admin_blood_bank_list_screen.dart';
import 'admin_diagnostic_sessions_screen.dart';
import 'admin_doctor_sessions_screen.dart';

enum _ProviderTab {
  onlineDoctors,
  homeVisitDoctors,
  hospitalVisitDoctors,
  nurses,
  ambulance,
  bloodBanks,
  labs,
  scans,
}

class _ProviderOption {
  const _ProviderOption({
    required this.tab,
    required this.icon,
    required this.label,
  });

  final _ProviderTab tab;
  final IconData icon;
  final String label;
}

/// Hub for managing all service-provider application queues.
class AdminServiceProviderManagementScreen extends StatefulWidget {
  const AdminServiceProviderManagementScreen({super.key});

  @override
  State<AdminServiceProviderManagementScreen> createState() =>
      _AdminServiceProviderManagementScreenState();
}

class _AdminServiceProviderManagementScreenState
    extends State<AdminServiceProviderManagementScreen> {
  _ProviderTab _selected = _ProviderTab.onlineDoctors;

  static const _options = <_ProviderOption>[
    _ProviderOption(
      tab: _ProviderTab.onlineDoctors,
      icon: Icons.videocam_rounded,
      label: 'Online doctors',
    ),
    _ProviderOption(
      tab: _ProviderTab.homeVisitDoctors,
      icon: Icons.home_rounded,
      label: 'Home visit doctors',
    ),
    _ProviderOption(
      tab: _ProviderTab.hospitalVisitDoctors,
      icon: Icons.local_hospital_rounded,
      label: 'Hospital visit doctors',
    ),
    _ProviderOption(
      tab: _ProviderTab.nurses,
      icon: Icons.health_and_safety_rounded,
      label: 'Nurses',
    ),
    _ProviderOption(
      tab: _ProviderTab.ambulance,
      icon: Icons.local_shipping_rounded,
      label: 'Ambulance',
    ),
    _ProviderOption(
      tab: _ProviderTab.bloodBanks,
      icon: Icons.bloodtype_rounded,
      label: 'Blood banks',
    ),
    _ProviderOption(
      tab: _ProviderTab.labs,
      icon: Icons.biotech_rounded,
      label: 'Labs',
    ),
    _ProviderOption(
      tab: _ProviderTab.scans,
      icon: Icons.radar_rounded,
      label: 'Scan / MRI',
    ),
  ];

  Widget _buildHubHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Review, verify, and manage provider applications across every category.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var i = 0; i < _options.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _ProviderButton(
                  icon: _options[i].icon,
                  label: _options[i].label,
                  selected: _selected == _options[i].tab,
                  onTap: () => setState(() => _selected = _options[i].tab),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContent() {
    final header = _buildHubHeader();
    switch (_selected) {
      case _ProviderTab.onlineDoctors:
        return AdminDoctorSessionsScreen(
          key: const ValueKey('online'),
          serviceType: 'online',
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.homeVisitDoctors:
        return AdminDoctorSessionsScreen(
          key: const ValueKey('home_visit'),
          serviceType: 'home_visit',
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.hospitalVisitDoctors:
        return AdminDoctorSessionsScreen(
          key: const ValueKey('hospital_visit'),
          serviceType: 'hospital_visit',
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.nurses:
        return AdminDoctorSessionsScreen(
          key: const ValueKey('nurse'),
          serviceType: 'home_visit',
          providerType: 'nurse',
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.ambulance:
        return AdminAmbulanceListScreen(
          key: const ValueKey('ambulance'),
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.bloodBanks:
        return AdminBloodBankListScreen(
          key: const ValueKey('blood_banks'),
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.labs:
        return AdminDiagnosticSessionsScreen(
          key: const ValueKey('lab'),
          kind: 'lab',
          embedded: true,
          scrollHeader: header,
        );
      case _ProviderTab.scans:
        return AdminDiagnosticSessionsScreen(
          key: const ValueKey('scan'),
          kind: 'scan',
          embedded: true,
          scrollHeader: header,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAdaptiveShell(
      section: AdminNavSection.providers,
      constrainBody: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Service provider management')),
      body: ResponsivePage(child: _buildContent()),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.white : AppColors.primary,
      ),
      label: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: selected ? AppColors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : AppColors.white,
        foregroundColor: selected ? AppColors.white : AppColors.textPrimary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
