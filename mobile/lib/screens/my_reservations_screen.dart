import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getMyReservations();
      setState(() => _reservations = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel(String resId) async {
    try {
      final result = await _api.cancelReservation(resId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _reservations.length,
              itemBuilder: (context, index) {
                final res = _reservations[index];
                final start = res['activity_start_time'] != null 
                  ? DateTime.parse(res['activity_start_time']).toLocal() 
                  : DateTime.now();
                final status = res['status'];

                Color statusColor;
                switch (status) {
                  case 'active': statusColor = Colors.green; break;
                  case 'cancelled': statusColor = Colors.grey; break;
                  case 'late_cancelled': statusColor = Colors.orange; break;
                  case 'absent': statusColor = Colors.red; break;
                  default: statusColor = Colors.black;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(res['activity_title'] ?? 'Clase desconocida'),
                    subtitle: Text('${DateFormat('EEE d MMM HH:mm').format(start)}\nEstado: $status'),
                    leading: Icon(Icons.confirmation_number, color: statusColor),
                    trailing: status == 'active' 
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _showCancelDialog(res['_id']),
                        )
                      : null,
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showCancelDialog(String resId) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text('¿Seguro? Si quedan menos de 15 min, contará como no asistencia.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            _cancel(resId);
          }, child: const Text('Cancelar Clase', style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }
}
