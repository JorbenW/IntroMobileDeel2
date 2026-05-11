import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/topbar.dart';
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
  late TextEditingController _omschrijvingController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _prijsController;

  String? _selectedCategorie;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  // NIEUW: De geselecteerde dagen
  List<String> _selectedDays = [];

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

    _latController = TextEditingController();
    _lngController = TextEditingController();
    if (widget.itemData['locatie'] is GeoPoint) {
      GeoPoint gp = widget.itemData['locatie'];
      _latController.text = gp.latitude.toString();
      _lngController.text = gp.longitude.toString();
    }

    // NIEUW: Lees de dagen uit. Zijn het er geen? Dan gaan we er vanuit dat hij altijd beschikbaar is (terugwerkende kracht)
    if (widget.itemData['beschikbareDagen'] != null) {
      _selectedDays = List<String>.from(widget.itemData['beschikbareDagen']);
    } else {
      _selectedDays = List.from(kDaysOfWeek);
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
          'locatie': GeoPoint(lat, lng),
          'categorie': _selectedCategorie,
          'prijs': double.tryParse(_prijsController.text) ?? 0.0,
          'beschikbareDagen': _selectedDays, // NIEUW: Update in Firebase
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

            // NIEUW: De Selectie UI
            const SizedBox(height: 24),
            const Text(
              'Beschikbare Dagen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: kDaysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.purple[100],
                  checkmarkColor: Colors.deepPurple,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
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
