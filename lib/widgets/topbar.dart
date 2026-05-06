import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/start_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showProfileIcon;

  const CustomAppBar({super.key, this.showProfileIcon = true});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Gebruiker";

    return AppBar(
      centerTitle: false,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Handy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(width: 6),
          Icon(Icons.stars, size: 24),
          SizedBox(width: 6),
          Text('Renting', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        if (showProfileIcon && user != null) ...[
          Center(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uitloggen', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Weet je zeker dat je wilt uitloggen?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD878CA), 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const StartScreen()), (r) => false);
              }
            },
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}