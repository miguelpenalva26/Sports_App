import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Screen for creating a new sports facility booking
class BookingScreen extends StatefulWidget {
  final String token;

  const BookingScreen({super.key, required this.token});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List _facilities = [];
  int? _selectedFacility;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List _bookingsForDay = []; // Existing bookings for the selected day
  String _recommendation = ""; // Weather recommendation (indoor/outdoor)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  // Loads the list of available facilities when the screen opens
  Future<void> _fetchFacilities() async {
    final facilities = await ApiService.fetchFacilities(widget.token);
    setState(() {
      _facilities = facilities;
      _isLoading = false;
    });
  }

  // Fetches bookings for the selected facility and day
  // Called when the facility or date changes to show occupied slots
  Future<void> _fetchBookingsForDay() async {
    if (_selectedFacility == null || _selectedDate == null) return;
    final date = _selectedDate!.toIso8601String().split("T")[0];
    final bookings = await ApiService.fetchBookingsForDay(
        widget.token, _selectedFacility!, date);
    setState(() => _bookingsForDay = bookings);
  }

  // Asks the backend whether rain is expected to recommend indoor or outdoor
  Future<void> _fetchRecommendation() async {
    if (_selectedDate == null || _startTime == null) return;
    final date = _selectedDate!.toIso8601String().split("T")[0];
    final hour = _startTime!.hour.toString();
    final recommendation = await ApiService.fetchRecommendation(date, hour);
    setState(() => _recommendation = recommendation);
  }

  // Checks whether the chosen time slot overlaps with any existing booking
  bool _isOverlapping() {
    if (_startTime == null || _endTime == null) return false;

    final selectedStart = DateTime(0, 0, 0, _startTime!.hour, _startTime!.minute);
    final selectedEnd = DateTime(0, 0, 0, _endTime!.hour, _endTime!.minute);

    for (var booking in _bookingsForDay) {
      final startParts = booking["start_time"].split(":");
      final endParts = booking["end_time"].split(":");
      final bookedStart = DateTime(0, 0, 0, int.parse(startParts[0]), int.parse(startParts[1]));
      final bookedEnd = DateTime(0, 0, 0, int.parse(endParts[0]), int.parse(endParts[1]));

      if (selectedStart.isBefore(bookedEnd) && selectedEnd.isAfter(bookedStart)) {
        return true;
      }
    }
    return false;
  }

  // Validates fields, checks for overlap and sends the booking to the backend
  Future<void> _createBooking() async {
    if (_selectedFacility == null || _selectedDate == null ||
        _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    if (_isOverlapping()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This time slot is already booked")));
      return;
    }

    final success = await ApiService.createBooking(widget.token, {
      "facility": _selectedFacility,
      "date": _selectedDate!.toIso8601String().split("T")[0],
      "start_time":
          "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00",
      "end_time":
          "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00",
    });

    // Returns true to HomeScreen so it refreshes the booking list
    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error creating booking")));
    }
  }

  // Dark background container reused by all form fields
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("New Booking", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFacilityDropdown(),
                  const SizedBox(height: 20),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildStartTimePicker(),
                  const SizedBox(height: 20),
                  _buildEndTimePicker(),
                  if (_bookingsForDay.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildOccupiedSlots(),
                  ],
                  if (_recommendation.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildRecommendation(),
                  ],
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildFacilityDropdown() {
    return _buildCard(
      child: DropdownButtonFormField<int>(
        dropdownColor: const Color(0xFF1E293B),
        decoration: const InputDecoration(
          labelText: "Select Facility",
          labelStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        items: _facilities.map<DropdownMenuItem<int>>((facility) {
          return DropdownMenuItem<int>(
            value: facility["id"],
            child: Text(facility["name"]),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedFacility = value);
          _fetchBookingsForDay();
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return _buildCard(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.greenAccent),
        title: Text(
          _selectedDate == null
              ? "Select Date"
              : _selectedDate!.toString().split(" ")[0],
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            initialDate: DateTime.now(),
          );
          if (date != null) {
            setState(() => _selectedDate = date);
            _fetchBookingsForDay();
          }
        },
      ),
    );
  }

  Widget _buildStartTimePicker() {
    return _buildCard(
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.greenAccent),
        title: Text(
          _startTime == null ? "Select Start Time" : _startTime!.format(context),
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            setState(() => _startTime = time);
            await _fetchRecommendation(); // Fetch recommendation when start time is set
          }
        },
      ),
    );
  }

  Widget _buildEndTimePicker() {
    return _buildCard(
      child: ListTile(
        leading: const Icon(Icons.access_time_filled, color: Colors.greenAccent),
        title: Text(
          _endTime == null ? "Select End Time" : _endTime!.format(context),
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) setState(() => _endTime = time);
        },
      ),
    );
  }

  // Shows already booked time slots for that day and facility
  Widget _buildOccupiedSlots() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Occupied slots",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._bookingsForDay.map((b) => Text(
                "${b["start_time"]} - ${b["end_time"]}",
                style: const TextStyle(color: Colors.white70),
              )),
        ],
      ),
    );
  }

  // Shows red if rain is expected, green if the weather is fine
  Widget _buildRecommendation() {
    return _buildCard(
      child: Text(
        _recommendation,
        style: TextStyle(
          color: _recommendation.contains("Rain") ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _createBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text(
          "Create Booking",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
