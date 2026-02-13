import 'package:collection/collection.dart';
import 'package:metroapp/route_result.dart';

import 'metroStation.dart';
import 'metro_data.dart';

MetroStation? _findStation(String name) {
  for (final line in [line1, line2, line3]) {
    for (final station in line) {
      if (station.name == name) return station;
    }
  }
  return null;
}

final monib_shubra_intersections = {
  'sadat': 0,
  'ataba': 2,
  'al_shohadaa': 0
};

final adly_rod_intersections = {
  'ataba': 1,
  'gamal_abdel_nasser': 0
};

int _calcPrice(int n) =>
    n <= 0 ? 0 : n <= 9 ? 8 : n <= 16 ? 10 : n <= 23 ? 15 : 20;

String _getNameById(List<MetroStation> line, int id) {
  return line.firstWhere((s) => s.id == id).name;
}

List<String> _buildSegment(List<MetroStation> line, int from, int to, {bool skipFirst = false}) {
  final route = <String>[];
  for (int i = from; from > to ? i >= to : i <= to; from > to ? i-- : i++) {
    route.add(_getNameById(line, i));
  }
  if (skipFirst && route.isNotEmpty) route.removeAt(0);
  return route;
}

class MetroRouteService {
  RouteResult? findRoute(String from, String to) {
    final fromInLine1 = line1.firstWhereOrNull((s) => s.name == from);
    final fromInLine2 = line2.firstWhereOrNull((s) => s.name == from);
    final fromInLine3 = line3.firstWhereOrNull((s) => s.name == from);
    final toInLine1 = line1.firstWhereOrNull((s) => s.name == to);
    final toInLine2 = line2.firstWhereOrNull((s) => s.name == to);
    final toInLine3 = line3.firstWhereOrNull((s) => s.name == to);

    // check if stations exist at all
    if (fromInLine1 == null && fromInLine2 == null && fromInLine3 == null) {
      return null;
    }
    if (toInLine1 == null && toInLine2 == null && toInLine3 == null) {
      return null;
    }

    // ================= LINE 1 → LINE 1 =================
    if (fromInLine1 != null && toInLine1 != null) {
      final int c = fromInLine1.id;
      final int b = toInLine1.id;
      final int n = (c - b).abs();
      final String direction = c > b ? 'Helwan' : 'New El-Marg';
      final route = _buildSegment(line1, c, b);

      return RouteResult(
        stations: n,
        price: _calcPrice(n),
        time: n * 2,
        route: route,
        direction1: direction,
        direction2: null,
        intersection: null,
      );
    }

    // ================= LINE 1 → LINE 2 =================
    else if (fromInLine1 != null && toInLine2 != null) {
      final int c = fromInLine1.id;

      String? nearest;
      int min = 1 << 30;

      for (final stationName in getKeysByValue(monib_shubra_intersections, 0)) {
        final stationInLine1 = line1.firstWhereOrNull((s) => s.name == stationName);
        if (stationInLine1 == null) continue;
        final d = (c - stationInLine1.id).abs();
        if (d < min) {
          min = d;
          nearest = stationName;
        }
      }

      if (nearest == null) return null;

      final int b = line1.firstWhere((s) => s.name == nearest).id;
      final String direction1 = c > b ? 'Helwan' : 'New El-Marg';

      final int c2 = line2.firstWhere((s) => s.name == nearest).id;
      final int b2 = toInLine2.id;
      final String direction2 = c2 > b2 ? 'El Munib' : 'Shubra';

      final int part1 = (c - b).abs();
      final int part2 = (c2 - b2).abs();
      final int all = part1 + part2;

      final route = _buildSegment(line1, c, b);
      route.addAll(_buildSegment(line2, c2, b2, skipFirst: true));

      return RouteResult(
        stations: all,
        price: _calcPrice(all),
        time: all * 2,
        route: route,
        direction1: direction1,
        direction2: direction2,
        intersection: nearest,
      );
    }

    // ================= LINE 1 → LINE 3 =================
    else if (fromInLine1 != null && toInLine3 != null) {
      final int c = fromInLine1.id;

      String? nearest;
      int min = 1 << 30;

      for (final stationName in getKeysByValue(adly_rod_intersections, 0)) {
        final stationInLine1 = line1.firstWhereOrNull((s) => s.name == stationName);
        if (stationInLine1 == null) continue;
        final d = (c - stationInLine1.id).abs();
        if (d < min) {
          min = d;
          nearest = stationName;
        }
      }

      if (nearest == null) return null;

      final int b = line1.firstWhere((s) => s.name == nearest).id;
      final String direction1 = c > b ? 'Helwan' : 'New El-Marg';

      final int c2 = line3.firstWhere((s) => s.name == nearest).id;
      final int b2 = toInLine3.id;
      final String direction2 = c2 > b2 ? 'Adly Mansour' : 'Rod El Farag Corridor';

      final int part1 = (c - b).abs();
      final int part2 = (c2 - b2).abs();
      final int all = part1 + part2;

      final route = _buildSegment(line1, c, b);
      route.addAll(_buildSegment(line3, c2, b2, skipFirst: true));

      return RouteResult(
        stations: all,
        price: _calcPrice(all),
        time: all * 2,
        route: route,
        direction1: direction1,
        direction2: direction2,
        intersection: nearest,
      );
    }

    // ================= LINE 2 → LINE 2 =================
    else if (fromInLine2 != null && toInLine2 != null) {
      final int c = fromInLine2.id;
      final int b = toInLine2.id;
      final int n = (c - b).abs();
      final String direction = c > b ? 'El Munib' : 'Shubra';
      final route = _buildSegment(line2, c, b);

      return RouteResult(
        stations: n,
        price: _calcPrice(n),
        time: n * 2,
        route: route,
        direction1: direction,
        direction2: null,
        intersection: null,
      );
    }

    // ================= LINE 2 → LINE 1 =================
    else if (fromInLine2 != null && toInLine1 != null) {
      final int c = fromInLine2.id;

      String? nearest;
      int min = 1 << 30;

      for (final stationName in getKeysByValue(monib_shubra_intersections, 0)) {
        final stationInLine2 = line2.firstWhereOrNull((s) => s.name == stationName);
        if (stationInLine2 == null) continue;
        final d = (c - stationInLine2.id).abs();
        if (d < min) {
          min = d;
          nearest = stationName;
        }
      }

      if (nearest == null) return null;

      final int b = line2.firstWhere((s) => s.name == nearest).id;
      final String direction1 = c > b ? 'El Munib' : 'Shubra';

      final int c2 = line1.firstWhere((s) => s.name == nearest).id;
      final int b2 = toInLine1.id;
      final String direction2 = c2 > b2 ? 'Helwan' : 'New El-Marg';

      final int part1 = (c - b).abs();
      final int part2 = (c2 - b2).abs();
      final int all = part1 + part2;

      final route = _buildSegment(line2, c, b);
      route.addAll(_buildSegment(line1, c2, b2, skipFirst: true));

      return RouteResult(
        stations: all,
        price: _calcPrice(all),
        time: all * 2,
        route: route,
        direction1: direction1,
        direction2: direction2,
        intersection: nearest,
      );
    }

    // ================= LINE 2 → LINE 3 =================
    else if (fromInLine2 != null && toInLine3 != null) {
      final int c = fromInLine2.id;

      String? nearest;
      int min = 1 << 30;

      for (final stationName in getKeysByValue(adly_rod_intersections, 1)) {
        final stationInLine2 = line2.firstWhereOrNull((s) => s.name == stationName);
        if (stationInLine2 == null) continue;
        final d = (c - stationInLine2.id).abs();
        if (d < min) {
          min = d;
          nearest = stationName;
        }
      }

      if (nearest == null) return null;

      final int b = line2.firstWhere((s) => s.name == nearest).id;
      final String direction1 = c > b ? 'El Munib' : 'Shubra';

      final int c2 = line3.firstWhere((s) => s.name == nearest).id;
      final int b2 = toInLine3.id;
      final String direction2 = c2 > b2 ? 'Adly Mansour' : 'Rod El Farag Corridor';

      final int part1 = (c - b).abs();
      final int part2 = (c2 - b2).abs();
      final int all = part1 + part2;

      final route = _buildSegment(line2, c, b);
      route.addAll(_buildSegment(line3, c2, b2, skipFirst: true));

      return RouteResult(
        stations: all,
        price: _calcPrice(all),
        time: all * 2,
        route: route,
        direction1: direction1,
        direction2: direction2,
        intersection: nearest,
      );
    }

    // ================= LINE 3 → LINE 3 =================
    else if (fromInLine3 != null && toInLine3 != null) {
      final int c = fromInLine3.id;
      final int b = toInLine3.id;
      final int n = (c - b).abs();
      final String direction = c > b ? 'Adly Mansour' : 'Rod El Farag Corridor';
      final route = _buildSegment(line3, c, b);

      return RouteResult(
        stations: n,
        price: _calcPrice(n),
        time: n * 2,
        route: route,
        direction1: direction,
        direction2: null,
        intersection: null,
      );
    }

    // ================= LINE 3 → LINE 1 =================
    else if (fromInLine3 != null && toInLine1 != null) {
      final int c = fromInLine3.id;

      String? nearest;
      int min = 1 << 30;

      for (final stationName in getKeysByValue(adly_rod_intersections, 0)) {
        final stationInLine3 = line3.firstWhereOrNull((s) => s.name == stationName);
        if (stationInLine3 == null) continue;
        final d = (c - stationInLine3.id).abs();
        if (d < min) {
          min = d;
          nearest = stationName;
        }
      }

      if (nearest == null) return null;

      final int b = line3.firstWhere((s) => s.name == nearest).id;
      final String direction1 = c > b ? 'Adly Mansour' : 'Rod El Farag Corridor';

      final int c2 = line1.firstWhere((s) => s.name == nearest).id;
      final int b2 = toInLine1.id;
      final String direction2 = c2 > b2 ? 'Helwan' : 'New El-Marg';

      final int part1 = (c - b).abs();
      final int part2 = (c2 - b2).abs();
      final int all = part1 + part2;

      final route = _buildSegment(line3, c, b);
      route.addAll(_buildSegment(line1, c2, b2, skipFirst: true));

      return RouteResult(
        stations: all,
        price: _calcPrice(all),
        time: all * 2,
        route: route,
        direction1: direction1,
        direction2: direction2,
        intersection: nearest,
      );
    }

    // ================= LINE 3 → LINE 2 =================
    else if (fromInLine3 != null && toInLine2 != null) {
      final int c = fromInLine3.id;

      String? nearest;
      int min = 1 << 30;

      for (final stationName in getKeysByValue(adly_rod_intersections, 1)) {
        final stationInLine3 = line3.firstWhereOrNull((s) => s.name == stationName);
        if (stationInLine3 == null) continue;
        final d = (c - stationInLine3.id).abs();
        if (d < min) {
          min = d;
          nearest = stationName;
        }
      }

      if (nearest == null) return null;

      final int b = line3.firstWhere((s) => s.name == nearest).id;
      final String direction1 = c > b ? 'Adly Mansour' : 'Rod El Farag Corridor';

      final int c2 = line2.firstWhere((s) => s.name == nearest).id;
      final int b2 = toInLine2.id;
      final String direction2 = c2 > b2 ? 'El Munib' : 'Shubra';

      final int part1 = (c - b).abs();
      final int part2 = (c2 - b2).abs();
      final int all = part1 + part2;

      final route = _buildSegment(line3, c, b);
      route.addAll(_buildSegment(line2, c2, b2, skipFirst: true));

      return RouteResult(
        stations: all,
        price: _calcPrice(all),
        time: all * 2,
        route: route,
        direction1: direction1,
        direction2: direction2,
        intersection: nearest,
      );
    }

    return null;
  }
}

String getKeyByValue(Map<String, int> map, int value) =>
    map.keys.firstWhere((k) => map[k] == value);

List<String> getKeysByValue(Map<String, int> map, int value) =>
    map.entries.where((e) => e.value == value).map((e) => e.key).toList();