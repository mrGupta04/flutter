import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/ambulance_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/provider_type.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../provider/provider/provider_status_sync.dart';
import '../../provider/ambulance_registration_provider.dart';
import '../widgets/ambulance_registration_step_widgets.dart';

class AmbulanceRegistrationScreen extends ConsumerStatefulWidget {
  const AmbulanceRegistrationScreen({super.key});

  @override
  ConsumerState<AmbulanceRegistrationScreen> createState() =>
      _AmbulanceRegistrationScreenState();
}

class _AmbulanceRegistrationScreenState
    extends ConsumerState<AmbulanceRegistrationScreen> {
  late PageController _pageController;
  late List<GlobalKey<FormState>> _formKeys;

  static const _stepTitles = [
    ('Service & owner', 'Company info, licenses & login'),
    ('Vehicle fleet', 'Register each ambulance individually'),
    ('Drivers & EMTs', 'License, certification & assignment'),
    ('Documents', 'Service, vehicle & driver uploads'),
    ('Location', 'Base address & coverage area'),
    ('Bank details', 'Payout account & cancelled cheque'),
    ('Review & submit', 'Confirm before admin verification'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final currentStep = ref.read(currentAmbulanceStepProvider);
    if (!_validateStep(currentStep)) return;
    if (currentStep < totalAmbulanceRegistrationSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      ref.read(currentAmbulanceStepProvider.notifier).state = currentStep + 1;
    }
  }

  void _previousStep() {
    final currentStep = ref.read(currentAmbulanceStepProvider);
    if (currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      ref.read(currentAmbulanceStepProvider.notifier).state = currentStep - 1;
    }
  }

  void _goToStep(int step) {
    _pageController.jumpToPage(step - 1);
    ref.read(currentAmbulanceStepProvider.notifier).state = step;
  }

  Future<void> _submit() async {
    if (!_validateStep(totalAmbulanceRegistrationSteps)) return;
    final ok = await ref
        .read(ambulanceRegistrationFormProvider.notifier)
        .submitRegistration();
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await navigateAfterRegistration(context, ref, ProviderType.ambulance);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(ambulanceRegistrationFormProvider).submitError ??
            'Registration failed',
      );
    }
  }

  bool _validateStep(int step) {
    final form = ref.read(ambulanceRegistrationFormProvider);

    if (step == 1) {
      if (!(_formKeys[0].currentState?.validate() ?? false)) {
        SnackBarHelper.showError(
          context,
          'Please complete all required fields including mobile number, email, and password.',
        );
        return false;
      }
      if (!form.hasProfileImage) {
        SnackBarHelper.showError(context, 'Please upload a profile picture.');
        return false;
      }
    }

    if (step == 2) {
      if (form.vehicles.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Add at least one vehicle to your fleet.',
        );
        return false;
      }
    }

    if (step == 3) {
      if (form.drivers.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Add at least one driver or EMT.',
        );
        return false;
      }
    }

    if (step == 4) {
      const requiredServiceDocs = [
        AmbulanceServiceDocumentType.serviceLicense,
        AmbulanceServiceDocumentType.companyRegistration,
        AmbulanceServiceDocumentType.gstCertificate,
        AmbulanceServiceDocumentType.fleetInsurance,
      ];
      for (final doc in requiredServiceDocs) {
        if (!form.serviceDocumentUrls.containsKey(doc)) {
          SnackBarHelper.showError(
            context,
            'Please upload: ${doc.label}',
          );
          return false;
        }
      }
      const requiredVehicleDocs = [
        AmbulanceVehicleDocumentType.rcBook,
        AmbulanceVehicleDocumentType.insurance,
        AmbulanceVehicleDocumentType.fitnessCertificate,
        AmbulanceVehicleDocumentType.photoFront,
      ];
      for (final vehicle in form.vehicles) {
        final docs = form.vehicleDocumentUrls[vehicle.id] ?? {};
        for (final doc in requiredVehicleDocs) {
          if (!docs.containsKey(doc)) {
            SnackBarHelper.showError(
              context,
              'Upload ${doc.label} for ${vehicle.displayLabel}',
            );
            return false;
          }
        }
      }
      const requiredDriverDocs = [
        AmbulanceDriverDocumentType.governmentId,
        AmbulanceDriverDocumentType.drivingLicense,
        AmbulanceDriverDocumentType.photo,
      ];
      for (final driver in form.drivers) {
        final docs = form.driverDocumentUrls[driver.id] ?? {};
        for (final doc in requiredDriverDocs) {
          if (!docs.containsKey(doc)) {
            SnackBarHelper.showError(
              context,
              'Upload ${doc.label} for ${driver.fullName}',
            );
            return false;
          }
        }
      }
    }

    if (step == 5) {
      if (!(_formKeys[1].currentState?.validate() ?? false)) return false;
      if (form.latitude == null || form.longitude == null) {
        SnackBarHelper.showError(
          context,
          'Please select your base location on the map.',
        );
        return false;
      }
    }

    if (step == 6) {
      if (!(_formKeys[2].currentState?.validate() ?? false)) return false;
      if (!form.serviceDocumentUrls
          .containsKey(AmbulanceServiceDocumentType.cancelledCheque)) {
        SnackBarHelper.showError(
          context,
          'Please upload a cancelled cheque photo.',
        );
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentAmbulanceStepProvider);
    final stepMeta = _stepTitles[currentStep - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ambulance onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: currentStep > 1 ? _previousStep : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          FormStepHeader(
            step: currentStep,
            total: totalAmbulanceRegistrationSteps,
            title: stepMeta.$1,
            subtitle: stepMeta.$2,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AmbulanceStep1ServiceOwner(formKey: _formKeys[0]),
                const AmbulanceStep2VehicleFleet(),
                const AmbulanceStep3Drivers(),
                const AmbulanceStep4Documents(),
                AmbulanceStep5Location(formKey: _formKeys[1]),
                AmbulanceStep6BankDetails(formKey: _formKeys[2]),
                AmbulanceStep7Review(
                  onSubmit: _submit,
                  onEdit: _goToStep,
                ),
              ],
            ),
          ),
          if (currentStep < totalAmbulanceRegistrationSteps)
            BottomCtaBar(
              child: Row(
                children: [
                  if (currentStep > 1) ...[
                    Expanded(
                      child: CustomOutlineButton(
                        label: 'Back',
                        onPressed: _previousStep,
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: currentStep > 1 ? 2 : 1,
                    child: CustomButton(
                      label: currentStep == totalAmbulanceRegistrationSteps - 1
                          ? 'Review'
                          : 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextStep,
                      height: 50,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
