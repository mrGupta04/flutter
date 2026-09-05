import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_booking_model.dart';
import '../../../../data/repositories/ambulance_repository.dart';

class AmbulanceTripDetailScreen extends StatefulWidget {
  const AmbulanceTripDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<AmbulanceTripDetailScreen> createState() =>
      _AmbulanceTripDetailScreenState();
}

class _AmbulanceTripDetailScreenState extends State<AmbulanceTripDetailScreen> {
  AmbulanceBookingModel? _booking;
  String? _error;
  bool _loading = true;
  int _rating = 5;
  final _review = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final response = await AmbulanceRepository().getMyBooking(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _booking = response.data;
      _error = response.success ? null : response.error;
      _loading = false;
    });
  }

  Future<void> _pay() async {
    final repo = AmbulanceRepository();
    final order = await repo.createPaymentOrder(widget.bookingId);
    if (!mounted) return;
    if (!order.success) {
      SnackBarHelper.showError(context, order.error ?? 'Payment could not start');
      return;
    }
    final verify = await repo.verifyPayment({
      'bookingId': widget.bookingId,
      'razorpayOrderId': (order.data?['razorpayOrder'] as Map?)?['id'],
      'razorpayPaymentId': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      'razorpaySignature': 'mock',
    });
    if (!mounted) return;
    if (verify.success) {
      SnackBarHelper.showSuccess(context, 'Payment confirmed');
      _load();
    } else {
      SnackBarHelper.showError(context, verify.error ?? 'Payment failed');
    }
  }

  Future<void> _submitReview() async {
    final response = await AmbulanceRepository().submitReview(widget.bookingId, {
      'ambulanceRating': _rating,
      'driverRating': _rating,
      'providerRating': _rating,
      'review': _review.text.trim(),
    });
    if (!mounted) return;
    if (response.success) {
      SnackBarHelper.showSuccess(context, 'Thank you for the review');
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Could not submit review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? Center(child: Text(_error ?? 'Trip not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(booking.statusLabel ?? booking.status, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    _row('Booking ID', booking.id),
                    _row('Patient', booking.patientName),
                    _row('Pickup', booking.pickupAddress),
                    _row('Destination', booking.dropAddress ?? booking.destinationHospitalName),
                    _row('Ambulance', booking.ambulanceServiceName),
                    _row('Driver', booking.assignedDriverName),
                    _row('Vehicle', booking.assignedVehicleRegistration),
                    _row('Type', booking.assignedVehicleType ?? booking.vehicleTypeRequested),
                    _row('Fare', booking.fare == null ? '—' : '₹${booking.fare!.total}'),
                    _row('Payment', booking.paymentStatus),
                    const SizedBox(height: 16),
                    const Text('Status timeline', style: TextStyle(fontWeight: FontWeight.w800)),
                    ...booking.timeline.map(
                      (step) => ListTile(
                        dense: true,
                        leading: Icon(
                          step['done'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(step['label']?.toString() ?? ''),
                      ),
                    ),
                    if (booking.canTrack || booking.isSearching)
                      FilledButton(
                        onPressed: () => context.push(
                          '${AppConstants.routeAmbulanceTrack}?bookingId=${booking.id}',
                        ),
                        child: const Text('Track live'),
                      ),
                    if (booking.paymentStatus == 'unpaid' || booking.paymentStatus == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton(
                          onPressed: _pay,
                          child: const Text('Pay now'),
                        ),
                      ),
                    if (booking.canReview) ...[
                      const SizedBox(height: 20),
                      const Text('Rate this trip', style: TextStyle(fontWeight: FontWeight.w800)),
                      Slider(
                        value: _rating.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$_rating',
                        onChanged: (value) => setState(() => _rating = value.round()),
                      ),
                      CustomTextField(controller: _review, label: 'Review (optional)', maxLines: 3),
                      const SizedBox(height: 8),
                      CustomButton(label: 'Submit review', onPressed: _submitReview),
                    ],
                  ],
                ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }
}
