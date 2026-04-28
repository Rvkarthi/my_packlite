import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/di/providers.dart';
import '../../services/ai/weather_service.dart';
import '../../services/ai/offline_ai_service.dart';

final currentLocationProvider = FutureProvider<String?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied ||
          req == LocationPermission.deniedForever) {
        return null;
      }
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      ),
    );
    // Reverse geocode via Open-Meteo geocoding
    return '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
  } catch (_) {
    return null;
  }
});

final homeWeatherProvider = FutureProvider<WeatherData?>((ref) async {
  try {
    final locationStr = await ref.watch(currentLocationProvider.future);
    if (locationStr == null) return null;
    final parts = locationStr.split(', ');
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return ref
        .read(weatherServiceProvider)
        .getWeatherForCoords(lat, lng, 'Current Location');
  } catch (_) {
    return null;
  }
});

final aiSuggestionsProvider =
    FutureProvider.family<AiSuggestion, AiSuggestionParams>(
        (ref, params) async {
  return ref.read(offlineAiServiceProvider).getSuggestions(
        locationName: params.locationName,
        tempCelsius: params.tempCelsius,
        weatherCondition: params.weatherCondition,
        tripType: params.tripType,
      );
});

class AiSuggestionParams {
  final String locationName;
  final double? tempCelsius;
  final String? weatherCondition;
  final String? tripType;

  const AiSuggestionParams({
    required this.locationName,
    this.tempCelsius,
    this.weatherCondition,
    this.tripType,
  });

  @override
  bool operator ==(Object other) =>
      other is AiSuggestionParams &&
      other.locationName == locationName &&
      other.tempCelsius == tempCelsius &&
      other.weatherCondition == weatherCondition &&
      other.tripType == tripType;

  @override
  int get hashCode => Object.hash(locationName, tempCelsius, weatherCondition, tripType);
}
