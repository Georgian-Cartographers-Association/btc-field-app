import 'dart:math' as math;

/// WGS84 → UTM Zone 38N (EPSG:32638)
/// Central meridian 45°E · False easting 500 000 m · Scale 0.9996
class UtmService {
  UtmService._();

  static const double _a   = 6378137.0;
  static const double _f   = 1.0 / 298.257223563;
  static const double _k0  = 0.9996;
  static const double _e0  = 500000.0;
  static const double _lon0 = 45.0 * math.pi / 180.0;

  static final double _e2       = 2 * _f - _f * _f;
  static final double _ePrime2  = _e2 / (1.0 - _e2);

  static UtmCoord toUtm38N(double latDeg, double lonDeg) {
    final lat    = latDeg * math.pi / 180.0;
    final lon    = lonDeg * math.pi / 180.0;
    final sinLat = math.sin(lat);
    final cosLat = math.cos(lat);
    final tanLat = math.tan(lat);
    final t      = tanLat * tanLat;
    final c      = _ePrime2 * cosLat * cosLat;
    final nu     = _a / math.sqrt(1.0 - _e2 * sinLat * sinLat);
    final A      = cosLat * (lon - _lon0);
    final A2 = A*A; final A3 = A2*A; final A4 = A3*A; final A5 = A4*A; final A6 = A5*A;
    final e2 = _e2; final e4 = e2*e2; final e6 = e4*e2;
    final M = _a * (
        (1 - e2/4 - 3*e4/64 - 5*e6/256)          * lat
      - (3*e2/8 + 3*e4/32 - 45*e6/1024)           * math.sin(2*lat)
      + (15*e4/256 + 45*e6/1024)                  * math.sin(4*lat)
      - (35*e6/3072)                               * math.sin(6*lat)
    );
    final easting = _k0 * nu * (
        A
      + (1 - t + c)                                * A3 / 6.0
      + (5 - 18*t + t*t + 72*c - 58*_ePrime2)     * A5 / 120.0
    ) + _e0;
    final northing = _k0 * (
        M + nu * tanLat * (
            A2 / 2.0
          + (5 - t + 9*c + 4*c*c)                  * A4 / 24.0
          + (61 - 58*t + t*t + 600*c - 330*_ePrime2) * A6 / 720.0
        )
    );
    return UtmCoord(easting: easting, northing: northing);
  }
}

class UtmCoord {
  const UtmCoord({required this.easting, required this.northing});
  final double easting;
  final double northing;

  String formatted() => 'E ${_fmt(easting)}   N ${_fmt(northing)}';

  static String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    final parts = s.split('.');
    final buf = StringBuffer();
    final intStr = parts[0];
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
      buf.write(intStr[i]);
    }
    return '${buf.toString()}.${parts[1]}';
  }

  @override
  String toString() => formatted();
}
