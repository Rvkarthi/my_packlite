import 'dart:convert';
import 'package:flutter/services.dart';

class AiSuggestion {
  final List<String> places;
  final List<String> packingItems;
  final String reasoning;

  const AiSuggestion({
    required this.places,
    required this.packingItems,
    required this.reasoning,
  });
}

/// Rule-based offline AI engine. No network calls. No fake responses.
/// Uses local JSON dataset + deterministic rules.
class OfflineAiService {
  Map<String, dynamic>? _dataset;

  Future<void> initialize() async {
    if (_dataset != null) return;
    final raw = await rootBundle.loadString('assets/data/ai_dataset.json');
    _dataset = jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Generate suggestions based on location name, temperature, and weather condition.
  Future<AiSuggestion> getSuggestions({
    required String locationName,
    double? tempCelsius,
    String? weatherCondition,
    String? tripType,
  }) async {
    await initialize();
    final data = _dataset!;

    final places = <String>[];
    final items = <String>[];
    final reasons = <String>[];

    // --- Location matching ---
    final locationKey = _matchLocation(locationName.toLowerCase());
    if (locationKey != null) {
      final locData = data['locations'][locationKey] as Map<String, dynamic>;
      places.addAll((locData['places'] as List).cast<String>());
      items.addAll((locData['items'] as List).cast<String>());
      reasons.add('Based on $locationKey destination');
    }

    // --- Weather rules ---
    if (tempCelsius != null) {
      final weatherData = data['weather'] as Map<String, dynamic>;
      if (tempCelsius < 10) {
        items.addAll((weatherData['cold']['items'] as List).cast<String>());
        reasons.add('Cold weather (${tempCelsius.round()}°C)');
      } else if (tempCelsius < 18) {
        items.addAll((weatherData['cool']['items'] as List).cast<String>());
        reasons.add('Cool weather (${tempCelsius.round()}°C)');
      } else if (tempCelsius < 28) {
        items.addAll((weatherData['warm']['items'] as List).cast<String>());
        reasons.add('Warm weather (${tempCelsius.round()}°C)');
      } else {
        items.addAll((weatherData['hot']['items'] as List).cast<String>());
        reasons.add('Hot weather (${tempCelsius.round()}°C)');
      }
    }

    // --- Precipitation rules ---
    if (weatherCondition != null) {
      final cond = weatherCondition.toLowerCase();
      final weatherData = data['weather'] as Map<String, dynamic>;
      if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) {
        items.addAll((weatherData['rain']['items'] as List).cast<String>());
        reasons.add('Rainy conditions expected');
      }
      if (cond.contains('snow') || cond.contains('blizzard') || cond.contains('sleet')) {
        items.addAll((weatherData['snow']['items'] as List).cast<String>());
        reasons.add('Snow conditions expected');
      }
    }

    // --- Trip type rules ---
    if (tripType != null) {
      final tripData = data['trip_types'] as Map<String, dynamic>;
      final key = tripType.toLowerCase();
      if (tripData.containsKey(key)) {
        items.addAll((tripData[key]['items'] as List).cast<String>());
        reasons.add('$tripType trip type');
      }
    }

    // --- Always add essentials ---
    final essentials = (data['essentials'] as List).cast<String>();
    for (final e in essentials) {
      if (!items.contains(e)) items.add(e);
    }

    // Deduplicate
    final uniqueItems = items.toSet().toList();
    final uniquePlaces = places.toSet().toList();

    return AiSuggestion(
      places: uniquePlaces,
      packingItems: uniqueItems,
      reasoning: reasons.isEmpty ? 'General travel essentials' : reasons.join(' • '),
    );
  }

  String? _matchLocation(String name) {
    final keywords = {
      'beach': ['beach', 'coast', 'ocean', 'sea', 'bay', 'island', 'bali', 'hawaii', 'cancun', 'maldives', 'phuket'],
      'mountain': ['mountain', 'alps', 'hiking', 'trek', 'peak', 'summit', 'rockies', 'andes', 'himalaya', 'everest'],
      'city': ['city', 'new york', 'london', 'paris', 'tokyo', 'berlin', 'sydney', 'dubai', 'singapore', 'chicago'],
      'desert': ['desert', 'sahara', 'dubai', 'arizona', 'nevada', 'mojave', 'atacama'],
      'tropical': ['tropical', 'jungle', 'rainforest', 'amazon', 'costa rica', 'borneo', 'thailand'],
      'europe': ['europe', 'paris', 'rome', 'barcelona', 'amsterdam', 'prague', 'vienna', 'lisbon', 'athens'],
      'japan': ['japan', 'tokyo', 'osaka', 'kyoto', 'hiroshima', 'sapporo'],
      'ski': ['ski', 'snowboard', 'aspen', 'vail', 'whistler', 'chamonix', 'zermatt', 'verbier'],
    };

    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (name.contains(kw)) return entry.key;
      }
    }
    return null;
  }
}
