import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import 'register_screen.dart';
//import '../../admin/kitchen/kitchen_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Aquí pondremos tu logo final luego
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120, // Ajusta el tamaño según tu gusto
                  fit: BoxFit.contain, // Para que no se deforme
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Bienvenido de nuevo",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const Text("Tradición en cada bocado"),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Correo", prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Contraseña", prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 30),

              authProvider.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC45A34),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        final error = await authProvider.login(
                          email: _emailController.text.trim(),
                          password: _passController.text.trim(),
                        );
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                        }
                        // Si no hay error, el Stream en main.dart nos llevará al Home automáticamente
                      },
                      child: const Text("INGRESAR"),
                    ),
              
              const SizedBox(height: 20),
              /*TextButton.icon(
                icon: const Icon(Icons.soup_kitchen, color: Colors.grey),
                label: const Text("Acceso Cocina (Staff)", style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  // Navegar directo a la pantalla de cocina
                  // (Nota: En producción, esto pediría password de admin)
                  // Asegúrate de importar la pantalla arriba
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const KitchenScreen()) // Requiere import
                  );
                },
              ),*/
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text("¿No tienes cuenta? Regístrate aquí"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}