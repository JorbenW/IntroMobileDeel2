import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // NIEUW
import 'package:flutter/gestures.dart'; // NIEUW
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_intro_mobile/screens/bottom_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/pink_button.dart';
import '../../constants/constants.dart';

class EditItemScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> itemData;

  const EditItemScreen({
    super.key,
    required this.docId,
    required this.itemData,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _omschrijvingController;
  late TextEditingController _prijsController;

  String? _selectedCategory;
  String? _base64Image;
  bool _isSaving = false;

  final List<String> _alleDagen = [
    'Maandag',
    'Dinsdag',
    'Woensdag',
    'Donderdag',
    'Vrijdag',
    'Zaterdag',
    'Zondag',
  ];
  List<String> _geselecteerdeDagen = [];

  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _omschrijvingController = TextEditingController(
      text: widget.itemData['omschrijving'],
    );
    _prijsController = TextEditingController(
      text: widget.itemData['prijs'].toString(),
    );
    _selectedCategory = widget.itemData['categorie'];
    _base64Image = widget.itemData['fotoBase64'];
    _geselecteerdeDagen = List<String>.from(
      widget.itemData['beschikbareDagen'] ?? [],
    );

    final GeoPoint? gp = widget.itemData['locatie'];
    if (gp != null) _currentLocation = LatLng(gp.latitude, gp.longitude);
  }

  Future<void> _kiesNieuweFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() => _base64Image = base64Encode(bytes));
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate() || _geselecteerdeDagen.isEmpty)
      return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('toestellen')
          .doc(widget.docId)
          .update({
            'omschrijving': _omschrijvingController.text.trim(),
            'prijs': double.parse(_prijsController.text.trim()),
            'categorie': _selectedCategory,
            'beschikbareDagen': _geselecteerdeDagen,
            'fotoBase64': _base64Image,
            'locatie': GeoPoint(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
            ),
          });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bewerken')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_base64Image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(_base64Image!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              TextButton.icon(
                onPressed: _kiesNieuweFoto,
                icon: const Icon(Icons.edit),
                label: const Text("WIJZIG FOTO"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _omschrijvingController,
                decoration: const InputDecoration(labelText: 'Naam'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prijsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prijs'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: kCategories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 24),
              const Text(
                "Locatie aanpassen",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_currentLocation != null)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                    // CRUCIALE FIX:
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('p'),
                        position: _currentLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet,
                        ),
                      ),
                    },
                    onTap: (pos) => setState(() => _currentLocation = pos),
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: _alleDagen
                    .map(
                      (dag) => FilterChip(
                        label: Text(dag),
                        selected: _geselecteerdeDagen.contains(dag),
                        onSelected: (s) => setState(
                          () => s
                              ? _geselecteerdeDagen.add(dag)
                              : _geselecteerdeDagen.remove(dag),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : PinkButton(text: 'OPSLAAN', onPressed: _updateItem),
            ],
          ),
        ),
      ),
    );
  }
}
