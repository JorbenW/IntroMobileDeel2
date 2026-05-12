import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_intro_mobile/screens/bottom_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/pink_button.dart';
import '../../constants/constants.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _omschrijvingController = TextEditingController();
  final _prijsController = TextEditingController();

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
  final List<String> _geselecteerdeDagen = [];

  GoogleMapController? _mapController;
  LatLng? _initialPosition;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _geselecteerdeDagen.addAll(_alleDagen);
    _haalHuidigeLocatieOp();
  }

  Future<void> _haalHuidigeLocatieOp() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _selectedLocation = _initialPosition;
      });
    }
  }

  Future<void> _kiesFoto() async {
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

  Future<void> _opslaan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Image == null ||
        _selectedCategory == null ||
        _geselecteerdeDagen.isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vul alle velden in inclusief foto en locatie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // We wachten braaf tot Firebase klaar is
      await FirebaseFirestore.instance.collection('toestellen').add({
        'omschrijving': _omschrijvingController.text.trim(),
        'prijs': double.parse(_prijsController.text.trim()),
        'categorie': _selectedCategory,
        'beschikbareDagen': _geselecteerdeDagen,
        'fotoBase64': _base64Image,
        'verhuurderId': user?.uid,
        'locatie': GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
        'aangemaaktOp': Timestamp.now(),
      });

      // Dit is de levensreddende check: bestaat dit scherm nog in de app?
      if (!mounted) return;

      // Toon eerst de melding, en pop daarna pas het scherm.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toestel succesvol toegevoegd aan je aanbod!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Kleine adempauze voor de UI om af te bouwen
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij opslaan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nieuw Toestel')),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _kiesFoto,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _base64Image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(_base64Image!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _omschrijvingController,
                      decoration: const InputDecoration(
                        labelText: 'Naam / Omschrijving',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Vul een naam in' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prijsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prijs per dag',
                        prefixText: '€ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Vul een prijs in'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: kCategories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                      decoration: const InputDecoration(
                        labelText: 'Categorie',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Locatie (Beweeg de kaart en tik)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepPurple, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition!,
                          zoom: 14,
                        ),
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                        markers: {
                          Marker(
                            markerId: const MarkerId('pin'),
                            position: _selectedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueViolet,
                            ),
                          ),
                        },
                        onTap: (pos) => setState(() => _selectedLocation = pos),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Beschikbare Dagen",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _alleDagen
                          .map(
                            (dag) => FilterChip(
                              label: Text(dag),
                              selected: _geselecteerdeDagen.contains(dag),
                              onSelected: (selected) => setState(
                                () => selected
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
                        : PinkButton(
                            text: 'TOESTEL TOEVOEGEN',
                            onPressed: _opslaan,
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
