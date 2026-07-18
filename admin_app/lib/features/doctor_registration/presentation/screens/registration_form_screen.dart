import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../core/models/provider_type.dart';
import '../../../provider/provider/provider_status_sync.dart';
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

  Future<void> _nextStep() async {
    final currentStep = ref.read(currentRegistrationStepProvider);
    if (!_validateCurrentStep(currentStep)) return;
    await ref.read(registrationFormProvider.notifier).saveRegistrationDraft();
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

    if (!success && mounted) {
      final error = ref.read(registrationFormProvider).submitError ??
          'Registration could not be saved. Please try again.';
      SnackBarHelper.showError(context, error);
      return;
    }

    if (success && mounted) {
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await navigateAfterRegistration(context, ref, ProviderType.doctor);
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
      if (formState.offersOnlineConsult &&
          ValidationUtils.validateOptionalOfferFee(
                formState.onlineConsultOfferFee,
                formState.onlineConsultFee,
              ) !=
              null) {
        SnackBarHelper.showError(
          context,
          'Online offer price must be less than the regular online fee.',
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
      if (formState.offersVisitSite &&
          ValidationUtils.validateOptionalOfferFee(
                formState.visitSiteOfferFee,
                formState.visitSiteFee,
              ) !=
              null) {
        SnackBarHelper.showError(
          context,
          'Hospital visit offer must be less than the regular hospital fee.',
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
      if (formState.offersBookHome &&
          ValidationUtils.validateOptionalOfferFee(
                formState.homeVisitOfferFee,
                formState.homeVisitFee,
              ) !=
              null) {
        SnackBarHelper.showError(
          context,
          'Home visit offer must be less than the regular home visit fee.',
        );
        return false;
      }
    }

    if (step == 3) {
      if (formState.latitude == null || formState.longitude == null) {
        SnackBarHelper.showError(
          context,
          'Please pin the clinic on the map, or locate your typed address.',
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

  Widget _stepPage(int step, {required Widget child, Widget? footer}) {
    final meta = _stepTitles[step - 1];
    return RegistrationStepPage(
      step: step,
      total: AppConstants.totalRegistrationSteps,
      title: meta.$1,
      subtitle: meta.$2,
      footer: footer,
      child: child,
    );
  }

  Widget? _stepFooter(int step) {
    if (step >= AppConstants.totalRegistrationSteps) return null;
    return RegistrationStepActions(
      showBack: step > 1,
      onBack: _previousStep,
      onContinue: _nextStep,
      continueLabel: step == AppConstants.totalRegistrationSteps - 1
          ? 'Review'
          : 'Continue',
      continueIcon: Icons.arrow_forward_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentRegistrationStepProvider);

    return PopScope(
      canPop: currentStep <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _previousStep();
      },
      child: Scaffold(
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
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _stepPage(
            1,
            footer: _stepFooter(1),
            child: Step1PersonalInfo(formKey: _formKeys[0]),
          ),
          _stepPage(
            2,
            footer: _stepFooter(2),
            child: Step2ProfessionalDetails(formKey: _formKeys[1]),
          ),
          _stepPage(
            3,
            footer: _stepFooter(3),
            child: Step3ClinicAddress(formKey: _formKeys[2]),
          ),
          _stepPage(
            4,
            footer: _stepFooter(4),
            child: Step4DocumentUpload(formKey: _formKeys[3]),
          ),
          _stepPage(
            5,
            footer: _stepFooter(5),
            child: Step5BankDetails(formKey: _formKeys[4]),
          ),
          _stepPage(
            6,
            footer: _stepFooter(6),
            child: const Step6WeeklyAvailability(),
          ),
          _stepPage(
            7,
            child: Step7ReviewSubmit(
              onSubmit: _submitRegistration,
              onEdit: (step) {
                _pageController.jumpToPage(step - 1);
                ref.read(currentRegistrationStepProvider.notifier).state =
                    step;
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
