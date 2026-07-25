import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/services/dio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_booking_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_back_navigation.dart';

/// Multi-step nursing assessment form for a home visit.
class NurseVisitAssessmentScreen extends StatefulWidget {
  const NurseVisitAssessmentScreen({
    super.key,
    required this.booking,
    this.initialDraft,
  });

  final DoctorBookingModel booking;
  final Map<String, dynamic>? initialDraft;

  @override
  State<NurseVisitAssessmentScreen> createState() =>
      _NurseVisitAssessmentScreenState();
}

class _NurseVisitAssessmentScreenState extends State<NurseVisitAssessmentScreen> {
  final _pageController = PageController();
  int _step = 0;
  bool _saving = false;
  bool _submitting = false;

  // Vitals
  final _bpSys = TextEditingController();
  final _bpDia = TextEditingController();
  final _pulse = TextEditingController();
  final _spo2 = TextEditingController();
  final _temp = TextEditingController();
  final _sugar = TextEditingController();
  String _sugarType = 'random';
  final _respRate = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  // General
  final _condition = TextEditingController();
  double _painLevel = 3;
  String _mentalStatus = 'Alert';
  String _mobility = 'Independent';
  String _hydration = 'Normal';

  final _symptoms = <String>{};
  final _symptomsOther = TextEditingController();
  final _procedures = <String>{};
  final _proceduresOther = TextEditingController();
  final _medicines = <Map<String, String>>[];
  final _nurseNotes = TextEditingController();
  String? _followUp;

  static const _symptomOptions = [
    'Fever', 'Cough', 'Cold', 'Vomiting', 'Diarrhoea', 'Headache',
    'Body Pain', 'Breathing Difficulty', 'Swelling', 'Weakness',
  ];
  static const _procedureOptions = [
    'BP Monitoring', 'Sugar Check', 'Temperature Check', 'Wound Dressing',
    'Injection', 'IV Fluid', 'Catheter Care', 'Tube Feeding', 'Nebulisation',
    'ECG', 'Sample Collection', 'Medication Administration',
  ];

  @override
  void initState() {
    super.initState();
    _loadDraft(widget.initialDraft);
    _fetchDraftFromServer();
  }

  Future<void> _fetchDraftFromServer() async {
    try {
      final response = await DioService().get(
        AppConstants.endpointNurseVisitNote(widget.booking.id),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() => _loadDraft(data));
      }
    } catch (_) {}
  }

  void _loadDraft(Map<String, dynamic>? draft) {
    if (draft == null) return;
    _medicines.clear();
    final vitals = draft['vitalsData'] as Map<String, dynamic>? ?? {};
    _bpSys.text = '${vitals['bloodPressureSystolic'] ?? ''}';
    _bpDia.text = '${vitals['bloodPressureDiastolic'] ?? ''}';
    _pulse.text = '${vitals['pulseRate'] ?? ''}';
    _spo2.text = '${vitals['oxygenSaturation'] ?? ''}';
    _temp.text = '${vitals['bodyTemperature'] ?? ''}';
    _sugar.text = '${vitals['bloodSugar'] ?? ''}';
    _sugarType = vitals['bloodSugarType']?.toString() ?? 'random';
    _respRate.text = '${vitals['respiratoryRate'] ?? ''}';
    _height.text = '${vitals['heightCm'] ?? ''}';
    _weight.text = '${vitals['weightKg'] ?? ''}';

    final ga = draft['generalAssessment'] as Map<String, dynamic>? ?? {};
    _condition.text = ga['patientCondition']?.toString() ?? '';
    _painLevel = (ga['painLevel'] as num?)?.toDouble() ?? 3;
    _mentalStatus = ga['mentalStatus']?.toString() ?? 'Alert';
    _mobility = ga['mobilityStatus']?.toString() ?? 'Independent';
    _hydration = ga['hydrationStatus']?.toString() ?? 'Normal';

    _symptoms.addAll((draft['symptoms'] as List?)?.map((e) => '$e') ?? []);
    _symptomsOther.text = draft['symptomsOther']?.toString() ?? '';
    _procedures.addAll(
      (draft['proceduresPerformed'] as List?)?.map((e) => '$e') ?? [],
    );
    _proceduresOther.text = draft['proceduresOther']?.toString() ?? '';
    _nurseNotes.text =
        draft['nurseNotes']?.toString() ?? draft['careSummary']?.toString() ?? '';
    _followUp = draft['followUpRecommendation']?.toString();
    for (final raw in (draft['medicinesAdministered'] as List?) ?? []) {
      if (raw is! Map) continue;
      _medicines.add({
        'name': raw['name']?.toString() ?? '',
        'dosage': raw['dosage']?.toString() ?? '',
        'quantity': raw['quantity']?.toString() ?? '',
        'route': raw['route']?.toString() ?? 'Oral',
        'timeGiven': raw['timeGiven']?.toString() ?? '',
      });
    }
  }

  Future<void> _addMedicine() async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    var route = 'Oral';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: route,
                  decoration: const InputDecoration(labelText: 'Route'),
                  items: const [
                    DropdownMenuItem(value: 'Oral', child: Text('Oral')),
                    DropdownMenuItem(value: 'IV', child: Text('IV')),
                    DropdownMenuItem(value: 'IM', child: Text('IM')),
                    DropdownMenuItem(value: 'Topical', child: Text('Topical')),
                  ],
                  onChanged: (v) => setLocal(() => route = v ?? 'Oral'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time given',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _medicines.add({
          'name': nameCtrl.text.trim(),
          'dosage': dosageCtrl.text.trim(),
          'quantity': qtyCtrl.text.trim(),
          'route': route,
          'timeGiven': timeCtrl.text.trim(),
        });
      });
    }
    nameCtrl.dispose();
    dosageCtrl.dispose();
    qtyCtrl.dispose();
    timeCtrl.dispose();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bpSys.dispose();
    _bpDia.dispose();
    _pulse.dispose();
    _spo2.dispose();
    _temp.dispose();
    _sugar.dispose();
    _respRate.dispose();
    _height.dispose();
    _weight.dispose();
    _condition.dispose();
    _symptomsOther.dispose();
    _proceduresOther.dispose();
    _nurseNotes.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    double? parseNum(String v) =>
        v.trim().isEmpty ? null : double.tryParse(v.trim());
    int? parseInt(String v) =>
        v.trim().isEmpty ? null : int.tryParse(v.trim());

    final h = parseNum(_height.text);
    final w = parseNum(_weight.text);
    double? bmi;
    if (h != null && w != null && h > 0) {
      final m = h / 100;
      bmi = double.parse((w / (m * m)).toStringAsFixed(1));
    }

    return {
      'vitalsData': {
        if (parseInt(_bpSys.text) != null)
          'bloodPressureSystolic': parseInt(_bpSys.text),
        if (parseInt(_bpDia.text) != null)
          'bloodPressureDiastolic': parseInt(_bpDia.text),
        if (parseInt(_pulse.text) != null) 'pulseRate': parseInt(_pulse.text),
        if (parseInt(_spo2.text) != null)
          'oxygenSaturation': parseInt(_spo2.text),
        if (parseNum(_temp.text) != null)
          'bodyTemperature': parseNum(_temp.text),
        if (parseNum(_sugar.text) != null) 'bloodSugar': parseNum(_sugar.text),
        if (_sugar.text.trim().isNotEmpty) 'bloodSugarType': _sugarType,
        if (parseInt(_respRate.text) != null)
          'respiratoryRate': parseInt(_respRate.text),
        if (h != null) 'heightCm': h,
        if (w != null) 'weightKg': w,
        if (bmi != null) 'bmi': bmi,
      },
      'generalAssessment': {
        if (_condition.text.trim().isNotEmpty)
          'patientCondition': _condition.text.trim(),
        'painLevel': _painLevel.round(),
        'mentalStatus': _mentalStatus,
        'mobilityStatus': _mobility,
        'hydrationStatus': _hydration,
      },
      'symptoms': _symptoms.toList(),
      if (_symptomsOther.text.trim().isNotEmpty)
        'symptomsOther': _symptomsOther.text.trim(),
      'proceduresPerformed': _procedures.toList(),
      if (_proceduresOther.text.trim().isNotEmpty)
        'proceduresOther': _proceduresOther.text.trim(),
      'medicinesAdministered': _medicines
          .where((m) => (m['name'] ?? '').trim().isNotEmpty)
          .map((m) => {
                'name': m['name']!.trim(),
                if ((m['dosage'] ?? '').trim().isNotEmpty)
                  'dosage': m['dosage']!.trim(),
                if ((m['quantity'] ?? '').trim().isNotEmpty)
                  'quantity': m['quantity']!.trim(),
                if ((m['route'] ?? '').trim().isNotEmpty)
                  'route': m['route']!.trim(),
                if ((m['timeGiven'] ?? '').trim().isNotEmpty)
                  'timeGiven': m['timeGiven']!.trim(),
              })
          .toList(),
      'nurseNotes': _nurseNotes.text.trim(),
      if (_followUp != null) 'followUpRecommendation': _followUp,
    };
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await DioService().put(
        AppConstants.endpointNurseVisitReport(widget.booking.id),
        data: _payload(),
      );
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Draft saved');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    if (_nurseNotes.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Nurse notes are required');
      return;
    }
    setState(() => _submitting = true);
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitReportSubmit(widget.booking.id),
        data: _payload(),
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Report submitted & PDF generated');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goToPreviousStep() {
    if (_step <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepBackScope(
      step: _step,
      onPreviousStep: _goToPreviousStep,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Nursing assessment'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveDraft,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.booking.patientName ?? 'Patient',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  backgroundColor: AppColors.grey100,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  'Step ${_step + 1} of 4',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _vitalsStep(),
                _assessmentStep(),
                _proceduresStep(),
                _notesStep(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goToPreviousStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_step < 3) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              } else {
                                _submit();
                              }
                            },
                      child: Text(
                        _step < 3
                            ? 'Continue'
                            : (_submitting ? 'Submitting…' : 'Submit report'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _vitalsStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Patient vitals'),
        Row(
          children: [
            Expanded(child: _field(_bpSys, 'Systolic BP')),
            const SizedBox(width: 10),
            Expanded(child: _field(_bpDia, 'Diastolic BP')),
          ],
        ),
        _field(_pulse, 'Pulse (bpm)'),
        _field(_spo2, 'SpO₂ (%)'),
        _field(_temp, 'Temperature (°F)'),
        _field(_sugar, 'Blood sugar (mg/dL)'),
        DropdownButtonFormField<String>(
          value: _sugarType,
          decoration: const InputDecoration(labelText: 'Sugar type'),
          items: const [
            DropdownMenuItem(value: 'random', child: Text('Random')),
            DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
          ],
          onChanged: (v) => setState(() => _sugarType = v ?? 'random'),
        ),
        _field(_respRate, 'Respiratory rate'),
        Row(
          children: [
            Expanded(child: _field(_height, 'Height (cm)')),
            const SizedBox(width: 10),
            Expanded(child: _field(_weight, 'Weight (kg)')),
          ],
        ),
      ],
    );
  }

  Widget _assessmentStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('General assessment'),
        _field(_condition, 'Patient condition'),
        Text('Pain level: ${_painLevel.round()}/10',
            style: AppTextStyles.labelMedium),
        Slider(
          value: _painLevel,
          min: 1,
          max: 10,
          divisions: 9,
          label: _painLevel.round().toString(),
          onChanged: (v) => setState(() => _painLevel = v),
        ),
        _dropdown('Mental status', _mentalStatus,
            ['Alert', 'Confused', 'Drowsy', 'Unresponsive'],
            (v) => setState(() => _mentalStatus = v)),
        _dropdown('Mobility', _mobility,
            ['Independent', 'Assisted', 'Bedridden'],
            (v) => setState(() => _mobility = v)),
        _dropdown('Hydration', _hydration,
            ['Normal', 'Mild dehydration', 'Severe dehydration'],
            (v) => setState(() => _hydration = v)),
        const SizedBox(height: 12),
        _sectionTitle('Symptoms'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _symptomOptions.map((s) {
            final selected = _symptoms.contains(s);
            return FilterChip(
              label: Text(s),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _symptoms.add(s);
                } else {
                  _symptoms.remove(s);
                }
              }),
            );
          }).toList(),
        ),
        _field(_symptomsOther, 'Other symptoms'),
      ],
    );
  }

  Widget _proceduresStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Procedures performed'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _procedureOptions.map((p) {
            final selected = _procedures.contains(p);
            return FilterChip(
              label: Text(p),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _procedures.add(p);
                } else {
                  _procedures.remove(p);
                }
              }),
            );
          }).toList(),
        ),
        _field(_proceduresOther, 'Other procedures'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Medicines administered'),
            TextButton.icon(
              onPressed: _addMedicine,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_medicines.isEmpty)
          Text(
            'No medicines added yet.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ..._medicines.asMap().entries.map((entry) {
          final i = entry.key;
          final med = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                med['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if ((med['dosage'] ?? '').isNotEmpty) med['dosage'],
                  if ((med['quantity'] ?? '').isNotEmpty) 'Qty ${med['quantity']}',
                  med['route'] ?? 'Oral',
                  if ((med['timeGiven'] ?? '').isNotEmpty) med['timeGiven'],
                ].whereType<String>().join(' · '),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _medicines.removeAt(i)),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _notesStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Nurse notes'),
        TextField(
          controller: _nurseNotes,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Observations, recommendations, remarks…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Follow-up recommendation'),
        ...[
          ('continue_medication', 'Continue medication'),
          ('consult_doctor', 'Consult doctor'),
          ('emergency_visit', 'Emergency visit recommended'),
          ('follow_up_home_visit', 'Follow-up home visit'),
          ('hospital_admission', 'Hospital admission suggested'),
        ].map(
          (item) => RadioListTile<String>(
            value: item.$1,
            groupValue: _followUp,
            title: Text(item.$2),
            onChanged: (v) => setState(() => _followUp = v),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.numberWithOptions(
          decimal: label.contains('Temperature') || label.contains('Weight'),
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
