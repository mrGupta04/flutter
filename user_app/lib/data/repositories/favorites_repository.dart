import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../services/dio_service.dart';

class FavoriteItem {
  final String id;
  final String providerType;
  final String providerId;
  final Map<String, dynamic> provider;

  const FavoriteItem({
    required this.id,
    required this.providerType,
    required this.providerId,
    required this.provider,
  });

  String get displayName {
    final first = provider['firstName']?.toString() ?? '';
    final last = provider['lastName']?.toString() ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Provider' : name;
  }

  String? get specialization =>
      provider['specialization']?.toString() ??
      provider['qualification']?.toString();

  String? get profilePicture => provider['profilePicture']?.toString();

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      providerType: json['providerType']?.toString() ?? 'doctor',
      providerId: json['providerId']?.toString() ?? '',
      provider: json['provider'] is Map
          ? Map<String, dynamic>.from(json['provider'] as Map)
          : const {},
    );
  }
}

class FavoritesRepository {
  FavoritesRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<List<FavoriteItem>> list() async {
    try {
      final response = await _dio.get(AppConstants.endpointPatientFavorites);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .whereType<Map>()
          .map((e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<bool> isFavorite(String providerType, String providerId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientFavoriteCheck(providerType, providerId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return data['isFavorite'] as bool? ?? false;
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> add(String providerType, String providerId) async {
    try {
      await _dio.post(
        AppConstants.endpointPatientFavorites,
        data: {
          'providerType': providerType,
          'providerId': providerId,
        },
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> remove(String providerType, String providerId) async {
    try {
      await _dio.delete(
        AppConstants.endpointPatientFavoriteDelete(providerType, providerId),
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Request failed') as String;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}
