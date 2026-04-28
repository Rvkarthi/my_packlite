import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double tempCelsius;
  final String condition;
  final String description;
  final String icon;
  final String cityName;

  const WeatherData({
    required this.tempCelsius,
    required this.condition,
    required this.description,
    required this.icon,
    required this.cityName,
  });
}

/// Fetches weather from Open-Meteo (free, no API key required).
/// Silently returns null on any failure — never crashes the app.
class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _geocodeUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<WeatherData?> getWeatherForLocation(String cityName) async {
    try {
      // Step 1: Geocode city name
      final geoRes = await http
          .get(Uri.parse('$_geocodeUrl?name=${Uri.encodeComponent(cityName)}&count=1'))
          .timeout(const Duration(seconds: 5));
      if (geoRes.statusCode != 200) return null;
      final geoData = jsonDecode(geoRes.body) as Map<String, dynamic>;
      final results = geoData['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final lat = results[0]['latitude'] as double;
      final lng = results[0]['longitude'] as double;
      return getWeatherForCoords(lat, lng, cityName);
    } catch (_) {
      return null; // Silent failure
    }
  }

  Future<WeatherData?> getWeatherForCoords(
      double lat, double lng, String cityName) async {
    try {
      final url =
          '$_baseUrl?latitude=$lat&longitude=$lng&current=temperature_2m,weathercode&temperature_unit=celsius';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final temp = (current['temperature_2m'] as num).toDouble();
      final code = current['weathercode'] as int;
      final condition = _codeToCondition(code);
      return WeatherData(
        tempCelsius: temp,
        condition: condition,
        description: condition,
        icon: _codeToIcon(code),
        cityName: cityName,
      );
    } catch (_) {
      return null;
    }
  }

  String _codeToCondition(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 9) return 'Foggy';
    if (code <= 19) return 'Drizzle';
    if (code <= 29) return 'Rain';
    if (code <= 39) return 'Snow';
    if (code <= 49) return 'Freezing Drizzle';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rain';
    if (code <= 79) return 'Snow';
    if (code <= 84) return 'Rain Showers';
    if (code <= 94) return 'Thunderstorm';
    return 'Thunderstorm';
  }

  String _codeToIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 9) return '🌫️';
    if (code <= 39) return '🌧️';
    if (code <= 79) return '❄️';
    if (code <= 84) return '🌦️';
    return '⛈️';
  }
}
