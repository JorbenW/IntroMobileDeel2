import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/topbar.dart';
import '../../widgets/pink_button.dart';
import '../../constants/constants.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _omschrijvingController = TextEditingController();
  final _locatieController = TextEditingController();
  final _prijsController = TextEditingController();

  String? _selectedCategorie;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _uploadItem() async {
    if (_imageBytes == null ||
        _omschrijvingController.text.isEmpty ||
        _locatieController.text.isEmpty ||
        _selectedCategorie == null ||
        _prijsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vul alle velden in en kies een foto!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String base64Image = base64Encode(_imageBytes!);
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'Onbekend';

      await FirebaseFirestore.instance.collection('toestellen').add({
        'omschrijving': _omschrijvingController.text.trim(),
        'locatie': _locatieController.text.trim(),
        'categorie': _selectedCategorie,
        'prijs': double.tryParse(_prijsController.text.trim()) ?? 0.0,
        'fotoBase64': base64Image,
        'verhuurderId': userId,
        'beschikbaar': true,
        'toegevoegdOp': Timestamp.now(),
      });

      setState(() {
        _imageBytes = null;
        _omschrijvingController.clear();
        _locatieController.clear();
        _selectedCategorie = null;
        _prijsController.clear();
        _isUploading = false;
      });

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toestel succesvol toegevoegd!'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Er is iets misgegaan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nieuw Toestel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.deepPurple.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_imageBytes!),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 50,
                            color: Colors.black54,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tik om foto toe te voegen',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInputRow('Omschrijving', Icons.edit, _omschrijvingController),
            _buildInputRow('Locatie', Icons.location_city, _locatieController),
            _buildDropdown(),
            _buildInputRow(
              'Prijs per dag (€)',
              Icons.euro,
              _prijsController,
              isNumber: true,
            ),
            const SizedBox(height: 32),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : PinkButton(
                    text: 'TOEVOEGEN',
                    onPressed: _uploadItem,
                    icon: Icons.check_circle_outline,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedCategorie,
        decoration: InputDecoration(
          labelText: 'Categorie',
          prefixIcon: const Icon(Icons.category, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items: kCategories
            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
            .toList(),
        onChanged: (val) => setState(() => _selectedCategorie = val),
      ),
    );
  }
}
