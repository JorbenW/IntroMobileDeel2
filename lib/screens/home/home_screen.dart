import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/topbar.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../search/item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(50.8503, 4.3517);
  bool _isLoadingLocation = true;

  // Zoek & Filter Statussen
  String _searchQuery = ""; // NIEUW: Houdt bij wat je intypt
  String? _selectedCategoryFilter;
  double? _maxDistance; // Null betekent: filter staat uit
  double? _maxPrice; // Null betekent: filter staat uit

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    }
  }

  void _openFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialCategory: _selectedCategoryFilter,
        initialDistance: _maxDistance,
        initialPrice: _maxPrice,
        onApply: (category, distance, price) {
          setState(() {
            _selectedCategoryFilter = category;
            _maxDistance = distance;
            _maxPrice = price;
          });
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(List<QueryDocumentSnapshot> docs) {
    Set<Marker> markers = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint? geoPoint = data['locatie'] is GeoPoint
          ? data['locatie']
          : null;
      final double prijs = (data['prijs'] ?? 0.0).toDouble();
      final String omschrijving = (data['omschrijving'] ?? '').toLowerCase();

      if (geoPoint != null) {
        // 1. Check Zoekterm (Tekstveld)
        if (_searchQuery.isNotEmpty &&
            !omschrijving.contains(_searchQuery.toLowerCase()))
          continue;

        // 2. Check Categorie
        if (_selectedCategoryFilter != null &&
            data['categorie'] != _selectedCategoryFilter)
          continue;

        // 3. Check Prijs (Alleen als filter aan staat)
        if (_maxPrice != null && prijs > _maxPrice!) continue;

        // 4. Check Afstand (Alleen als filter aan staat)
        if (_maxDistance != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            _initialPosition.latitude,
            _initialPosition.longitude,
            geoPoint.latitude,
            geoPoint.longitude,
          );
          if (distanceInMeters > _maxDistance! * 1000) continue;
        }

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(
              title: data['omschrijving'] ?? 'Toestel',
              snippet: '€$prijs/dag - Tik om te reserveren',
              onTap: () {
                data['id'] = doc.id;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(itemData: data),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Het zoekveld (Nu open om in te typen)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(
                  () => _searchQuery = val,
                ), // Werkt de zoekterm live bij!
                decoration: InputDecoration(
                  hintText: 'Zoek op naam...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.deepPurple),
                        onPressed: _openFilterMenu,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // De Kaart
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isLoadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('toestellen')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          return GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _initialPosition,
                              zoom: 12,
                            ),
                            onMapCreated: (controller) =>
                                _mapController = controller,
                            markers: _buildMarkers(snapshot.data!.docs),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
