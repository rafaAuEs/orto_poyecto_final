import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final dynamic activity;
  const AttendanceScreen({super.key, required this.activity});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _attendees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getActivityReservations(widget.activity['_id']);
      setState(() => _attendees = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String resId, String status) async {
    try {
      // Optimistic update
      final index = _attendees.indexWhere((r) => r['_id'] == resId);
      final oldStatus = _attendees[index]['status'];
      
      setState(() {
        _attendees[index]['status'] = status;
      });

      await _api.updateAttendance(resId, status);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
      _loadData(); // Revert
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity['title']),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendees.isEmpty 
            ? const Center(child: Text("No hay alumnos inscritos"))
            : ListView.builder(
                itemCount: _attendees.length,
                itemBuilder: (context, index) {
                  final res = _attendees[index];
                  final status = res['status'];
                  
                  return Card(
                    child: ListTile(
                      title: Text(res['user_name'] ?? 'Usuario'),
                      subtitle: Text(res['user_email'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle, 
                              color: status == 'attended' ? Colors.green : Colors.grey[300]
                            ),
                            onPressed: () => _updateStatus(res['_id'], 'attended'),
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, 
                              color: status == 'absent' ? Colors.red : Colors.grey[300]
                            ),
                            onPressed: () => _updateStatus(res['_id'], 'absent'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
