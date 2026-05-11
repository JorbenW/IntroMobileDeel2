import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'pink_button.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialCategory;
  final double?
  initialDistance; // Nu nullable (kan null zijn als de filter uit staat)
  final double? initialPrice; // Nu nullable
  final Function(String?, double?, double?) onApply;

  const FilterBottomSheet({
    super.key,
    this.initialCategory,
    this.initialDistance,
    this.initialPrice,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategory;

  // Afstand State
  bool _enableDistance = false;
  double _distance = 50.0;
  final TextEditingController _distCtrl = TextEditingController();

  // Prijs State
  bool _enablePrice = false;
  double _price = 100.0;
  final TextEditingController _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;

    // Stel afstand in
    if (widget.initialDistance != null) {
      _enableDistance = true;
      _distance = widget.initialDistance!;
    }
    _distCtrl.text = _distance.toInt().toString();

    // Stel prijs in
    if (widget.initialPrice != null) {
      _enablePrice = true;
      _price = widget.initialPrice!;
    }
    _priceCtrl.text = _price.toInt().toString();
  }

  void _syncDistanceSlider(String val) {
    double? parsed = double.tryParse(val);
    if (parsed != null && parsed >= 1 && parsed <= 500) {
      setState(() => _distance = parsed);
    }
  }

  void _syncPriceSlider(String val) {
    double? parsed = double.tryParse(val);
    if (parsed != null && parsed >= 1 && parsed <= 500) {
      setState(() => _price = parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            24, // Voorkomt dat toetsenbord menu bedekt
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filters",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),

            // CATEGORIE
            const Text(
              "Categorie",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("Alles"),
                  selected: _selectedCategory == null,
                  selectedColor: Colors.purple[100],
                  onSelected: (val) => setState(() => _selectedCategory = null),
                ),
                ...kCategories.map(
                  (cat) => FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    selectedColor: Colors.purple[100],
                    onSelected: (val) =>
                        setState(() => _selectedCategory = cat),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // AFSTAND FILTER
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Maximale afstand instellen",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              activeColor: Colors.deepPurple,
              value: _enableDistance,
              onChanged: (val) =>
                  setState(() => _enableDistance = val ?? false),
            ),
            if (_enableDistance) ...[
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _distance,
                      min: 1,
                      max: 500,
                      activeColor: Colors.deepPurple,
                      onChanged: (val) {
                        setState(() {
                          _distance = val;
                          _distCtrl.text = val.toInt().toString();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _distCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        suffixText: 'km',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _syncDistanceSlider,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 30),

            // PRIJS FILTER
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Maximale prijs/dag instellen",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              activeColor: Colors.deepPurple,
              value: _enablePrice,
              onChanged: (val) => setState(() => _enablePrice = val ?? false),
            ),
            if (_enablePrice) ...[
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _price,
                      min: 1,
                      max: 500,
                      activeColor: Colors.deepPurple,
                      onChanged: (val) {
                        setState(() {
                          _price = val;
                          _priceCtrl.text = val.toInt().toString();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '€ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _syncPriceSlider,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            PinkButton(
              text: "FILTERS TOEPASSEN",
              onPressed: () {
                widget.onApply(
                  _selectedCategory,
                  _enableDistance ? _distance : null,
                  _enablePrice ? _price : null,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
