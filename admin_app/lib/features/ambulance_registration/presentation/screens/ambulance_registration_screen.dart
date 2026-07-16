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
          'Please pin your base location on the map, or locate your typed address.',
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

  Widget _stepPage(int step, {required Widget child, Widget? footer}) {
    final meta = _stepTitles[step - 1];
    return RegistrationStepPage(
      step: step,
      total: totalAmbulanceRegistrationSteps,
      title: meta.$1,
      subtitle: meta.$2,
      footer: footer,
      child: child,
    );
  }

  Widget? _stepFooter(int step) {
    if (step >= totalAmbulanceRegistrationSteps) return null;
    return RegistrationStepActions(
      showBack: step > 1,
      onBack: _previousStep,
      onContinue: _nextStep,
      continueLabel: step == totalAmbulanceRegistrationSteps - 1
          ? 'Review'
          : 'Continue',
      continueIcon: Icons.arrow_forward_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentAmbulanceStepProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ambulance onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: currentStep > 1 ? _previousStep : () => context.pop(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _stepPage(
            1,
            footer: _stepFooter(1),
            child: AmbulanceStep1ServiceOwner(formKey: _formKeys[0]),
          ),
          _stepPage(
            2,
            footer: _stepFooter(2),
            child: const AmbulanceStep2VehicleFleet(),
          ),
          _stepPage(
            3,
            footer: _stepFooter(3),
            child: const AmbulanceStep3Drivers(),
          ),
          _stepPage(
            4,
            footer: _stepFooter(4),
            child: const AmbulanceStep4Documents(),
          ),
          _stepPage(
            5,
            footer: _stepFooter(5),
            child: AmbulanceStep5Location(formKey: _formKeys[1]),
          ),
          _stepPage(
            6,
            footer: _stepFooter(6),
            child: AmbulanceStep6BankDetails(formKey: _formKeys[2]),
          ),
          _stepPage(
            7,
            child: AmbulanceStep7Review(
              onSubmit: _submit,
              onEdit: _goToStep,
            ),
          ),
        ],
      ),
    );
  }
}
