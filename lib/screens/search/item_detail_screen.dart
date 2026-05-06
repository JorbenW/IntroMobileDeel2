import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/pink_button.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({super.key, required this.itemData});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingStart = true;
  final _messageController = TextEditingController();
  bool _isRequesting = false;

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitRequest() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecteer zowel een start- als einddatum.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isRequesting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('aanvragen').add({
        'toestelId': widget.itemData['id'],
        'toestelNaam': widget.itemData['omschrijving'],
        'fotoBase64': widget.itemData['fotoBase64'],
        'verhuurderId': widget.itemData['verhuurderId'],
        'huurderId': user?.uid,
        'huurderNaam': user?.displayName ?? 'Onbekend',
        'startDatum': _formatDate(_startDate),
        'eindDatum': _formatDate(_endDate),
        'bericht': _messageController.text.trim(),
        'status': 'In afwachting',
        'aangevraagdOp': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aanvraag verstuurd!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij aanvragen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base64String = widget.itemData['fotoBase64'] ?? '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: const Text("Details & Reserveren")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                color: Colors.grey[200],
                child: base64String.isNotEmpty
                    ? Image.memory(
                        base64Decode(base64String),
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.itemData['omschrijving'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '€${widget.itemData['prijs']} per dag',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(height: 40),
            const Text(
              "Huurperiode selecteren",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Simpele weergave van geselecteerde datums
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Van: ${_formatDate(_startDate)}"),
                Text("Tot: ${_formatDate(_endDate)}"),
              ],
            ),

            CalendarDatePicker(
              initialDate: today,
              firstDate: today,
              lastDate: today.add(const Duration(days: 365)),
              onDateChanged: (date) {
                setState(() {
                  if (_selectingStart) {
                    _startDate = date;
                    _selectingStart = false;
                  } else {
                    _endDate = date;
                    _selectingStart = true;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Bericht voor verhuurder",
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _isRequesting
                ? const Center(child: CircularProgressIndicator())
                : PinkButton(
                    text: 'RESERVERING AANVRAGEN',
                    onPressed: _submitRequest,
                    icon: Icons.send,
                  ),
          ],
        ),
      ),
    );
  }
}
