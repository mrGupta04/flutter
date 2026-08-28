import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/token_storage.dart';
import 'selected_location.dart';

class ProviderSavedAddressStore {
  ProviderSavedAddressStore._();
  static final ProviderSavedAddressStore instance =
      ProviderSavedAddressStore._();

  static const _prefix = 'provider_saved_addresses_v1_';

  Future<String> _ownerKey() async {
    final storage = TokenStorage.instance;
    final id = await storage.getDoctorId() ??
        await storage.getNurseId() ??
        await storage.getAmbulanceId() ??
        await storage.getLabId() ??
        await storage.getBloodBankId() ??
        await storage.getScanCenterId() ??
        'local';
    return '$_prefix$id';
  }

  Future<List<SavedPlaceModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _ownerKey());
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => SavedPlaceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SavedPlaceModel>> upsert(SavedPlaceModel place) async {
    var items = [...await load()];
    final id = place.id.isEmpty ? const Uuid().v4() : place.id;
    var next = SavedPlaceModel(
      id: id,
      label: place.label,
      addressLine: place.addressLine,
      city: place.city,
      state: place.state,
      pincode: place.pincode,
      landmark: place.landmark,
      contactName: place.contactName,
      phone: place.phone,
      latitude: place.latitude,
      longitude: place.longitude,
      isDefault: place.isDefault || items.isEmpty,
    );
    if (next.isDefault) {
      items = items
          .map(
            (item) => SavedPlaceModel(
              id: item.id,
              label: item.label,
              addressLine: item.addressLine,
              city: item.city,
              state: item.state,
              pincode: item.pincode,
              landmark: item.landmark,
              contactName: item.contactName,
              phone: item.phone,
              latitude: item.latitude,
              longitude: item.longitude,
              isDefault: false,
            ),
          )
          .toList();
    }
    final index = items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      items[index] = next;
    } else {
      items.add(next);
    }
    await _persist(items);
    return items;
  }

  Future<List<SavedPlaceModel>> delete(String id) async {
    var items = (await load()).where((item) => item.id != id).toList();
    if (items.isNotEmpty && !items.any((item) => item.isDefault)) {
      final first = items.first;
      items[0] = SavedPlaceModel(
        id: first.id,
        label: first.label,
        addressLine: first.addressLine,
        city: first.city,
        state: first.state,
        pincode: first.pincode,
        landmark: first.landmark,
        contactName: first.contactName,
        phone: first.phone,
        latitude: first.latitude,
        longitude: first.longitude,
        isDefault: true,
      );
    }
    await _persist(items);
    return items;
  }

  Future<void> _persist(List<SavedPlaceModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      await _ownerKey(),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
