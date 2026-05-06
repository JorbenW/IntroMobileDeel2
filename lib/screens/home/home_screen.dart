import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/topbar.dart';
import '../../constants/constants.dart';
import '../search/item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategoryFilter;
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(50.8503, 4.3517); // Standaard: Brussel
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Functie om de huidige locatie van de gebruiker te bepalen
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      // Verplaats de camera naar de gebruiker
      _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    }
  }

  // Hulpmiddel om markers te maken op basis van Firebase data en filters
  Set<Marker> _buildMarkers(List<QueryDocumentSnapshot> docs) {
    Set<Marker> markers = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // FILTER LOGICA: Toon alleen als categorie overeenkomt (of als er geen filter is)
      if (_selectedCategoryFilter == null ||
          data['categorie'] == _selectedCategoryFilter) {
        final GeoPoint? geoPoint = data['locatie'] is GeoPoint
            ? data['locatie']
            : null;

        if (geoPoint != null) {
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(geoPoint.latitude, geoPoint.longitude),
              infoWindow: InfoWindow(
                title: data['omschrijving'] ?? 'Toestel',
                snippet: 'Tik hier om te reserveren',
                onTap: () {
                  // Navigeer naar de detail/reservatie pagina
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
            // ZOEKBALK (Bovenaan)
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
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Waar ben je naar op zoek?',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  suffixIcon: Icon(Icons.search, color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CATEGORIE FILTER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    'Filter op categorie',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  value: _selectedCategoryFilter,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.deepPurple,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Alle categorieën'),
                    ),
                    ...kCategories.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (newValue) =>
                      setState(() => _selectedCategoryFilter = newValue),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DE KAART (Vervangt de placeholder)
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
                            myLocationEnabled:
                                true, // Toont de blauwe stip van de gebruiker zelf
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapType: MapType.normal,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // RADIUS KNOP
            ElevatedButton.icon(
              onPressed: () {
                // Toekomstige functie: Radius instellen
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Zoekradius instellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
