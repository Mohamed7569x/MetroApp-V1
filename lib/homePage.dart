import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:metroapp/route_result.dart';
import 'package:url_launcher/url_launcher.dart';
import 'metroStation.dart';
import 'metro_data.dart';
import 'metro_service.dart';

// ─── Color Palette ───────────────────────────────────────────────
class MetroColors {
  static const Color background = Color(0xFF0F1923);
  static const Color surface = Color(0xFF1A2733);
  static const Color surfaceLight = Color(0xFF243442);
  static const Color accent = Color(0xFF00BFA6);
  static const Color accentDim = Color(0xFF007A6A);
  static const Color line1Color = Color(0xFFE53935);
  static const Color line2Color = Color(0xFFFFB300);
  static const Color line3Color = Color(0xFF43A047);
  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color error = Color(0xFFEF5350);
}

class Homepage extends StatelessWidget {
  Homepage({super.key});
  final selectOneController = TextEditingController();
  final selectTwoController = TextEditingController();
  final locationController = TextEditingController();
  final result = Rxn<RouteResult>();
  final isLoading = false.obs;

  final entries = () {
    final allNames = <String>{};
    final list = <DropdownMenuEntry<String>>[];
    for (final line in [line1, line2, line3]) {
      for (final station in line) {
        if (allNames.add(station.name)) {
          list.add(DropdownMenuEntry(value: station.name, label: station.name));
        }
      }
    }
    return list;
  }();

  MetroStation? _getStationWithCoords(String name) {
    for (final line in [line1, line2, line3]) {
      for (final station in line) {
        if (station.name == name) return station;
      }
    }
    return null;
  }

  MetroStation _findNearestStation(double lat, double lng) {
    MetroStation? nearest;
    double minDistance = double.infinity;
    for (final line in [line1, line2, line3]) {
      for (final station in line) {
        final distance = Geolocator.distanceBetween(
          lat, lng, station.lat, station.long,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = station;
        }
      }
    }
    return nearest!;
  }

  Future<void> _handleGetLocation() async {
    isLoading.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Location services are disabled.', isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Location permissions are denied', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackbar('Location permissions are permanently denied',
            isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final nearest = _findNearestStation(pos.latitude, pos.longitude);
      selectOneController.text = nearest.name;
      final uri = Uri.parse('geo:0,0?q=${nearest.lat},${nearest.long}');
      launchUrl(uri);
    } catch (e) {
      _showSnackbar('Failed to get location', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleSubmitAddress() async {
    if (locationController.text.isEmpty) {
      _showSnackbar('Please enter an address', isError: true);
      return;
    }
    isLoading.value = true;
    try {
      final locations = await locationFromAddress(locationController.text);
      if (locations.isEmpty) {
        _showSnackbar('Address not found', isError: true);
        return;
      }
      final loc = locations.first;
      final nearest = _findNearestStation(loc.latitude, loc.longitude);
      selectOneController.text = nearest.name;
      _showSnackbar('Nearest station: ${nearest.name}', isError: false);
    } catch (e) {
      _showSnackbar('Could not find address', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? MetroColors.error.withOpacity(0.9)
          : MetroColors.accent.withOpacity(0.9),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }

  Color _getLineColor(String stationName) {
    for (final station in line1) {
      if (station.name == stationName) return MetroColors.line1Color;
    }
    for (final station in line2) {
      if (station.name == stationName) return MetroColors.line2Color;
    }
    for (final station in line3) {
      if (station.name == stationName) return MetroColors.line3Color;
    }
    return MetroColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MetroColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              _buildSectionLabel('FROM', Icons.trip_origin),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStationDropdown(selectOneController)),
                  const SizedBox(width: 10),
                  _buildIconButton(
                    icon: Icons.map_outlined,
                    onPressed: () {
                      if (selectOneController.text.isEmpty) {
                        _showSnackbar('Please select a station first',
                            isError: true);
                        return;
                      }
                      final station =
                      _getStationWithCoords(selectOneController.text);
                      if (station != null) {
                        final uri = Uri.parse(
                            'geo:0,0?q=${station.lat},${station.long}');
                        launchUrl(uri);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionLabel('TO', Icons.location_on_outlined),
              const SizedBox(height: 8),
              _buildStationDropdown(selectTwoController),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildPrimaryButton(
                      label: 'Find Route',
                      icon: Icons.route,
                      onPressed: () {
                        if (selectOneController.text.isNotEmpty &&
                            selectTwoController.text.isNotEmpty) {
                          result.value = MetroRouteService().findRoute(
                              selectOneController.text,
                              selectTwoController.text);
                          if (result.value == null) {
                            _showSnackbar('Route not found', isError: true);
                          }
                        } else {
                          _showSnackbar('Please select both stations',
                              isError: true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildSecondaryButton(
                      label: 'Nearest',
                      icon: Icons.my_location,
                      onPressed: () => _handleGetLocation(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Obx(() {
                final r = result.value;
                if (r == null) return const SizedBox();
                return _buildRouteResult(r);
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: MetroColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: locationController,
                style: const TextStyle(
                    color: MetroColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter address to find nearest station...',
                  hintStyle: TextStyle(
                      color: MetroColors.textSecondary.withOpacity(0.6),
                      fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: MetroColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: MetroColors.surfaceLight,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: MetroColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MetroColors.accent, MetroColors.accentDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleSubmitAddress(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child:
                    Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widget Builders ──────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MetroColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.subway_rounded,
              color: MetroColors.accent, size: 28),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cairo Metro',
              style: TextStyle(
                color: MetroColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Plan your route',
              style: TextStyle(
                color: MetroColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: MetroColors.accent, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: MetroColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStationDropdown(TextEditingController controller) {
    return Theme(
      data: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: MetroColors.surface,
          onSurface: MetroColors.textPrimary,
          primary: MetroColors.accent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: MetroColors.textPrimary),
        ),
      ),
      child: DropdownMenu<String>(
        hintText: 'Select station',
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        menuHeight: 220,
        width: double.infinity,
        controller: controller,
        textStyle: const TextStyle(
          color: MetroColors.textPrimary,
          fontSize: 15,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(MetroColors.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          elevation: const WidgetStatePropertyAll(8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MetroColors.surfaceLight,
          hintStyle: TextStyle(
            color: MetroColors.textSecondary.withOpacity(0.5),
            fontSize: 15,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: MetroColors.accent, width: 1.5),
          ),
        ),
        dropdownMenuEntries: entries,
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: MetroColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: MetroColors.accent, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
      {required String label,
        required IconData icon,
        required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MetroColors.accent, MetroColors.accentDim],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: MetroColors.accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      {required String label,
        required IconData icon,
        required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: MetroColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MetroColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: MetroColors.accent, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: MetroColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteResult(RouteResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MetroColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: MetroColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Stats Row ─────────────────────────
          Row(
            children: [
              _buildStatChip(Icons.linear_scale, '${r.stations}', 'Stations'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.payments_outlined, '${r.price}', 'EGP'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.schedule, '${r.time}', 'Mins'),
            ],
          ),
          const SizedBox(height: 18),

          // ─── Direction Info ────────────────────
          if (r.direction1 != null) ...[
            _buildInfoRow(Icons.arrow_forward, 'Direction', r.direction1!),
            const SizedBox(height: 8),
          ],
          if (r.intersection != null) ...[
            _buildInfoRow(Icons.swap_horiz, 'Transfer at', r.intersection!),
            const SizedBox(height: 8),
          ],
          if (r.direction2 != null) ...[
            _buildInfoRow(Icons.arrow_forward, 'After transfer', r.direction2!),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 14),
          const Divider(color: MetroColors.surfaceLight, height: 1),
          const SizedBox(height: 14),

          // ─── Route Stations ────────────────────
          const Text(
            'ROUTE',
            style: TextStyle(
              color: MetroColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(r.route.length, (i) {
            final stationName = r.route[i];
            final isFirst = i == 0;
            final isLast = i == r.route.length - 1;
            final isTransfer = stationName == r.intersection;
            final color = _getLineColor(stationName);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Container(
                        width: isFirst || isLast || isTransfer ? 14 : 8,
                        height: isFirst || isLast || isTransfer ? 14 : 8,
                        decoration: BoxDecoration(
                          color: isTransfer
                              ? Colors.white
                              : isFirst || isLast
                              ? color
                              : Colors.transparent,
                          border: Border.all(color: color, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 28,
                          color: color.withOpacity(0.4),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          stationName,
                          style: TextStyle(
                            color: isFirst || isLast || isTransfer
                                ? MetroColors.textPrimary
                                : MetroColors.textSecondary,
                            fontSize:
                            isFirst || isLast || isTransfer ? 14 : 13,
                            fontWeight: isFirst || isLast || isTransfer
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (isTransfer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: MetroColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TRANSFER',
                              style: TextStyle(
                                color: MetroColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: MetroColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: MetroColors.accent, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: MetroColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: MetroColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: MetroColors.accent, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: MetroColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: MetroColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}