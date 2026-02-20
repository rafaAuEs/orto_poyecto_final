import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ActivityFormScreen extends StatefulWidget {
  final dynamic activity; // null for create, object for edit
  const ActivityFormScreen({super.key, this.activity});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _instructorController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final act = widget.activity;
    _titleController = TextEditingController(text: act?['title'] ?? '');
    _instructorController = TextEditingController(text: act?['instructor'] ?? '');
    _locationController = TextEditingController(text: act?['location'] ?? 'Sala Principal');
    _capacityController = TextEditingController(text: act?['capacity']?.toString() ?? '20');
    
    _startTime = act != null ? DateTime.parse(act['start_time']).toLocal() : DateTime.now().add(const Duration(hours: 1));
    _endTime = act != null ? DateTime.parse(act['end_time']).toLocal() : _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructorController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      if (!mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser posterior al inicio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'instructor': _instructorController.text,
      'location': _locationController.text,
      'capacity': int.parse(_capacityController.text),
      'start_time': _startTime.toUtc().toIso8601String().replaceFirst('.000', 'Z'),
      'end_time': _endTime.toUtc().toIso8601String().replaceFirst('.000', 'Z'),
    };

    try {
      if (widget.activity == null) {
        await _api.createActivity(data);
      } else {
        await _api.updateActivity(widget.activity['_id'], data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.activity != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Clase' : 'Nueva Clase'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título de la Actividad', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _instructorController,
                          decoration: const InputDecoration(labelText: 'Instructor', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Aforo', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Ubicación', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Horario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Inicio'),
                    subtitle: Text(DateFormat('EEE, d MMM yyyy, HH:mm').format(_startTime)),
                    trailing: const Icon(Icons.calendar_month),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    onTap: () => _pickDateTime(true),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(DateFormat('EEE, d MMM yyyy, HH:mm').format(_endTime)),
                    trailing: const Icon(Icons.calendar_month),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    onTap: () => _pickDateTime(false),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    child: Text(isEdit ? 'GUARDAR CAMBIOS' : 'CREAR ACTIVIDAD'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
