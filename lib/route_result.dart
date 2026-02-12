  class RouteResult {
    final int stations;
    final int price;
    final int time;
    final List<String> route;
    final String? direction1;
    final String? direction2;
    final String? intersection;

    const RouteResult({
      required this.stations,
      required this.price,
      required this.time,
      required this.route,
      required this.direction1,
      required this.direction2,
      required this.intersection,
  });
  }