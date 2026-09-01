import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/receptionist_model.dart';
import '../../provider/receptionist_providers.dart';

class ReceptionistManagementScreen extends ConsumerWidget {
  const ReceptionistManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorReceptionistsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Receptionist Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Receptionist'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(doctorReceptionistsProvider.notifier).load(),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.items.isEmpty
                ? AppErrorWidget(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(doctorReceptionistsProvider.notifier).load(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
                    children: [
                      Text(
                        'Clinic receptionists can verify patient arrival using the OTP in the patient’s booking.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.items.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.badge_outlined,
                          title: 'No receptionists yet',
                          message: 'Create a receptionist account for your clinic desk.',
                        )
                      else
                        for (final item in state.items) ...[
                          _ReceptionistTile(item: item),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
      ),
    );
  }
}

class _ReceptionistTile extends ConsumerWidget {
  const _ReceptionistTile({required this.item});

  final ReceptionistModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.name,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item.email}${item.phone != null && item.phone!.isNotEmpty ? ' · ${item.phone}' : ''}\n${item.isActive ? 'Active' : 'Disabled'}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final notifier = ref.read(doctorReceptionistsProvider.notifier);
            switch (value) {
              case 'edit':
                await _showEditor(context, ref, existing: item);
              case 'toggle':
                final err = await notifier.setStatus(
                  item.id,
                  item.isActive ? 'disabled' : 'active',
                );
                if (context.mounted && err != null) {
                  SnackBarHelper.showError(context, err);
                }
              case 'password':
                await _showPasswordSheet(context, ref, item);
              case 'delete':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete receptionist'),
                    content: Text('Remove ${item.name} from your clinic?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final err = await notifier.delete(item.id);
                  if (context.mounted && err != null) {
                    SnackBarHelper.showError(context, err);
                  }
                }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit details')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(item.isActive ? 'Disable account' : 'Enable account'),
            ),
            const PopupMenuItem(value: 'password', child: Text('Reset password')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

Future<void> _showEditor(
  BuildContext context,
  WidgetRef ref, {
  ReceptionistModel? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final email = TextEditingController(text: existing?.email ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'Create Receptionist' : 'Edit Receptionist',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: name,
                  label: 'Receptionist name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phone,
                  label: 'Phone number (optional)',
                  keyboardType: TextInputType.phone,
                ),
                if (existing == null) ...[
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: password,
                    label: 'Password',
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 8)
                            ? 'At least 8 characters'
                            : null,
                  ),
                ],
                const SizedBox(height: 20),
                CustomButton(
                  label: existing == null ? 'Create Receptionist' : 'Save changes',
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    final notifier =
                        ref.read(doctorReceptionistsProvider.notifier);
                    final err = existing == null
                        ? await notifier.create(
                            name: name.text,
                            email: email.text,
                            password: password.text,
                            phone: phone.text,
                          )
                        : await notifier.update(
                            ReceptionistModel(
                              id: existing.id,
                              doctorId: existing.doctorId,
                              name: name.text.trim(),
                              email: email.text.trim(),
                              phone: phone.text.trim(),
                              status: existing.status,
                            ),
                          );
                    if (!ctx.mounted) return;
                    if (err != null) {
                      SnackBarHelper.showError(ctx, err);
                      return;
                    }
                    Navigator.pop(ctx);
                    SnackBarHelper.showSuccess(
                      context,
                      existing == null
                          ? 'Receptionist created'
                          : 'Receptionist updated',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  name.dispose();
  email.dispose();
  phone.dispose();
  password.dispose();
}

Future<void> _showPasswordSheet(
  BuildContext context,
  WidgetRef ref,
  ReceptionistModel item,
) async {
  final password = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset password',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: password,
              label: 'New password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Update password',
              onPressed: () async {
                if (password.text.length < 8) {
                  SnackBarHelper.showError(ctx, 'At least 8 characters');
                  return;
                }
                final err = await ref
                    .read(doctorReceptionistsProvider.notifier)
                    .resetPassword(item.id, password.text);
                if (!ctx.mounted) return;
                if (err != null) {
                  SnackBarHelper.showError(ctx, err);
                  return;
                }
                Navigator.pop(ctx);
                SnackBarHelper.showSuccess(context, 'Password updated');
              },
            ),
          ],
        ),
      );
    },
  );
  password.dispose();
}
