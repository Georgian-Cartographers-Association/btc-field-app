/// Parsed data from api.met.no locationforecast/2.0/compact
class WeatherHour {
  final DateTime time;
  final double temperature; // °C
  final double windSpeed;   // m/s
  final double windDir;     // degrees from north
  final double humidity;    // %
  final double precipitation; // mm
  final String symbolCode;  // e.g. "clearsky_day", "rain"

  const WeatherHour({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windDir,
    required this.humidity,
    required this.precipitation,
    required this.symbolCode,
  });

  /// Human-readable weather emoji for this symbol.
  String get emoji => WeatherData.symbolEmoji(symbolCode);

  /// Georgian wind direction label.
  String get windDirLabel {
    const dirs = ['ჩ', 'ჩ-აღ', 'აღ', 'სამ-აღ', 'სამ', 'სამ-დ', 'დ', 'ჩ-დ'];
    final idx = ((windDir + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }
}

class WeatherData {
  final WeatherHour current;
  final List<WeatherHour> hourly; // next ~24 h
  final DateTime fetchedAt;

  const WeatherData({
    required this.current,
    required this.hourly,
    required this.fetchedAt,
  });

  // ── Factory ────────────────────────────────────────────────────────────────

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final timeseries = json['properties']['timeseries'] as List;
    final now = DateTime.now().toUtc();
    final hours = <WeatherHour>[];

    for (final item in timeseries) {
      final time = DateTime.parse(item['time'] as String);
      if (time.isBefore(now.subtract(const Duration(hours: 1)))) continue;

      final details =
          (item['data']['instant']['details'] as Map<String, dynamic>);
      final next1 = item['data']['next_1_hours'] as Map<String, dynamic>?;
      final next6 = item['data']['next_6_hours'] as Map<String, dynamic>?;

      final symbol = (next1?['summary']?['symbol_code'] ??
              next6?['summary']?['symbol_code'] ??
              'cloudy') as String;
      final precip = ((next1?['details']?['precipitation_amount'] ??
              next6?['details']?['precipitation_amount'] ??
              0) as num)
          .toDouble();

      hours.add(WeatherHour(
        time: time,
        temperature: (details['air_temperature'] as num).toDouble(),
        windSpeed: (details['wind_speed'] as num).toDouble(),
        windDir: (details['wind_from_direction'] as num?)?.toDouble() ?? 0,
        humidity: (details['relative_humidity'] as num?)?.toDouble() ?? 0,
        precipitation: precip,
        symbolCode: symbol,
      ));

      if (hours.length >= 25) break;
    }

    if (hours.isEmpty) throw const FormatException('Empty timeseries');

    return WeatherData(
      current: hours.first,
      hourly: hours.skip(1).toList(),
      fetchedAt: DateTime.now(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String symbolEmoji(String code) {
    final c = code.toLowerCase();
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('heavyrain') || c.contains('heavy_rain')) return '🌧️';
    if (c.contains('lightrain') || c.contains('drizzle')) return '🌦️';
    if (c.contains('rain') || c.contains('shower')) return '🌧️';
    if (c.contains('sleet')) return '🌨️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('fog')) return '🌫️';
    if (c.contains('clearsky') || c.contains('fair')) {
      return c.contains('night') ? '🌙' : '☀️';
    }
    if (c.contains('partlycloudy') || c.contains('partly')) return '⛅';
    if (c.contains('cloud') || c.contains('overcast')) return '☁️';
    return '🌡️';
  }

  static String symbolGeorgian(String code) {
    final c = code.toLowerCase();
    if (c.contains('thunder')) return 'ჭექა-ქუხილი';
    if (c.contains('heavyrain')) return 'ძლიერი წვიმა';
    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
      return 'წვიმა';
    }
    if (c.contains('sleet')) return 'თოვა-წვიმა';
    if (c.contains('snow')) return 'თოვლი';
    if (c.contains('fog')) return 'ნისლი';
    if (c.contains('clearsky')) return 'მოწმენდილი';
    if (c.contains('fair')) return 'ნათელი';
    if (c.contains('partlycloudy') || c.contains('partly')) return 'ნაწილობრივ ღრუბლიანი';
    if (c.contains('overcast')) return 'მოღრუბლული';
    if (c.contains('cloud')) return 'ღრუბლიანი';
    return 'ამინდი';
  }
}
