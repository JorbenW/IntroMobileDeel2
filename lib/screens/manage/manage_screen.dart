import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/topbar.dart';
import 'edit_item_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                tabs: [
                  Tab(text: 'Mijn Aanbod'),
                  Tab(text: 'Aanvragen'),
                  Tab(text: 'Status'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMyItemsTab(context),
                  const Center(
                    child: Text("Hier komen aanvragen"),
                  ), // Voor nu versimpeld
                  const Center(child: Text("Hier komt status")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyItemsTab(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Niet ingelogd"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('toestellen')
          .where('verhuurderId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("Geen toestellen gevonden."));

        final items = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.55,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemData = items[index].data() as Map<String, dynamic>;
            itemData['id'] = items[index].id;
            return _buildManageCard(context, itemData);
          },
        );
      },
    );
  }

  Widget _buildManageCard(BuildContext context, Map<String, dynamic> itemData) {
    final base64String = itemData['fotoBase64'] ?? '';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: base64String.isNotEmpty
                  ? Image.memory(base64Decode(base64String), fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  itemData['omschrijving'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => EditItemScreen(
                        docId: itemData['id'],
                        itemData: itemData,
                      ),
                    ),
                  ),
                  child: const Text("BEWERK"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
