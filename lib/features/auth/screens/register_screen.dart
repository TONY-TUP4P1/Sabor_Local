import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controladores de texto
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Cuenta")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80, // Un poco más chico que en el login
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Únete a SaborLocal",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC45A34)),
                  textAlign: TextAlign.center,
                ),

                // Inputs
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: "Nombre Completo", prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Teléfono / Celular", prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v!.isEmpty ? "Requerido para contactarte" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Correo Electrónico", prefixIcon: Icon(Icons.email)),
                  validator: (v) => v!.contains("@") ? null : "Correo inválido",
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock)),
                  validator: (v) => v!.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 30),

                // Botón Registrar
                authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC45A34),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final error = await authProvider.register(
                              email: _emailController.text.trim(),
                              password: _passController.text.trim(),
                              nombre: _nombreController.text.trim(),
                              telefono: _telefonoController.text.trim(),
                            );

                            if (error == null) {
                              if (context.mounted) Navigator.pop(context); // Volver al login
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Cuenta creada. ¡Inicia sesión!")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            }
                          }
                        },
                        child: const Text("REGISTRARME"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}