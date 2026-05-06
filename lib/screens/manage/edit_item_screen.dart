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
  late TextEditingController _locatieController;
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
    _locatieController = TextEditingController(
      text: widget.itemData['locatie'],
    );
    _prijsController = TextEditingController(
      text: widget.itemData['prijs'].toString(),
    );
    _selectedCategorie = widget.itemData['categorie'];
    if (widget.itemData['fotoBase64'] != null)
      _imageBytes = base64Decode(widget.itemData['fotoBase64']);
  }

  Future<void> _updateItem() async {
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance
        .collection('toestellen')
        .doc(widget.docId)
        .update({
          'omschrijving': _omschrijvingController.text,
          'locatie': _locatieController.text,
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
            TextField(
              controller: _locatieController,
              decoration: const InputDecoration(labelText: "Locatie"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : PinkButton(text: "OPSLAAN", onPressed: _updateItem),
          ],
        ),
      ),
    );
  }
}
