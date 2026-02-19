import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Only for register
  bool _isRegister = false;
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      if (_isRegister) {
        await auth.register(_emailCtrl.text, _nameCtrl.text, _passCtrl.text);
      } else {
        await auth.login(_emailCtrl.text, _passCtrl.text);
      }
      // Navigation handled by main wrapper based on auth state
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                _isRegister ? 'Crear Cuenta' : 'Bienvenido',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              if (_isRegister)
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                ),
              if (_isRegister) const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(_isRegister ? 'Registrarse' : 'Entrar'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(_isRegister ? '¿Ya tienes cuenta? Entra' : '¿No tienes cuenta? Regístrate'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
