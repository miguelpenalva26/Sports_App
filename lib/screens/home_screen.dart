import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/booking_card.dart';
import 'booking_screen.dart';
import 'login_screen.dart';

// Main screen: shows the user's bookings and allows creating or deleting them
class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // Loads all bookings for the authenticated user
  Future<void> _fetchBookings() async {
    final bookings = await ApiService.fetchBookings(widget.token);
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  // Shows a confirmation dialog before deleting the booking
  Future<void> _deleteBooking(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete booking?", style: TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteBooking(widget.token, id);
      if (success && mounted) {
        _fetchBookings(); // Refresh the list after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking deleted"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Opens the new booking screen and refreshes the list if one was created
  Future<void> _openBookingScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(token: widget.token)),
    );

    if (result == true && mounted) {
      _fetchBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking created successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Logs out: clears the navigation stack and returns to the login screen
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Log out",
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        onPressed: _openBookingScreen,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
                ? _buildEmptyState()
                : _buildBookingList(),
      ),
    );
  }

  // Empty state shown when the user has no bookings
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.white24),
          SizedBox(height: 20),
          Text("No bookings yet", style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 10),
          Text("Tap + to create your first booking", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  // Booking list, each card has a delete option
  Widget _buildBookingList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "My Bookings",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        ..._bookings.map((booking) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BookingCard(
                facility: booking["facility_name"] ?? "Unknown Court",
                date: booking["date"] ?? "No date",
                time: "${booking["start_time"] ?? ""} - ${booking["end_time"] ?? ""}",
                onDelete: () => _deleteBooking(booking["id"]),
              ),
            )),
      ],
    );
  }
}
