import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/nursing_report_model.dart';
import '../../provider/patient_dashboard_provider.dart';
import '../utils/nursing_report_view_utils.dart';

final nursingReportsProvider =
    FutureProvider.autoDispose<List<NursingReportModel>>((ref) {
  return ref.read(patientDashboardRepositoryProvider).fetchNursingReports();
});

class NursingReportsScreen extends ConsumerWidget {
  const NursingReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nursingReportsProvider);
    final repo = ref.read(patientDashboardRepositoryProvider);
    final dateFmt = DateFormat('EEE, dd MMM yyyy · hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nursing reports'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 56,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No nursing reports yet',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'After a nurse home visit is completed, your digital nursing report will appear here.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(nursingReportsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final report = reports[index];
                final visitDate = report.slotStart ?? report.createdAt;
                return Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home nursing visit',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (visitDate != null)
                                    Text(
                                      dateFmt.format(visitDate),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if ((report.nurseNotes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            report.nurseNotes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => openNursingReportPdf(
                                  context,
                                  bookingId: report.bookingId,
                                  pdfUrl: report.pdfUrl,
                                  repository: repo,
                                ),
                                icon: const Icon(Icons.picture_as_pdf_rounded,
                                    size: 18),
                                label: const Text('View PDF'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Share',
                              onPressed: () => shareNursingReportPdf(
                                bookingId: report.bookingId,
                                pdfUrl: report.pdfUrl,
                                repository: repo,
                              ),
                              icon: const Icon(Icons.share_outlined),
                            ),
                            IconButton(
                              tooltip: 'Print',
                              onPressed: () => printNursingReportPdf(
                                bookingId: report.bookingId,
                                pdfUrl: report.pdfUrl,
                                repository: repo,
                              ),
                              icon: const Icon(Icons.print_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
