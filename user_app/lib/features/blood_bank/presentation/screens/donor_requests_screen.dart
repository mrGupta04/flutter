import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';

class DonorRequestsScreen extends StatefulWidget {
  const DonorRequestsScreen({super.key});

  @override
  State<DonorRequestsScreen> createState() => _DonorRequestsScreenState();
}

class _DonorRequestsScreenState extends State<DonorRequestsScreen> {
  final _repo = BloodBankRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.getDonorRequests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res.success ? null : res.error;
      _items = res.data ?? const [];
    });
  }

  Future<void> _respond(String id, bool accept) async {
    final res = await _repo.respondToDonorRequest(id, accept: accept);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message ?? res.error ?? 'Updated')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency donor requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No emergency donation requests right now.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final pending = item['status'] == 'notified';
                            return Card(
                              color: pending ? const Color(0xFFFFEBEE) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency Blood Request',
                                      style: TextStyle(
                                        color: pending ? const Color(0xFFB71C1C) : AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Blood group: ${item['bloodGroup'] ?? ''}'),
                                    Text('Location: ${item['hospitalName'] ?? 'Hospital'}'),
                                    if (item['distanceKm'] != null)
                                      Text('Distance: ${item['distanceKm']} km'),
                                    Text('Required: ${item['units'] ?? ''} units'),
                                    const SizedBox(height: 10),
                                    if (pending)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton(
                                              onPressed: () => _respond(item['id'] as String, true),
                                              child: const Text('I Can Donate'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _respond(item['id'] as String, false),
                                              child: const Text('Not Available'),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text('Status: ${item['status']}'.replaceAll('_', ' ')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
