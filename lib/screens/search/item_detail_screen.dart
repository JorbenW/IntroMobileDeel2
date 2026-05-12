import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
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
  late DateTime _focusedDay;

  final _messageController = TextEditingController();
  bool _isRequesting = false;
  bool _isLoadingBookings = true;

  List<int> _availableWeekdays = [];
  List<DateTime> _bookedDates = [];

  @override
  void initState() {
    super.initState();
    _calculateAvailableDays();
    _fetchBookedDates();

    DateTime today = DateTime.now();
    _focusedDay = today;
    if (_availableWeekdays.isNotEmpty) {
      while (!_availableWeekdays.contains(_focusedDay.weekday)) {
        _focusedDay = _focusedDay.add(const Duration(days: 1));
      }
    }
  }

  DateTime _parseDateString(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
    return DateTime.now();
  }

  Future<void> _fetchBookedDates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('aanvragen')
          .where('toestelId', isEqualTo: widget.itemData['id'])
          .where('status', isEqualTo: 'Goedgekeurd')
          .get();

      List<DateTime> dates = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final start = _parseDateString(data['startDatum']);
        final end = _parseDateString(data['eindDatum']);

        DateTime checkDatum = DateTime(start.year, start.month, start.day);
        DateTime normalizedEnd = DateTime(end.year, end.month, end.day);

        while (checkDatum.isBefore(normalizedEnd) ||
            checkDatum.isAtSameMomentAs(normalizedEnd)) {
          dates.add(checkDatum);
          checkDatum = checkDatum.add(const Duration(days: 1));
        }
      }

      setState(() {
        _bookedDates = dates;
        _isLoadingBookings = false;
      });
    } catch (e) {
      setState(() => _isLoadingBookings = false);
    }
  }

  void _calculateAvailableDays() {
    final List<dynamic>? stringDays = widget.itemData['beschikbareDagen'];

    if (stringDays == null || stringDays.isEmpty) {
      _availableWeekdays = [1, 2, 3, 4, 5, 6, 7];
      return;
    }

    Map<String, int> dayMap = {
      'Maandag': DateTime.monday,
      'Dinsdag': DateTime.tuesday,
      'Woensdag': DateTime.wednesday,
      'Donderdag': DateTime.thursday,
      'Vrijdag': DateTime.friday,
      'Zaterdag': DateTime.saturday,
      'Zondag': DateTime.sunday,
    };

    _availableWeekdays = stringDays.map((d) => dayMap[d as String]!).toList();
  }

  bool _isDayBooked(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _bookedDates.any((booked) => booked.isAtSameMomentAs(normalizedDay));
  }

  bool _isPeriodeGeldig(DateTime start, DateTime end) {
    DateTime checkDatum = DateTime(start.year, start.month, start.day);
    DateTime normalizedEnd = DateTime(end.year, end.month, end.day);

    while (checkDatum.isBefore(normalizedEnd) ||
        checkDatum.isAtSameMomentAs(normalizedEnd)) {
      if (!_availableWeekdays.contains(checkDatum.weekday)) return false;
      if (_isDayBooked(checkDatum)) return false;
      checkDatum = checkDatum.add(const Duration(days: 1));
    }
    return true;
  }

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
    final today = DateTime.now();

    // Check of jij de eigenaar bent
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser?.uid == widget.itemData['verhuurderId'];

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

            if (_availableWeekdays.length < 7) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Beschikbaar op: ${(widget.itemData['beschikbareDagen'] as List).join(", ")}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 40),

            if (isOwner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 30),
                    SizedBox(height: 8),
                    Text(
                      "Dit is jouw eigen toestel.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      "Je kunt je eigen spullen niet huren.",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              )
            else ...[
              const Text(
                "Huurperiode selecteren",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Van: ${_formatDate(_startDate)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Tot: ${_formatDate(_endDate)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.all(8),
                child: _isLoadingBookings
                    ? const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : TableCalendar(
                        firstDay: today,
                        lastDay: today.add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        rangeStartDay: _startDate,
                        rangeEndDay: _endDate,
                        calendarFormat: CalendarFormat.month,
                        rangeSelectionMode: RangeSelectionMode.enforced,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        pageJumpingEnabled: false,
                        shouldFillViewport: false,

                        enabledDayPredicate: (day) {
                          if (!_availableWeekdays.contains(day.weekday))
                            return false;
                          if (_isDayBooked(day)) return false;
                          return true;
                        },

                        calendarStyle: CalendarStyle(
                          rangeHighlightColor: Colors.purple[100]!,
                          rangeStartDecoration: const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                          withinRangeTextStyle: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          disabledTextStyle: TextStyle(color: Colors.grey[400]),
                        ),

                        onRangeSelected: (start, end, focusedDay) {
                          setState(() => _focusedDay = focusedDay);

                          if (start != null && end != null) {
                            if (_isPeriodeGeldig(start, end)) {
                              setState(() {
                                _startDate = start;
                                _endDate = end;
                              });
                            } else {
                              setState(() {
                                _startDate = start;
                                _endDate = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Je kunt deze periode niet selecteren, omdat het toestel tussendoor al verhuurd of onbeschikbaar is.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                      ),
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
          ],
        ),
      ),
    );
  }
}
