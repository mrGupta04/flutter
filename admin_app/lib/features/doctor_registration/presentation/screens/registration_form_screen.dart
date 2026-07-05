import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../provider/registration_provider.dart';
import '../widgets/registration_step_widgets.dart';

class RegistrationFormScreen extends ConsumerStatefulWidget {
  const RegistrationFormScreen({super.key});

  @override
  ConsumerState<RegistrationFormScreen> createState() =>
      _RegistrationFormScreenState();
}

class _RegistrationFormScreenState
    extends ConsumerState<RegistrationFormScreen> {
  late PageController _pageController;
  late List<GlobalKey<FormState>> _formKeys;

  static const _stepTitles = [
    ('Personal details', 'Name, contact & profile photo'),
    ('Professional info', 'Registration, specialty & experience'),
    ('Clinic address', 'Location & hospital photos'),
    ('Upload documents', 'License, ID & certificates'),
    ('Payout details', 'Bank account & UPI for consultation fees'),
    ('Weekly availability', 'Online & clinic visit slots (Sun–Sat, 8 AM–6 PM)'),
    ('Review & submit', 'Confirm before we verify'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _formKeys = List.generate(
      AppConstants.totalRegistrationSteps,
      (_) => GlobalKey<FormState>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final currentStep = ref.read(currentRegistrationStepProvider);
    if (!_validateCurrentStep(currentStep)) return;
    if (_pageController.page! < AppConstants.totalRegistrationSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      ref.read(currentRegistrationStepProvider.notifier).state =
          currentStep + 1;
    }
  }

  void _previousStep() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      ref.read(currentRegistrationStepProvider.notifier).state--;
    }
  }

  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep(AppConstants.totalRegistrationSteps)) return;
    final success =
        await ref.read(registrationFormProvider.notifier).submitRegistration();

    if (success && mounted) {
      await ref.read(providerAuthProvider.notifier).refreshSession();
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.push(AppConstants.routeApplicationSubmitted);
      }
    }
  }

  bool _validateCurrentStep(int step) {
    if ((step >= 1 && step <= 3) || step == 5) {
      final formKeyIndex = step == 5 ? 4 : step - 1;
      final formKey = _formKeys[formKeyIndex];
      if (!(formKey.currentState?.validate() ?? false)) {
        if (step == 1) {
          SnackBarHelper.showError(
            context,
            'Please complete all required fields including mobile number, email, and password.',
          );
        } else if (step == 2) {
          SnackBarHelper.showError(
            context,
            'Please complete all professional details.',
          );
        } else if (step == 3) {
          SnackBarHelper.showError(
            context,
            'Please complete your clinic address details.',
          );
        } else if (step == 5) {
          SnackBarHelper.showError(
            context,
            'Please complete all payout bank details.',
          );
        }
        return false;
      }
    }

    final formState = ref.read(registrationFormProvider);

    if (step == 1) {
      if (!AppConstants.skipVerification && !formState.emailVerified) {
        SnackBarHelper.showError(
          context,
          'Please verify your email address before continuing.',
        );
        return false;
      }
      if (!formState.hasProfileImage) {
        SnackBarHelper.showError(context, 'Profile picture is required.');
        return false;
      }
    }

    if (step == 2) {
      if (formState.specializations.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Please select at least one specialization.',
        );
        return false;
      }
      if (formState.languagesSpoken.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Please select at least one language.',
        );
        return false;
      }
      if (!formState.hasConsultationOptionSelected) {
        SnackBarHelper.showError(
          context,
          'Select at least one consultation option (Online, Home, or Visit).',
        );
        return false;
      }
      if (formState.offersOnlineConsult &&
          ValidationUtils.validateConsultationFee(
                formState.onlineConsultFee,
              ) !=
              null) {
        SnackBarHelper.showError(
          context,
          'Enter a valid fee for online consultation.',
        );
        return false;
      }
      if (formState.offersVisitSite &&
          ValidationUtils.validateConsultationFee(formState.visitSiteFee) !=
              null) {
        SnackBarHelper.showError(
          context,
          'Enter a valid fee for hospital visit.',
        );
        return false;
      }
      if (formState.offersBookHome &&
          ValidationUtils.validateConsultationFee(formState.homeVisitFee) !=
              null) {
        SnackBarHelper.showError(
          context,
          'Enter a valid fee for home visit.',
        );
        return false;
      }
    }

    if (step == 3) {
      if (formState.latitude == null || formState.longitude == null) {
        SnackBarHelper.showError(
          context,
          'Please select the clinic location on the map.',
        );
        return false;
      }
      final missingHospitalPhotos = !formState.allHospitalPhotosUploaded;
      if (missingHospitalPhotos) {
        SnackBarHelper.showError(
          context,
          'Please upload all $doctorHospitalPhotoCount hospital photos.',
        );
        return false;
      }
    }

    if (step == 4) {
      const requiredDocs = [
        DocumentType.medicalLicense,
        DocumentType.aadhaarCard,
        DocumentType.degreeCertificate,
        DocumentType.clinicProof,
      ];
      final missing = requiredDocs.any(
        (doc) => !formState.uploadedDocuments.containsKey(doc),
      );
      if (missing) {
        SnackBarHelper.showError(
          context,
          'Please upload all required documents.',
        );
        return false;
      }
    }

    if (step == 5) {
      if (!formState.uploadedDocuments
          .containsKey(DocumentType.cancelledCheque)) {
        SnackBarHelper.showError(
          context,
          'Please upload a photo of your cancelled cheque.',
        );
        return false;
      }
    }

    if (step == 6) {
      if (formState.offersOnlineConsult &&
          formState.selectedOnlineAvailabilitySlots.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Select at least one online consult slot for this week.',
        );
        return false;
      }
      if (formState.offersVisitSite &&
          formState.selectedClinicAvailabilitySlots.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Select at least one clinic visit slot for this week.',
        );
        return false;
      }
      if (formState.offersBookHome &&
          formState.selectedHomeAvailabilitySlots.isEmpty) {
        SnackBarHelper.showError(
          context,
          'Select at least one home visit slot for this week.',
        );
        return false;
      }
    }

    if (step == AppConstants.totalRegistrationSteps) {
      final missingHospitalPhotos = !formState.allHospitalPhotosUploaded;
      if (missingHospitalPhotos) {
        SnackBarHelper.showError(
          context,
          'Please upload all $doctorHospitalPhotoCount hospital photos.',
        );
        return false;
      }
      final requiredDocs = [
        DocumentType.medicalLicense,
        DocumentType.aadhaarCard,
        DocumentType.degreeCertificate,
        DocumentType.clinicProof,
        DocumentType.cancelledCheque,
      ];
      final missing = requiredDocs.any(
        (doc) => !formState.uploadedDocuments.containsKey(doc),
      );
      if (missing) {
        SnackBarHelper.showError(
          context,
          'Please complete all steps before submitting.',
        );
        return false;
      }
      if (formState.bankAccountNumber.trim().isEmpty ||
          formState.ifscCode.trim().isEmpty) {
        SnackBarHelper.showError(
          context,
          'Bank account and IFSC details are required.',
        );
        return false;
      }
      if (formState.upiId.trim().isEmpty) {
        SnackBarHelper.showError(context, 'UPI ID is required.');
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentRegistrationStepProvider);
    final stepMeta = _stepTitles[currentStep - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: currentStep > 1
              ? _previousStep
              : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          FormStepHeader(
            step: currentStep,
            total: AppConstants.totalRegistrationSteps,
            title: stepMeta.$1,
            subtitle: stepMeta.$2,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1PersonalInfo(formKey: _formKeys[0]),
                Step2ProfessionalDetails(formKey: _formKeys[1]),
                Step3ClinicAddress(formKey: _formKeys[2]),
                Step4DocumentUpload(formKey: _formKeys[3]),
                Step5BankDetails(formKey: _formKeys[4]),
                const Step6WeeklyAvailability(),
                Step7ReviewSubmit(
                  onSubmit: _submitRegistration,
                  onEdit: (step) {
                    _pageController.jumpToPage(step - 1);
                    ref.read(currentRegistrationStepProvider.notifier).state =
                        step;
                  },
                ),
              ],
            ),
          ),
          if (currentStep < AppConstants.totalRegistrationSteps)
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
                      label: currentStep ==
                              AppConstants.totalRegistrationSteps - 1
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
