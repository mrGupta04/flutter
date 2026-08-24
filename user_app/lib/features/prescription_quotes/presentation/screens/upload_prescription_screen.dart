import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/lab_model.dart';
import '../../../../data/repositories/lab_repository.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../data/prescription_request_repository.dart';
import '../../provider/prescription_requests_provider.dart';

class UploadPrescriptionScreen extends ConsumerStatefulWidget {
  const UploadPrescriptionScreen({super.key, this.initialLab});

  final LabModel? initialLab;

  @override
  ConsumerState<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState
    extends ConsumerState<UploadPrescriptionScreen> {
  final _notesController = TextEditingController();
  final _testsController = TextEditingController();
  final _labSearchController = TextEditingController();

  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileExt;
  String? _uploadedUrl;
  String? _uploadedType;
  String? _uploadedName;

  final Set<String> _selectedLabIds = {};
  final Map<String, LabModel> _selectedLabs = {};
  List<LabModel> _labResults = [];
  bool _searchingLabs = false;
  bool _uploading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final lab = widget.initialLab;
    final id = lab?.id;
    if (lab != null && id != null && id.isNotEmpty) {
      _selectedLabIds.add(id);
      _selectedLabs[id] = lab;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _testsController.dispose();
    _labSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: PrescriptionRequestRepository.allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > AppConstants.maxFileSize) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'File exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB limit.',
      );
      return;
    }
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Could not read the selected file.');
      return;
    }
    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
      _fileExt = file.extension?.toLowerCase();
      _uploadedUrl = null;
      _uploadedType = null;
      _uploadedName = null;
    });
  }

  void _clearPrescription() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _fileExt = null;
      _uploadedUrl = null;
      _uploadedType = null;
      _uploadedName = null;
    });
  }

  Future<void> _searchLabs(String query) async {
    setState(() => _searchingLabs = true);
    final res = await LabRepository().searchVerified(
      LabSearchParams(query: query.trim().isEmpty ? null : query.trim()),
    );
    if (!mounted) return;
    setState(() {
      _searchingLabs = false;
      _labResults = res.success && res.data != null ? res.data! : [];
    });
  }

  void _toggleLab(LabModel lab) {
    final id = lab.id;
    if (id == null || id.isEmpty) return;

    if (_selectedLabIds.contains(id)) {
      setState(() {
        _selectedLabIds.remove(id);
        _selectedLabs.remove(id);
      });
      return;
    }
    if (_selectedLabIds.length >= PrescriptionRequestRepository.maxLabs) {
      SnackBarHelper.showError(
        context,
        'You can send a prescription request to a maximum of 4 labs.',
      );
      return;
    }
    setState(() {
      _selectedLabIds.add(id);
      _selectedLabs[id] = lab;
    });
  }

  Future<void> _submit() async {
    if (_fileBytes == null || _fileName == null) {
      SnackBarHelper.showError(context, 'Please upload a prescription first.');
      return;
    }
    if (_selectedLabIds.isEmpty) {
      SnackBarHelper.showError(
        context,
        'Select at least one lab or diagnostic center.',
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(prescriptionRequestRepositoryProvider);

    try {
      if (_uploadedUrl == null) {
        setState(() => _uploading = true);
        final upload = await repo.uploadPrescription(
          bytes: _fileBytes,
          filename: _fileName!,
        );
        setState(() => _uploading = false);
        if (!upload.success || upload.data == null) {
          throw Exception(upload.error ?? 'Upload failed');
        }
        _uploadedUrl = upload.data!.prescriptionFileUrl;
        _uploadedType = upload.data!.prescriptionFileType;
        _uploadedName = upload.data!.prescriptionFileName;
      }

      final tests = _testsController.text
          .split(RegExp(r'[\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((name) => {'name': name})
          .toList();

      final created = await repo.createRequest(
        prescriptionFileUrl: _uploadedUrl!,
        prescriptionFileType: _uploadedType ?? _fileExt ?? 'jpg',
        prescriptionFileName: _uploadedName ?? _fileName,
        labIds: _selectedLabIds.toList(),
        requestedTests: tests.isEmpty ? null : tests,
        notes: _notesController.text.trim(),
      );

      if (!created.success || created.data == null) {
        throw Exception(created.error ?? 'Failed to submit request');
      }

      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        created.message ?? 'Prescription request submitted',
      );
      context.pushReplacement(
        '${AppConstants.routePrescriptionRequestDetail}?id=${created.data!.id}',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAdaptiveScaffold(
      currentTab: UserNavTab.labs,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        title: const Text('Upload Prescription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            "Upload your doctor's prescription and send it to up to 4 labs for price quotes.",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _PrescriptionPickerCard(
            fileName: _fileName,
            fileExt: _fileExt,
            onPick: _pickPrescription,
            onClear: _fileName == null ? null : _clearPrescription,
          ),
          const SizedBox(height: 20),
          Text('Select labs (max 4)', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          if (_selectedLabs.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedLabs.values
                  .map(
                    (lab) => InputChip(
                      label: Text(lab.displayName),
                      onDeleted: () => _toggleLab(lab),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedLabIds.length}/4 labs selected'
                  '${_selectedLabIds.length >= 4 ? ' — Maximum 4 labs reached' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: _selectedLabIds.length >= 4
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          CaretOnTapTextField(
            controller: _labSearchController,
            decoration: const InputDecoration(
              hintText: 'Search labs...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) {
              if (v.trim().length >= 2 || v.trim().isEmpty) {
                _searchLabs(v);
              }
            },
            onTap: () {
              if (_labResults.isEmpty) _searchLabs('');
            },
          ),
          const SizedBox(height: 8),
          if (_searchingLabs)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._labResults.take(8).map((lab) {
              final selected = _selectedLabIds.contains(lab.id);
              return CheckboxListTile(
                value: selected,
                title: Text(lab.displayName),
                subtitle: Text(
                  [
                    if (lab.city != null && lab.city!.isNotEmpty) lab.city!,
                    if (lab.averageRating != null)
                      '⭐ ${lab.averageRating!.toStringAsFixed(1)}',
                  ].join(' · '),
                ),
                onChanged: (_) => _toggleLab(lab),
              );
            }),
          const SizedBox(height: 16),
          CaretOnTapTextField(
            controller: _testsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Requested tests (optional)',
              hintText: 'CBC, LFT, HbA1c...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          CaretOnTapTextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(
              _uploading
                  ? 'Uploading...'
                  : _submitting
                      ? 'Submitting...'
                      : 'Send for quotations',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionPickerCard extends StatelessWidget {
  const _PrescriptionPickerCard({
    required this.onPick,
    this.fileName,
    this.fileExt,
    this.onClear,
  });

  final VoidCallback onPick;
  final String? fileName;
  final String? fileExt;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                fileExt == 'pdf'
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName ?? 'No prescription selected',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(fileName == null ? 'Choose file' : 'Re-upload'),
          ),
          const SizedBox(height: 6),
          Text(
            'JPG, JPEG, PNG, or PDF · max 10 MB',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}