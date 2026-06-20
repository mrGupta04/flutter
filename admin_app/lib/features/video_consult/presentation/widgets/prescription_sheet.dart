import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/prescription_model.dart';
import '../../../../data/repositories/prescription_repository.dart';

class PrescriptionSheet extends StatefulWidget {
  const PrescriptionSheet({
    super.key,
    required this.bookingId,
    this.onSaved,
  });

  final String bookingId;
  final VoidCallback? onSaved;

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PrescriptionSheet(
        bookingId: bookingId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<PrescriptionSheet> createState() => _PrescriptionSheetState();
}

class _PrescriptionSheetState extends State<PrescriptionSheet> {
  final _repository = PrescriptionRepository();
  final _diagnosisController = TextEditingController();
  final _adviceController = TextEditingController();

  PrescriptionContextModel? _context;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final List<_MedicineRow> _medicines = [_MedicineRow()];
  final List<_TestRow> _tests = [_TestRow()];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _adviceController.dispose();
    for (final row in _medicines) {
      row.dispose();
    }
    for (final row in _tests) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContext() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contextData = await _repository.fetchContext(widget.bookingId);
      if (!mounted) return;

      final existing = contextData.prescription;
      if (existing != null) {
        _diagnosisController.text = existing.diagnosis ?? '';
        _adviceController.text = existing.advice ?? '';
        _medicines.clear();
        if (existing.medicines.isEmpty) {
          _medicines.add(_MedicineRow());
        } else {
          for (final med in existing.medicines) {
            _medicines.add(_MedicineRow.fromModel(med));
          }
        }
        _tests.clear();
        if (existing.tests.isEmpty) {
          _tests.add(_TestRow());
        } else {
          for (final test in existing.tests) {
            _tests.add(_TestRow.fromModel(test));
          }
        }
      }

      setState(() {
        _context = contextData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<PrescriptionMedicineModel> _collectMedicines() {
    return _medicines
        .map((row) => row.toModel())
        .where((med) => med.name.trim().isNotEmpty)
        .toList();
  }

  List<PrescriptionTestModel> _collectTests() {
    return _tests
        .map((row) => row.toModel())
        .where((test) => test.name.trim().isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final diagnosis = _diagnosisController.text.trim();
    final advice = _adviceController.text.trim();
    final medicines = _collectMedicines();
    final tests = _collectTests();

    if (diagnosis.isEmpty &&
        medicines.isEmpty &&
        tests.isEmpty &&
        advice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least a diagnosis, medicine, test, or advice.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await _repository.savePrescription(
        bookingId: widget.bookingId,
        diagnosis: diagnosis,
        medicines: medicines,
        tests: tests,
        advice: advice,
      );
      if (!mounted) return;

      widget.onSaved?.call();
      final emailNote = result.emailSent
          ? ' Prescription emailed to the patient.'
          : (result.emailReason != null
              ? ' Saved. Email not sent: ${result.emailReason}'
              : ' Saved for the patient profile.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescription saved.$emailNote')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Write prescription',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              _ReadOnlyField(
                                label: 'Patient name',
                                value: _context?.patientName ?? '—',
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyField(
                                label: 'Symptoms / notes',
                                value: (_context?.symptoms ?? '').isNotEmpty
                                    ? _context!.symptoms!
                                    : 'Not provided',
                              ),
                              if (_context?.slotLabel != null) ...[
                                const SizedBox(height: 12),
                                _ReadOnlyField(
                                  label: 'Appointment',
                                  value: _context!.slotLabel!,
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextField(
                                controller: _diagnosisController,
                                decoration: const InputDecoration(
                                  labelText: 'Diagnosis',
                                  hintText: 'e.g. Viral fever',
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Medicines',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() => _medicines.add(_MedicineRow()));
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add'),
                                  ),
                                ],
                              ),
                              ..._medicines.asMap().entries.map((entry) {
                                final index = entry.key;
                                final row = entry.value;
                                return _MedicineCard(
                                  row: row,
                                  index: index,
                                  onRemove: _medicines.length > 1
                                      ? () => setState(() {
                                            row.dispose();
                                            _medicines.removeAt(index);
                                          })
                                      : null,
                                );
                              }),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tests / investigations',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() => _tests.add(_TestRow()));
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add'),
                                  ),
                                ],
                              ),
                              ..._tests.asMap().entries.map((entry) {
                                final index = entry.key;
                                final row = entry.value;
                                return _TestCard(
                                  row: row,
                                  index: index,
                                  onRemove: _tests.length > 1
                                      ? () => setState(() {
                                            row.dispose();
                                            _tests.removeAt(index);
                                          })
                                      : null,
                                );
                              }),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _adviceController,
                                decoration: const InputDecoration(
                                  labelText: 'Advice / follow-up',
                                  hintText: 'Rest, fluids, review after 3 days...',
                                ),
                                maxLines: 3,
                              ),
                              if (_context?.prescription?.isFinalized == true) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'A prescription was already sent for this consultation. Saving again will replace it.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: _loading || _saving || _error != null ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('Save & send to patient'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineRow {
  _MedicineRow();

  _MedicineRow.fromModel(PrescriptionMedicineModel model) {
    nameController.text = model.name;
    dosageController.text = model.dosage ?? '';
    frequencyController.text = model.frequency ?? '';
    durationController.text = model.duration ?? '';
    instructionsController.text = model.instructions ?? '';
  }

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();
  final durationController = TextEditingController();
  final instructionsController = TextEditingController();

  PrescriptionMedicineModel toModel() => PrescriptionMedicineModel(
        name: nameController.text.trim(),
        dosage: dosageController.text.trim(),
        frequency: frequencyController.text.trim(),
        duration: durationController.text.trim(),
        instructions: instructionsController.text.trim(),
      );

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }
}

class _TestRow {
  _TestRow();

  _TestRow.fromModel(PrescriptionTestModel model) {
    nameController.text = model.name;
    notesController.text = model.notes ?? '';
  }

  final nameController = TextEditingController();
  final notesController = TextEditingController();

  PrescriptionTestModel toModel() => PrescriptionTestModel(
        name: nameController.text.trim(),
        notes: notesController.text.trim(),
      );

  void dispose() {
    nameController.dispose();
    notesController.dispose();
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.row,
    required this.index,
    this.onRemove,
  });

  final _MedicineRow row;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Medicine ${index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Remove medicine',
                  ),
              ],
            ),
            TextField(
              controller: row.nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                hintText: 'e.g. Paracetamol 500mg',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.frequencyController,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.durationController,
              decoration: const InputDecoration(labelText: 'Duration'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.instructionsController,
              decoration: const InputDecoration(labelText: 'Instructions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.row,
    required this.index,
    this.onRemove,
  });

  final _TestRow row;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Test ${index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Remove test',
                  ),
              ],
            ),
            TextField(
              controller: row.nameController,
              decoration: const InputDecoration(
                labelText: 'Test name',
                hintText: 'e.g. CBC, Blood sugar',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
