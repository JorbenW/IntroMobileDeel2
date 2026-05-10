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
                  _buildAanvragenTab(),
                  _buildStatusTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: MIJN AANBOD ---
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
                  itemData['omschrijving'] ?? 'Toestel',
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

  // --- TAB 2: AANVRAGEN (Die jij ontvangt) ---
  Widget _buildAanvragenTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Niet ingelogd"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('aanvragen')
          .where('verhuurderId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'In afwachting')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(
            child: Text("Je hebt geen openstaande aanvragen."),
          );

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final reqData = requests[index].data() as Map<String, dynamic>;
            reqData['id'] = requests[index].id;
            return _buildRequestCard(context, reqData, isOwner: true);
          },
        );
      },
    );
  }

  // --- TAB 3: STATUS (Wat jij hebt aangevraagd) ---
  Widget _buildStatusTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Niet ingelogd"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('aanvragen')
          .where('huurderId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("Je hebt nog niets aangevraagd."));

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final reqData = requests[index].data() as Map<String, dynamic>;
            reqData['id'] = requests[index].id;
            return _buildRequestCard(context, reqData, isOwner: false);
          },
        );
      },
    );
  }

  // --- DE REQUEST CARD ---
  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> reqData, {
    required bool isOwner,
  }) {
    final base64String = reqData['fotoBase64'] ?? '';
    final status = reqData['status'] ?? 'Onbekend';

    Color statusColor = Colors.orange;
    if (status == 'Goedgekeurd') statusColor = Colors.green;
    if (status == 'Geweigerd') statusColor = Colors.red;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: base64String.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.memory(
                      base64Decode(base64String),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reqData['toestelNaam'] ?? 'Toestel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Huurder: ${reqData['huurderNaam']}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  "Periode: ${reqData['startDatum']} - ${reqData['eindDatum']}",
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((reqData['bericht'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Bericht: ${reqData['bericht']}",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 16),

                if (isOwner)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(reqData['id'], 'Goedgekeurd'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                "ACCEPTEREN",
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(reqData['id'], 'Geweigerd'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                "WEIGEREN",
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            _showDeclineReasonDialog(context, reqData['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Weigeren met reden'),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Center(
                          child: Text(
                            "STATUS: ${status.toUpperCase()}",
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      if (status == 'Geweigerd' &&
                          (reqData['weigerReden'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Reden: ${reqData['weigerReden']}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    String docId,
    String newStatus, {
    String? reason,
  }) async {
    await FirebaseFirestore.instance.collection('aanvragen').doc(docId).update({
      'status': newStatus,
      if (reason != null) 'weigerReden': reason,
    });
  }

  void _showDeclineReasonDialog(BuildContext context, String docId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Reden voor weigering',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: 'Typ hier de reden...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                _updateStatus(
                  docId,
                  'Geweigerd',
                  reason: reasonController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Weigeren'),
          ),
        ],
      ),
    );
  }
}
