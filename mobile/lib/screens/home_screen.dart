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
  List<dynamic> _myReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> activities = await _api.getActivities();
      final List<dynamic> reservations = await _api.getMyReservations();
      setState(() {
        _activities = activities;
        _myReservations = reservations;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isAlreadyBooked(String activityId) {
    return _myReservations.any((r) => r['activity_id'] == activityId && r['status'] == 'active');
  }

  Future<void> _reserve(String activityId) async {
    try {
      await _api.createReservation(activityId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reserva confirmada!')));
      _loadData(); // Refresh everything
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mi Gimnasio', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis Reservas',
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const MyReservationsScreen())
            ).then((_) => _loadData()),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final act = _activities[index];
                final start = DateTime.parse(act['start_time']).toLocal();
                final full = act['booked_count'] >= act['capacity'];
                final booked = _isAlreadyBooked(act['_id']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(act['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(act['instructor'], style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (booked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    SizedBox(width: 4),
                                    Text('RESERVADO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(DateFormat('EEEE d MMM, HH:mm', 'es-ES').format(start), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(act['location']),
                            const Spacer(),
                            Text('${act['booked_count']}/${act['capacity']}', 
                              style: TextStyle(
                                color: full ? Colors.red : Colors.green.shade700, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14
                              )
                            ),
                            const SizedBox(width: 4),
                            Text('plazas', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (booked || full) ? null : () => _showReserveDialog(act),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: booked ? Colors.green.shade100 : Colors.grey.shade300,
                              disabledForegroundColor: booked ? Colors.green.shade700 : Colors.grey.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(booked ? 'YA ESTÁS ASIGNADO' : (full ? 'CLASE LLENA' : 'RESERVAR PLAZA')),
                          ),
                        ),
                      ],
                    ),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas confirmar tu plaza para esta clase?'),
            const SizedBox(height: 12),
            Text('Fecha: ${DateFormat('d MMM, HH:mm').format(DateTime.parse(act['start_time']).toLocal())}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reserve(act['_id']);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            child: const Text('CONFIRMAR RESERVA')
          ),
        ],
      )
    );
  }
}
