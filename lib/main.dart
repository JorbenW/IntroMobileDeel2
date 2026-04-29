import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

const List<String> kCategories = [
  'Gereedschap',
  'Tuin',
  'Keuken',
  'Schoonmaak',
  'Elektronica',
  'Feest & Evenementen',
  'Overig'
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandyRenting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: const Color(0xFFD878CA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const StartScreen(),
    );
  }
}

// ==========================================
// HERBRUIKBARE WIDGETS
// ==========================================

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

class AuthTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hintText,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            widget.isPassword ? Icons.lock_outline : Icons.person_outline, 
            color: Colors.grey[600]
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.deepPurple, width: 2)),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class PinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const PinkButton({super.key, required this.text, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD878CA),
        foregroundColor: Colors.white,
        elevation: 2,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
        ],
      ),
    );
  }
}

// ==========================================
// SCHERM: STARTSCHERM
// ==========================================
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Color(0xFF9C27B0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Handy', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black87)),
                      SizedBox(width: 8),
                      Icon(Icons.stars, color: Color(0xFFD878CA), size: 35),
                      SizedBox(width: 8),
                      Text('Renting', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                PinkButton(text: 'INLOGGEN', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()))),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('REGISTREREN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SCHERM: INLOGGEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const MainNavigation()), (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Fout bij inloggen');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showProfileIcon: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Welkom terug!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 30),
                AuthTextField(
                  hintText: 'E-mailadres',
                  controller: _emailController,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Voer een geldig e-mailadres in' : null,
                ),
                AuthTextField(
                  hintText: 'Wachtwoord',
                  isPassword: true,
                  controller: _passwordController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Voer je wachtwoord in' : null,
                ),
                const SizedBox(height: 30),
                _isLoading ? const CircularProgressIndicator() : PinkButton(text: 'INLOGGEN', onPressed: _login),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SCHERM: REGISTREREN
// ==========================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await uc.user?.updateDisplayName(_usernameController.text);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const MainNavigation()), (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Fout bij registratie');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showProfileIcon: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Nieuw Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 30),
                AuthTextField(hintText: 'Gebruikersnaam', controller: _usernameController, validator: (v) => (v == null || v.isEmpty) ? 'Vul een naam in' : null),
                AuthTextField(hintText: 'E-mailadres', controller: _emailController, validator: (v) => (v == null || !v.contains('@')) ? 'Ongeldig e-mailadres' : null),
                AuthTextField(
                  hintText: 'Wachtwoord',
                  isPassword: true,
                  controller: _passwordController,
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Minimaal 6 tekens';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'Moet een cijfer bevatten';
                    if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Moet een speciaal teken bevatten';
                    return null;
                  },
                ),
                AuthTextField(
                  hintText: 'Bevestig Wachtwoord',
                  isPassword: true,
                  controller: _confirmPasswordController,
                  validator: (v) => (v != _passwordController.text) ? 'Wachtwoorden komen niet overeen' : null,
                ),
                const SizedBox(height: 30),
                _isLoading ? const CircularProgressIndicator() : PinkButton(text: 'REGISTREREN', onPressed: _register),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOOFDAPP NAVIGATIE
// ==========================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const SearchScreen(), const AddItemScreen(), const ManageScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Colors.purple[100],
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Aanbod'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Toevoegen'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Beheer'),
        ],
      ),
    );
  }
}

// ==========================================
// SCHERM: HOME
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Waar ben je naar op zoek?', 
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
                  suffixIcon: Icon(Icons.search, color: Colors.deepPurple)
                )
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Filter op categorie', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: _selectedCategoryFilter,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.deepPurple),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Alle categorieën')),
                    ...kCategories.map((String cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))),
                  ],
                  onChanged: (newValue) => setState(() => _selectedCategoryFilter = newValue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Container(
                width: double.infinity, 
                decoration: BoxDecoration(
                  color: Colors.grey[200], 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!)
                ), 
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Kaartweergave', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18))
                  ],
                )
              )
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.location_on),
              label: const Text('Zoekradius instellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCHERM: AANBOD ZOEKEN
// ==========================================
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('toestellen').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Er is momenteel geen aanbod beschikbaar."));

          final items = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final itemData = items[index].data() as Map<String, dynamic>;
              itemData['id'] = items[index].id; 
              
              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(itemData: itemData)
                  ));
                },
                child: _buildModernItemCard(itemData),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// SCHERM: ITEM DETAILS & RESERVEREN (NU MET INLINE KALENDER)
// ==========================================
class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({super.key, required this.itemData});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingStart = true; // Bepaalt welke datum de kalender momenteel aanpast

  final _messageController = TextEditingController();
  bool _isRequesting = false;

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitRequest() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecteer zowel een start- als einddatum in de kalender.'), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aanvraag verstuurd! Kijk bij Beheer > Status.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fout bij aanvragen: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final base64String = widget.itemData['fotoBase64'] ?? '';
    
    // Zorg ervoor dat de kalender altijd veilig start vanaf "vandaag" (zonder uren/minuten)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Bepaal op welke datum het kalendervenster moet openen
    DateTime initDate = today;
    if (_selectingStart && _startDate != null) {
      initDate = _startDate!;
    } else if (!_selectingStart) {
      initDate = _endDate ?? _startDate ?? today;
    }
    if (initDate.isBefore(today)) initDate = today;

    return Scaffold(
      appBar: AppBar(title: const Text("Details & Reserveren")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
                color: Colors.grey[200],
                child: base64String.isNotEmpty 
                  ? Image.memory(base64Decode(base64String), fit: BoxFit.contain) 
                  : const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
            
            // INFO
            Text(widget.itemData['omschrijving'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('€${widget.itemData['prijs']} per dag', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.category, color: Colors.grey), const SizedBox(width: 8),
                Text(widget.itemData['categorie'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey), const SizedBox(width: 8),
                Text(widget.itemData['locatie'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
            
            const Divider(height: 40, thickness: 1.5),
            
            // RESERVEREN (INLINE KALENDER)
            const Text("Huurperiode selecteren", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 16),
            
            // Container voor de custom kalender
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 2),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
              ),
              child: Column(
                children: [
                  // Tabbladen voor Start / Eind
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectingStart = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectingStart ? Colors.deepPurple : Colors.transparent,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14)),
                            ),
                            child: Column(
                              children: [
                                Text('Startdatum', style: TextStyle(color: _selectingStart ? Colors.white70 : Colors.black54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_formatDate(_startDate), style: TextStyle(color: _selectingStart ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectingStart = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_selectingStart ? Colors.deepPurple : Colors.transparent,
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(14)),
                            ),
                            child: Column(
                              children: [
                                Text('Einddatum', style: TextStyle(color: !_selectingStart ? Colors.white70 : Colors.black54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_formatDate(_endDate), style: TextStyle(color: !_selectingStart ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // De Ingebouwde Kalender Widget
                  CalendarDatePicker(
                    key: ValueKey(_selectingStart), // Zorgt dat de kalender netjes verspringt als je wisselt
                    initialDate: initDate,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365)),
                    onDateChanged: (date) {
                      setState(() {
                        if (_selectingStart) {
                          _startDate = date;
                          // Als startdatum na einddatum is gekozen, reset einddatum
                          if (_endDate != null && date.isAfter(_endDate!)) {
                            _endDate = null;
                          }
                          _selectingStart = false; // Spring automatisch naar Einddatum selecteren
                        } else {
                          // Als einddatum vóór startdatum is, maak de gekozen datum de nieuwe start
                          if (_startDate != null && date.isBefore(_startDate!)) {
                            _startDate = date;
                            _endDate = null;
                          } else {
                            _endDate = date;
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Bericht voor de verhuurder (optioneel)',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 32),
            _isRequesting 
              ? const Center(child: CircularProgressIndicator())
              : PinkButton(text: 'RESERVERING AANVRAGEN', onPressed: _submitRequest, icon: Icons.send),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCHERM: ITEM TOEVOEGEN
// ==========================================
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _uploadItem() async {
    if (_imageBytes == null || _omschrijvingController.text.isEmpty || _locatieController.text.isEmpty || _selectedCategorie == null || _prijsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vul alle velden in en kies een foto!'), backgroundColor: Colors.red));
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

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toestel succesvol toegevoegd!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Er is iets misgegaan: $e'), backgroundColor: Colors.red));
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
            const Text('Nieuw Toestel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
                ),
                child: _imageBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.black54),
                          SizedBox(height: 12),
                          Text('Tik om foto toe te voegen', style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildModernInputRow('Omschrijving (bijv. Boormachine)', Icons.edit, _omschrijvingController),
            _buildModernInputRow('Locatie (bijv. Antwerpen)', Icons.location_city, _locatieController),
            _buildModernDropdown('Categorie', Icons.category, _selectedCategorie, (val) => setState(() => _selectedCategorie = val)),
            _buildModernInputRow('Prijs per dag (€)', Icons.euro, _prijsController, isNumber: true),
            
            const SizedBox(height: 32),
            _isUploading ? const Center(child: CircularProgressIndicator()) : PinkButton(text: 'TOEVOEGEN', onPressed: _uploadItem, icon: Icons.check_circle_outline),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCHERM: BEHEER
// ==========================================
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
                indicatorWeight: 3,
                labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: [Tab(text: 'Mijn Aanbod'), Tab(text: 'Aanvragen'), Tab(text: 'Status')],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMyItemsTab(),
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

  Widget _buildMyItemsTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Niet ingelogd"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('toestellen').where('verhuurderId', isEqualTo: currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Je hebt nog geen toestellen toegevoegd."));

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
            return _buildModernManageCard(context, itemData);
          },
        );
      },
    );
  }

  Widget _buildAanvragenTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Niet ingelogd"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('aanvragen')
          .where('verhuurderId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'In afwachting') 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Je hebt geen openstaande aanvragen."));

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

  Widget _buildStatusTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Niet ingelogd"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('aanvragen')
          .where('huurderId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Je hebt nog niets aangevraagd."));

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

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> reqData, {required bool isOwner}) {
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
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: base64String.isNotEmpty 
              ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.memory(base64Decode(base64String), fit: BoxFit.cover))
              : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reqData['toestelNaam'] ?? 'Toestel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Huurder: ${reqData['huurderNaam']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                Text("Periode: ${reqData['startDatum']} - ${reqData['eindDatum']}", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                if ((reqData['bericht'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text("Bericht: ${reqData['bericht']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 16),
                
                if (isOwner) 
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(reqData['id'], 'Goedgekeurd'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text("ACCEPTEREN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(reqData['id'], 'Geweigerd'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text("WEIGEREN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _showDeclineReasonDialog(context, reqData['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Weigeren met reden'),
                      )
                    ],
                  )
                else 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor)),
                        child: Center(
                          child: Text("STATUS: ${status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12))
                        ),
                      ),
                      if (status == 'Geweigerd' && (reqData['weigerReden'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text("Reden: ${reqData['weigerReden']}", style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 13)),
                      ]
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String docId, String newStatus, {String? reason}) async {
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
        title: const Text('Reden voor weigering', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: 'Typ hier de reden...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
          ),
          maxLines: 3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                _updateStatus(docId, 'Geweigerd', reason: reasonController.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Weigeren'),
          )
        ]
      )
    );
  }
}

// ==========================================
// SCHERM: ITEM BEWERKEN
// ==========================================
class EditItemScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> itemData;

  const EditItemScreen({super.key, required this.docId, required this.itemData});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _omschrijvingController = TextEditingController();
  final _locatieController = TextEditingController();
  final _prijsController = TextEditingController();
  
  String? _selectedCategorie; 
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _omschrijvingController.text = widget.itemData['omschrijving'] ?? '';
    _locatieController.text = widget.itemData['locatie'] ?? '';
    _prijsController.text = (widget.itemData['prijs'] ?? 0.0).toString();
    String oldCat = widget.itemData['categorie'] ?? '';
    if (kCategories.contains(oldCat)) _selectedCategorie = oldCat;
    String base64String = widget.itemData['fotoBase64'] ?? '';
    if (base64String.isNotEmpty) _imageBytes = base64Decode(base64String);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _updateItem() async {
    if (_omschrijvingController.text.isEmpty || _locatieController.text.isEmpty || _selectedCategorie == null || _prijsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vul alle velden in!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String base64Image = _imageBytes != null ? base64Encode(_imageBytes!) : '';
      await FirebaseFirestore.instance.collection('toestellen').doc(widget.docId).update({
        'omschrijving': _omschrijvingController.text.trim(),
        'locatie': _locatieController.text.trim(),
        'categorie': _selectedCategorie,
        'prijs': double.tryParse(_prijsController.text.trim()) ?? 0.0,
        if (base64Image.isNotEmpty) 'fotoBase64': base64Image,
      });
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Succesvol gewijzigd!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fout bij opslaan: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteItem() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('toestellen').doc(widget.docId).delete();
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toestel verwijderd!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fout bij verwijderen: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showProfileIcon: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Item Bewerken', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 2),
                ),
                child: _imageBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.black54),
                          SizedBox(height: 10),
                          Text('Tik om foto te wijzigen', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildModernInputRow('Omschrijving', Icons.edit, _omschrijvingController),
            _buildModernInputRow('Locatie', Icons.location_city, _locatieController),
            _buildModernDropdown('Categorie', Icons.category, _selectedCategorie, (val) => setState(() => _selectedCategorie = val)),
            _buildModernInputRow('Prijs per dag', Icons.euro, _prijsController, isNumber: true),
            
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      PinkButton(text: 'OPSLAAN', onPressed: _updateItem, icon: Icons.save_outlined),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _deleteItem,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Toestel verwijderen', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HULPFUNCTIES VOOR MODERNE WIDGETS
// ==========================================

Widget _buildModernInputRow(String hint, IconData icon, TextEditingController controller, {bool isNumber = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.deepPurple, width: 2)),
      ),
    ),
  );
}

Widget _buildModernDropdown(String hint, IconData icon, String? value, ValueChanged<String?> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.deepPurple),
      items: kCategories.map((String cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
      onChanged: onChanged,
    ),
  );
}

Widget _buildModernItemCard(Map<String, dynamic> itemData) {
  final base64String = itemData['fotoBase64'] ?? '';
  return Card(
    elevation: 4,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: base64String.isNotEmpty 
                ? Image.memory(base64Decode(base64String), fit: BoxFit.contain) 
                : const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(itemData['omschrijving'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('€${itemData['prijs']}/dag', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(itemData['categorie'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(itemData['locatie'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildModernManageCard(BuildContext context, Map<String, dynamic> itemData) {
  final base64String = itemData['fotoBase64'] ?? '';
  return Card(
    elevation: 4,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: base64String.isNotEmpty 
                ? Image.memory(base64Decode(base64String), fit: BoxFit.contain) 
                : const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(itemData['omschrijving'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('€${itemData['prijs']}/dag', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemScreen(docId: itemData['id'], itemData: itemData)));
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('BEWERK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  minimumSize: const Size(double.infinity, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}