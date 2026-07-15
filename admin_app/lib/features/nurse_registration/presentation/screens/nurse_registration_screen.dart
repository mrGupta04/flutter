import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/nurse_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/provider_type.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../provider/provider/provider_status_sync.dart';
import '../../provider/nurse_registration_provider.dart';
import '../widgets/nurse_registration_step_widgets.dart';

class NurseRegistrationScreen extends ConsumerStatefulWidget {
  const NurseRegistrationScreen({super.key});

  @override
  ConsumerState<NurseRegistrationScreen> createState() =>
      _NurseRegistrationScreenState();
}

class _NurseRegistrationScreenState
    extends ConsumerState<NurseRegistrationScreen> {
  late PageController _pageController;
  late List<GlobalKey<FormState>> _formKeys;

  static const _stepTitles = [
    ('Personal details', 'Name, DOB, languages & emergency contact'),
    ('Professional info', 'License, skills, NUID & home visit fee'),
    ('Base location', 'Address, map pin & service radius'),
    ('Upload documents', 'License, PAN, police verification & more'),
    ('Payout details', 'Bank account & cancelled cheque'),
    ('Weekly availability', 'Home visit slots (Sun–Sat, 8 AM–6 PM)'),
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
    final currentStep = ref.read(currentNurseStepProvider);
    if (!_validateStep(currentStep)) return;
    if (currentStep < totalNurseRegistrationSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      ref.read(currentNurseStepProvider.notifier).state = currentStep + 1;
    }
  }

  void _previousStep() {
    final currentStep = ref.read(currentNurseStepProvider);
    if (currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      ref.read(currentNurseStepProvider.notifier).state = currentStep - 1;
    }
  }

  void _goToStep(int step) {
    _pageController.jumpToPage(step - 1);
    ref.read(currentNurseStepProvider.notifier).state = step;
  }

  Future<void> _submit() async {
    if (!_validateStep(totalNurseRegistrationSteps)) return;
    final ok = await ref
        .read(nurseRegistrationFormProvider.notifier)
        .submitRegistration();
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await navigateAfterRegistration(context, ref, ProviderType.nurse);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(nurseRegistrationFormProvider).submitError ??
            'Registration failed',
      );
    }
  }

  bool _validateFormStep(
    int formKeyIndex, {
    required String invalidMessage,
  }) {
    final isValid = _formKeys[formKeyIndex].currentState?.validate() ?? false;
    if (!isValid) {
      SnackBarHelper.showError(context, invalidMessage);
    }
    return isValid;
  }

  bool _validateStep(int step) {
    final form = ref.read(nurseRegistrationFormProvider);

    if (step == 1) {
      if (!_validateFormStep(
        0,
        invalidMessage:
            'Please complete all required fields including mobile number, email, and password.',
      )) {
        return false;
      }
      if (!form.hasProfileImage) {
        SnackBarHelper.showError(context, 'Please upload a profile picture.');
        return false;
      }
      if (form.dateOfBirth == null) {
        SnackBarHelper.showError(context, 'Please select your date of birth.');
        return false;
      }
      if (form.languagesSpoken.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Select at least one language you speak.',
        );
        return false;
      }
    }

    if (step == 2) {
      if (!_validateFormStep(
        1,
        invalidMessage: 'Please complete all professional details.',
      )) {
        return false;
      }
      if (form.nursingSkills.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Select at least one clinical skill or service.',
        );
        return false;
      }
      if (form.qualification == 'Other' &&
          form.qualificationOther.trim().isEmpty) {
        SnackBarHelper.showError(context, 'Please specify your qualification.');
        return false;
      }
    }

    if (step == 3) {
      if (!_validateFormStep(
        2,
        invalidMessage: 'Please complete your base location details.',
      )) {
        return false;
      }
      if (form.latitude == null || form.longitude == null) {
        SnackBarHelper.showError(
          context,
          'Please select your location on the map.',
        );
        return false;
      }
      if (form.serviceRadiusKm == null) {
        SnackBarHelper.showError(
          context,
          'Please select your home visit service radius.',
        );
        return false;
      }
    }

    if (step == 4) {
      for (final doc in requiredNurseDocuments) {
        if (!form.documentUrls.containsKey(doc) &&
            !form.documentBytes.containsKey(doc)) {
          SnackBarHelper.showError(context, 'Please upload: ${doc.label}');
          return false;
        }
      }
    }

    if (step == 5) {
      if (!_validateFormStep(
        3,
        invalidMessage: 'Please complete all payout bank details.',
      )) {
        return false;
      }
      final cheque = NurseDocumentType.cancelledCheque;
      if (!form.documentUrls.containsKey(cheque) &&
          !form.documentBytes.containsKey(cheque)) {
        SnackBarHelper.showError(
          context,
          'Please upload a cancelled cheque photo.',
        );
        return false;
      }
    }

    if (step == 6) {
      if (form.selectedHomeAvailabilitySlots.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Select at least one home visit time slot.',
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
      total: totalNurseRegistrationSteps,
      title: meta.$1,
      subtitle: meta.$2,
      footer: footer,
      child: child,
    );
  }

  Widget? _stepFooter(int step) {
    if (step >= totalNurseRegistrationSteps) return null;
    return RegistrationStepActions(
      showBack: step > 1,
      onBack: _previousStep,
      onContinue: _nextStep,
      continueLabel:
          step == totalNurseRegistrationSteps - 1 ? 'Review' : 'Continue',
      continueIcon: Icons.arrow_forward_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentNurseStepProvider);
    final isSubmitting = ref.watch(
      nurseRegistrationFormProvider.select((s) => s.isSubmitting),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nurse onboarding'),
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
            child: NurseStep1Personal(formKey: _formKeys[0]),
          ),
          _stepPage(
            2,
            footer: _stepFooter(2),
            child: NurseStep2Professional(formKey: _formKeys[1]),
          ),
          _stepPage(
            3,
            footer: _stepFooter(3),
            child: NurseStep3Location(formKey: _formKeys[2]),
          ),
          _stepPage(
            4,
            footer: _stepFooter(4),
            child: const NurseStep4Documents(),
          ),
          _stepPage(
            5,
            footer: _stepFooter(5),
            child: NurseStep5Bank(formKey: _formKeys[3]),
          ),
          _stepPage(
            6,
            footer: _stepFooter(6),
            child: const NurseStep6Availability(),
          ),
          _stepPage(
            7,
            footer: RegistrationStepActions(
              showBack: true,
              onBack: _previousStep,
              onContinue: _submit,
              continueLabel: 'Submit for verification',
              isLoading: isSubmitting,
            ),
            child: NurseStep7Review(onEditStep: _goToStep),
          ),
        ],
      ),
    );
  }
}
