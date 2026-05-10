import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/topbar.dart';
import '../../widgets/pink_button.dart';

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
  late TextEditingController _omschrijvingController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _prijsController;

  String? _selectedCategorie;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _omschrijvingController = TextEditingController(
      text: widget.itemData['omschrijving'],
    );
    _prijsController = TextEditingController(
      text: widget.itemData['prijs'].toString(),
    );
    _selectedCategorie = widget.itemData['categorie'];

    if (widget.itemData['fotoBase64'] != null) {
      _imageBytes = base64Decode(widget.itemData['fotoBase64']);
    }

    // FIX: Haal de GeoPoint veilig uit Firebase
    _latController = TextEditingController();
    _lngController = TextEditingController();
    if (widget.itemData['locatie'] is GeoPoint) {
      GeoPoint gp = widget.itemData['locatie'];
      _latController.text = gp.latitude.toString();
      _lngController.text = gp.longitude.toString();
    }
  }

  Future<void> _updateItem() async {
    setState(() => _isLoading = true);

    double lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    double lng = double.tryParse(_lngController.text.trim()) ?? 0.0;

    await FirebaseFirestore.instance
        .collection('toestellen')
        .doc(widget.docId)
        .update({
          'omschrijving': _omschrijvingController.text,
          'locatie': GeoPoint(lat, lng), // Sla weer netjes op als GeoPoint
          'categorie': _selectedCategorie,
          'prijs': double.tryParse(_prijsController.text) ?? 0.0,
        });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showProfileIcon: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Item Bewerken",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _omschrijvingController,
              decoration: const InputDecoration(labelText: "Omschrijving"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: "Latitude"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: "Longitude"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prijsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: "Prijs"),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PinkButton(text: "OPSLAAN", onPressed: _updateItem),
          ],
        ),
      ),
    );
  }
}
