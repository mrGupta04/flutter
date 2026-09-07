import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/patient_user_model.dart';
import '../../../../data/repositories/patient_auth_repository.dart';
import '../../../select_location/add_address_screen.dart';
import '../../../select_location/selected_location.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';

/// Family members, saved addresses, allergies & medical history.
class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() =>
      _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(patientAuthProvider.notifier).refreshProfile();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  PatientAuthRepository get _repo => PatientAuthRepository();

  Future<void> _applyUser(PatientUserModel? user) async {
    if (user == null) return;
    ref.read(patientAuthProvider.notifier).setUser(user);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(patientAuthProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health profile'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Family'),
            Tab(text: 'Addresses'),
            Tab(text: 'Medical'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : TabBarView(
              controller: _tabs,
              children: [
                _FamilyTab(
                  user: user,
                  loading: _loading,
                  onAdd: () => _editFamily(null),
                  onEdit: _editFamily,
                  onDelete: _deleteFamily,
                ),
                _AddressesTab(
                  user: user,
                  loading: _loading,
                  onAdd: () => _editAddress(null),
                  onEdit: _editAddress,
                  onDelete: _deleteAddress,
                ),
                _MedicalTab(
                  user: user,
                  loading: _loading,
                  onSave: _saveMedical,
                ),
              ],
            ),
    );
  }

  Future<void> _editFamily(FamilyMemberModel? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl =
        TextEditingController(text: existing?.age?.toString() ?? '');
    final mobileCtrl =
        TextEditingController(text: existing?.mobileNumber ?? '');
    String relationship = existing?.relationship ?? 'child';
    String? gender = existing?.gender;
    String? bloodGroup = existing?.bloodGroup;
    bool emergency = existing?.isEmergencyContact ?? false;
    bool primary = existing?.isPrimary ?? false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Add family member' : 'Edit member',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  CaretOnTapTextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: relationship,
                    itemHeight: kMinInteractiveDimension,
                    menuMaxHeight: 280,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Relationship'),
                    items: const [
                      DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
                      DropdownMenuItem(
                          value: 'grandparent', child: Text('Grandparent')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) =>
                        setLocal(() => relationship = v ?? 'other'),
                  ),
                  const SizedBox(height: 8),
                  CaretOnTapTextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: gender,
                    itemHeight: kMinInteractiveDimension,
                    menuMaxHeight: 280,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setLocal(() => gender = v),
                  ),
                  const SizedBox(height: 8),
                  CaretOnTapTextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Mobile (optional)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: bloodGroup,
                    itemHeight: kMinInteractiveDimension,
                    menuMaxHeight: 280,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Blood group'),
                    items: const [
                      'A+',
                      'A-',
                      'B+',
                      'B-',
                      'AB+',
                      'AB-',
                      'O+',
                      'O-',
                    ]
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setLocal(() => bloodGroup = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Emergency contact'),
                    value: emergency,
                    onChanged: (v) => setLocal(() {
                      emergency = v;
                      if (!v) primary = false;
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary emergency contact'),
                    value: primary,
                    onChanged: (v) => setLocal(() {
                      primary = v;
                      if (v) emergency = true;
                    }),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Save',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (saved != true || !mounted) return;
    setState(() => _loading = true);
    final res = await _repo.saveFamilyMember(
      FamilyMemberModel(
        id: existing?.id ?? '',
        name: nameCtrl.text.trim(),
        relationship: relationship,
        age: int.tryParse(ageCtrl.text.trim()),
        gender: gender,
        mobileNumber: mobileCtrl.text.trim().isEmpty
            ? null
            : mobileCtrl.text.trim(),
        bloodGroup: bloodGroup,
        isEmergencyContact: emergency,
        isPrimary: primary,
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      await _applyUser(res.data);
      SnackBarHelper.showSuccess(context, 'Family member saved');
    } else {
      SnackBarHelper.showError(context, res.error ?? 'Could not save');
    }
  }

  Future<void> _deleteFamily(FamilyMemberModel member) async {
    setState(() => _loading = true);
    final res = await _repo.deleteFamilyMember(member.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      await _applyUser(res.data);
      SnackBarHelper.showSuccess(context, 'Removed');
    } else {
      SnackBarHelper.showError(context, res.error ?? 'Could not remove');
    }
  }

  Future<void> _editAddress(SavedAddressModel? existing) async {
    final result = await Navigator.of(context).push<SelectedLocationResult>(
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(existing: existing),
      ),
    );
    if (result != null && mounted) {
      await ref.read(patientAuthProvider.notifier).refreshProfile();
      SnackBarHelper.showSuccess(context, 'Address saved');
    }
  }

  Future<void> _deleteAddress(SavedAddressModel address) async {
    setState(() => _loading = true);
    final res = await _repo.deleteAddress(address.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      await _applyUser(res.data);
      SnackBarHelper.showSuccess(context, 'Removed');
    } else {
      SnackBarHelper.showError(context, res.error ?? 'Could not remove');
    }
  }

  Future<void> _saveMedical(MedicalProfileModel profile) async {
    setState(() => _loading = true);
    final res = await _repo.updateMedicalProfile(profile);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      await _applyUser(res.data);
      SnackBarHelper.showSuccess(context, 'Medical profile saved');
    } else {
      SnackBarHelper.showError(context, res.error ?? 'Could not save');
    }
  }
}

class _FamilyTab extends StatelessWidget {
  const _FamilyTab({
    required this.user,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final PatientUserModel user;
  final bool loading;
  final VoidCallback onAdd;
  final void Function(FamilyMemberModel) onEdit;
  final void Function(FamilyMemberModel) onDelete;

  @override
  Widget build(BuildContext context) {
    final members = user.familyMembers;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Book for family members without retyping details.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No family members yet')),
          ),
        ...members.map(
          (m) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(m.name.isNotEmpty ? m.name[0] : '?')),
              title: Text(m.name),
              subtitle: Text(
                [
                  m.relationship,
                  if (m.age != null) '${m.age} yrs',
                  if (m.bloodGroup != null) m.bloodGroup!,
                  if (m.isPrimary)
                    'Primary emergency'
                  else if (m.isEmergencyContact)
                    'Emergency',
                ].join(' · '),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: loading ? null : () => onEdit(m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: loading ? null : () => onDelete(m),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: 'Add family member',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: loading ? () {} : onAdd,
          isEnabled: !loading,
        ),
      ],
    );
  }
}

class _AddressesTab extends StatelessWidget {
  const _AddressesTab({
    required this.user,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final PatientUserModel user;
  final bool loading;
  final VoidCallback onAdd;
  final void Function(SavedAddressModel) onEdit;
  final void Function(SavedAddressModel) onDelete;

  @override
  Widget build(BuildContext context) {
    final addresses = user.savedAddresses;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Reuse addresses for home visits and sample collection.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (addresses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No saved addresses yet')),
          ),
        ...addresses.map(
          (a) => Card(
            child: ListTile(
              leading: Icon(
                a.isDefault ? Icons.home_rounded : Icons.place_outlined,
                color: AppColors.primary,
              ),
              title: Text('${a.label}${a.isDefault ? ' (Default)' : ''}'),
              subtitle: Text(a.displayLine),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: loading ? null : () => onEdit(a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: loading ? null : () => onDelete(a),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: 'Add address',
          icon: Icons.add_location_alt_outlined,
          onPressed: loading ? () {} : onAdd,
          isEnabled: !loading,
        ),
      ],
    );
  }
}

class _MedicalTab extends StatefulWidget {
  const _MedicalTab({
    required this.user,
    required this.loading,
    required this.onSave,
  });

  final PatientUserModel user;
  final bool loading;
  final Future<void> Function(MedicalProfileModel) onSave;

  @override
  State<_MedicalTab> createState() => _MedicalTabState();
}

class _MedicalTabState extends State<_MedicalTab> {
  late String? _bloodGroup;
  late final TextEditingController _allergies;
  late final TextEditingController _chronic;
  late final TextEditingController _meds;
  late final TextEditingController _notes;
  late final TextEditingController _insProvider;
  late final TextEditingController _insPolicy;
  late final TextEditingController _insMember;
  late final TextEditingController _insValid;

  @override
  void initState() {
    super.initState();
    final mp = widget.user.medicalProfile;
    _bloodGroup = mp.bloodGroup;
    _allergies = TextEditingController(text: mp.allergies.join(', '));
    _chronic = TextEditingController(text: mp.chronicDiseases.join(', '));
    _meds = TextEditingController(text: mp.currentMedications.join(', '));
    _notes = TextEditingController(text: mp.notes ?? '');
    _insProvider = TextEditingController(text: mp.insuranceProvider ?? '');
    _insPolicy = TextEditingController(text: mp.insurancePolicyNumber ?? '');
    _insMember = TextEditingController(text: mp.insuranceMemberId ?? '');
    _insValid = TextEditingController(text: mp.insuranceValidUntil ?? '');
  }

  @override
  void dispose() {
    _allergies.dispose();
    _chronic.dispose();
    _meds.dispose();
    _notes.dispose();
    _insProvider.dispose();
    _insPolicy.dispose();
    _insMember.dispose();
    _insValid.dispose();
    super.dispose();
  }

  List<String> _split(String raw) => raw
      .split(RegExp(r'[,;\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Shared with doctors and nurses when you book (allergies & conditions).',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push(AppConstants.routeNursingReports),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Nursing reports'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _bloodGroup,
          itemHeight: kMinInteractiveDimension,
          menuMaxHeight: 280,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Blood group'),
          items: const [
            'A+',
            'A-',
            'B+',
            'B-',
            'AB+',
            'AB-',
            'O+',
            'O-',
          ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _bloodGroup = v),
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _allergies,
          decoration: const InputDecoration(
            labelText: 'Allergies',
            hintText: 'Penicillin, peanuts… (comma separated)',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _chronic,
          decoration: const InputDecoration(
            labelText: 'Chronic conditions',
            hintText: 'Diabetes, hypertension…',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _meds,
          decoration: const InputDecoration(
            labelText: 'Current medications',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _notes,
          decoration: const InputDecoration(labelText: 'Notes for care team'),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Text(
          'Insurance',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        CaretOnTapTextField(
          controller: _insProvider,
          decoration: const InputDecoration(labelText: 'Insurance provider'),
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _insPolicy,
          decoration: const InputDecoration(labelText: 'Policy number'),
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _insMember,
          decoration: const InputDecoration(labelText: 'Member / ID number'),
        ),
        const SizedBox(height: 12),
        CaretOnTapTextField(
          controller: _insValid,
          decoration: const InputDecoration(
            labelText: 'Valid until (optional)',
            hintText: 'YYYY-MM-DD',
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: 'Save medical profile',
          icon: Icons.save_rounded,
          isLoading: widget.loading,
          onPressed: () => widget.onSave(
            MedicalProfileModel(
              bloodGroup: _bloodGroup,
              allergies: _split(_allergies.text),
              chronicDiseases: _split(_chronic.text),
              currentMedications: _split(_meds.text),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              insuranceProvider: _insProvider.text.trim().isEmpty
                  ? null
                  : _insProvider.text.trim(),
              insurancePolicyNumber: _insPolicy.text.trim().isEmpty
                  ? null
                  : _insPolicy.text.trim(),
              insuranceMemberId: _insMember.text.trim().isEmpty
                  ? null
                  : _insMember.text.trim(),
              insuranceValidUntil: _insValid.text.trim().isEmpty
                  ? null
                  : _insValid.text.trim(),
            ),
          ),
        ),
      ],
    );
  }
}
