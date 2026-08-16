import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/prescription_requests_provider.dart';

class PrescriptionRequestsListScreen extends ConsumerStatefulWidget {
  const PrescriptionRequestsListScreen({super.key});

  @override
  ConsumerState<PrescriptionRequestsListScreen> createState() =>
      _PrescriptionRequestsListScreenState();
}

class _PrescriptionRequestsListScreenState
    extends ConsumerState<PrescriptionRequestsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prescriptionRequestsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionRequestsProvider);

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.labs,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        title: const Text('My prescription requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(prescriptionRequestsProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeUploadPrescription),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
      ),
      body: state.isLoading && state.requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.requests.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(prescriptionRequestsProvider.notifier).load(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(prescriptionRequestsProvider.notifier).load(),
                  child: state.requests.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text('No prescription requests yet.'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: state.requests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final r = state.requests[index];
                            final quoted = r.activeQuotations.length;
                            return ListTile(
                              tileColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              title: Text(
                                'Request #${r.id.length > 8 ? r.id.substring(0, 8) : r.id}',
                                style: AppTextStyles.titleSmall,
                              ),
                              subtitle: Text(
                                '${r.status.replaceAll('_', ' ')} · $quoted quotation(s) · ${r.paymentStatus}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.push(
                                '${AppConstants.routePrescriptionRequestDetail}?id=${r.id}',
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}