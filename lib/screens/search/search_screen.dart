import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/topbar.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Position? _currentPosition;

  // Zoek & Filter Statussen
  String _searchQuery = "";
  String? _selectedCategoryFilter;
  double? _maxDistance;
  double? _maxPrice;

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
    if (mounted) setState(() => _currentPosition = position);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Zoek in aanbod...',
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
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('toestellen')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _currentPosition == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Er is momenteel geen aanbod beschikbaar."),
                  );
                }

                // FILTER DE LIJST
                final allItems = snapshot.data!.docs;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                final filteredItems = allItems.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Verberg je eigen toestellen
                  if (data['verhuurderId'] == currentUserId) return false;

                  final GeoPoint? geoPoint = data['locatie'] is GeoPoint
                      ? data['locatie']
                      : null;
                  final double prijs = (data['prijs'] ?? 0.0).toDouble();
                  final String omschrijving = (data['omschrijving'] ?? '')
                      .toLowerCase();

                  if (geoPoint == null) return false;

                  // 1. Zoekterm
                  if (_searchQuery.isNotEmpty &&
                      !omschrijving.contains(_searchQuery.toLowerCase()))
                    return false;
                  // 2. Categorie
                  if (_selectedCategoryFilter != null &&
                      data['categorie'] != _selectedCategoryFilter)
                    return false;
                  // 3. Prijs
                  if (_maxPrice != null && prijs > _maxPrice!) return false;
                  // 4. Afstand
                  if (_maxDistance != null) {
                    double distance = Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      geoPoint.latitude,
                      geoPoint.longitude,
                    );
                    if (distance > _maxDistance! * 1000) return false;
                  }

                  return true;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text("Geen toestellen gevonden met deze filters."),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final itemData =
                        filteredItems[index].data() as Map<String, dynamic>;
                    itemData['id'] = filteredItems[index].id;

                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ItemDetailScreen(itemData: itemData),
                        ),
                      ),
                      child: _buildModernItemCard(itemData),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernItemCard(Map<String, dynamic> itemData) {
    final base64String = itemData['fotoBase64'] ?? '';
    String distanceText = "";
    if (_currentPosition != null && itemData['locatie'] is GeoPoint) {
      GeoPoint gp = itemData['locatie'];
      double distInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        gp.latitude,
        gp.longitude,
      );
      distanceText = "${(distInMeters / 1000).toStringAsFixed(1)} km";
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                color: Colors.grey[200],
                child: base64String.isNotEmpty
                    ? Image.memory(
                        base64Decode(base64String),
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemData['omschrijving'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '€${itemData['prijs']}/dag',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        itemData['categorie'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        distanceText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
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
}
