import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/nurse_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
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
    ('Personal details', 'Name, contact & profile photo'),
    ('Professional info', 'License, specialty & home visit fee'),
    ('Base location', 'Address & map pin'),
    ('Upload documents', 'License, ID & certificates'),
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
      context.go(AppConstants.routeNurseApplicationSubmitted);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(nurseRegistrationFormProvider).submitError ??
            'Registration failed',
      );
    }
  }

  bool _validateStep(int step) {
    final form = ref.read(nurseRegistrationFormProvider);

    if (step == 1) {
      if (!(_formKeys[0].currentState?.validate() ?? false)) return false;
      if (!form.hasProfileImage) {
        SnackBarHelper.showError(context, 'Please upload a profile picture.');
        return false;
      }
    }

    if (step == 2) {
      if (!(_formKeys[1].currentState?.validate() ?? false)) return false;
    }

    if (step == 3) {
      if (!(_formKeys[2].currentState?.validate() ?? false)) return false;
      if (form.latitude == null || form.longitude == null) {
        SnackBarHelper.showError(
          context,
          'Please select your location on the map.',
        );
        return false;
      }
    }

    if (step == 4) {
      final required = [
        NurseDocumentType.nursingLicense,
        NurseDocumentType.degreeCertificate,
        NurseDocumentType.aadhaarCard,
      ];
      for (final doc in required) {
        if (!form.documentUrls.containsKey(doc) &&
            !form.documentBytes.containsKey(doc)) {
          SnackBarHelper.showError(context, 'Please upload: ${doc.label}');
          return false;
        }
      }
    }

    if (step == 5) {
      if (!(_formKeys[3].currentState?.validate() ?? false)) return false;
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

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentNurseStepProvider);
    final form = ref.watch(nurseRegistrationFormProvider);
    final stepMeta = _stepTitles[currentStep - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nurse onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: currentStep > 1 ? _previousStep : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          FormStepHeader(
            step: currentStep,
            total: totalNurseRegistrationSteps,
            title: stepMeta.$1,
            subtitle: stepMeta.$2,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                NurseStep1Personal(formKey: _formKeys[0]),
                NurseStep2Professional(formKey: _formKeys[1]),
                NurseStep3Location(formKey: _formKeys[2]),
                const NurseStep4Documents(),
                NurseStep5Bank(formKey: _formKeys[3]),
                const NurseStep6Availability(),
                NurseStep7Review(onEditStep: _goToStep),
              ],
            ),
          ),
          if (currentStep < totalNurseRegistrationSteps)
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
                      label: currentStep == totalNurseRegistrationSteps - 1
                          ? 'Review'
                          : 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextStep,
                      height: 50,
                    ),
                  ),
                ],
              ),
            )
          else
            BottomCtaBar(
              child: Row(
                children: [
                  Expanded(
                    child: CustomOutlineButton(
                      label: 'Back',
                      onPressed: _previousStep,
                      height: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      label: 'Submit for verification',
                      isLoading: form.isSubmitting,
                      onPressed: _submit,
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
