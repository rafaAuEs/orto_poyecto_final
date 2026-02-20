import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'my_reservations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getActivities();
      setState(() => _activities = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reserve(String activityId) async {
    try {
      await _api.createReservation(activityId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reserva confirmada!')));
      _loadData(); // Refresh capacity
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clases Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const MyReservationsScreen())
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final act = _activities[index];
                final start = DateTime.parse(act['start_time']).toLocal();
                final full = act['booked_count'] >= act['capacity'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(act['instructor'][0])),
                    title: Text(act['title']),
                    subtitle: Text('${DateFormat('EEE d MMM HH:mm').format(start)}\n${act['location']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${act['booked_count']}/${act['capacity']}', 
                          style: TextStyle(color: full ? Colors.red : Colors.green, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 4),
                        if (!full) 
                          const Icon(Icons.add_circle, color: Colors.blue)
                      ],
                    ),
                    onTap: full ? null : () => _showReserveDialog(act),
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showReserveDialog(dynamic act) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text('Reservar ${act['title']}'),
        content: const Text('¿Confirmar reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            _reserve(act['_id']);
          }, child: const Text('Confirmar')),
        ],
      )
    );
  }
}
