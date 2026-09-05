import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';

class DonorHistoryScreen extends StatefulWidget {
  const DonorHistoryScreen({super.key});

  @override
  State<DonorHistoryScreen> createState() => _DonorHistoryScreenState();
}

class _DonorHistoryScreenState extends State<DonorHistoryScreen> {
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
    final res = await _repo.getDonationHistory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res.success ? null : res.error;
      _items = res.data ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My donation history')),
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
                            Center(child: Text('No donation history yet.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                title: Text('${item['bloodGroup']} · ${item['componentType']}'),
                                subtitle: Text(
                                  '${item['units']} units · ${item['status']}\n'
                                  '${item['donationDate'] ?? ''}'
                                  '${item['nextEligibleDate'] != null ? '\nNext eligible date: ${item['nextEligibleDate']}' : ''}',
                                ),
                                isThreeLine: true,
                                leading: const Icon(Icons.volunteer_activism_outlined,
                                    color: Color(0xFFB71C1C)),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
