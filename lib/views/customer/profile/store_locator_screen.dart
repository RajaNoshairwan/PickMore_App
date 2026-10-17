import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/launchers.dart';
import '../../../viewmodels/customer/profile_viewmodel.dart';

class StoreLocatorScreen extends StatelessWidget {
  const StoreLocatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final store = vm.store;

    if (store == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasCoords = store.storeLat != 0 && store.storeLng != 0;
    final target = LatLng(store.storeLat, store.storeLng);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Store location')),
      body: Column(
        children: [
          // Map
          Expanded(
            child: hasCoords
                ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: target,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('store'),
                  position: target,
                  infoWindow: InfoWindow(
                    title: 'Pick More',
                    snippet: store.storeAddress,
                  ),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            )
                : Container(
              color: AppColors.divider,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Store location not set.\nPlease add coordinates from the admin panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
              ),
            ),
          ),

          // Info card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pick More',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _row(Icons.location_on_outlined, store.storeAddress),
                const SizedBox(height: 8),
                _row(Icons.access_time, store.openingHours),
                const SizedBox(height: 8),
                _row(Icons.call_outlined, store.phoneNumber),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (hasCoords) {
                            Launchers.map(store.storeLat, store.storeLng);
                          }
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Open in Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (store.phoneNumber.isNotEmpty) {
                            Launchers.call(store.phoneNumber);
                          }
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}