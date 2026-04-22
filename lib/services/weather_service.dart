import 'dart:convert';
import 'package:http/http.dart' as http;

// Simple data model holding weather values and walking advice for the UI.
class WeatherInfo {
  final double temperature;
  final int weatherCode;
  final int precipitationProbability;
  final String advice;
  final String description;

  WeatherInfo({
    required this.temperature,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.advice,
    required this.description,
  });
}

// Handles weather API requests and converts weather data into dog-walking advice.
class WeatherService {
  // Fetch current weather data for the user's location from the weather API.
  static Future<WeatherInfo> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
            '?latitude=$latitude'
            '&longitude=$longitude'
            '&current=temperature_2m,weather_code'
            '&hourly=precipitation_probability'
            '&forecast_hours=1'
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load weather data');
    }

    final data = jsonDecode(response.body);

    final current = data['current'];
    final hourly = data['hourly'];

    final double temperature =
    (current['temperature_2m'] as num).toDouble();
    final int weatherCode = current['weather_code'] as int;

    int precipitationProbability = 0;
    if (hourly != null &&
        hourly['precipitation_probability'] != null &&
        (hourly['precipitation_probability'] as List).isNotEmpty) {
      precipitationProbability =
          (hourly['precipitation_probability'][0] as num).toInt();
    }

    final description = weatherCodeToText(weatherCode);
    final advice = buildAdvice(
      temperature: temperature,
      weatherCode: weatherCode,
      precipitationProbability: precipitationProbability,
    );

    return WeatherInfo(
      temperature: temperature,
      weatherCode: weatherCode,
      precipitationProbability: precipitationProbability,
      advice: advice,
      description: description,
    );
  }

  // Convert the raw weather code into a readable weather description.
  static String weatherCodeToText(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1 || code == 2 || code == 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 67) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown weather';
  }

  // Turn weather conditions into a simple dog-walking recommendation.
  static String buildAdvice({
    required double temperature,
    required int weatherCode,
    required int precipitationProbability,
  }) {
    final isRainy = (weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82) ||
        (weatherCode >= 95 && weatherCode <= 99);

    if (isRainy || precipitationProbability >= 60) {
      return 'It may be better to wait or take only a short walk.';
    }

    if (temperature >= 28) {
      return 'It is quite hot. Consider a short walk and bring water.';
    }

    if (temperature <= 0) {
      return 'It is very cold. A shorter walk may be better today.';
    }

    if (temperature >= 10 && temperature <= 24 && precipitationProbability < 30) {
      return 'The weather looks great — time to walk your dog!';
    }

    return 'The weather is acceptable. A normal walk should be fine.';
  }
}