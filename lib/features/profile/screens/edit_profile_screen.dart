import 'package:flutter/material.dart';
import '../../../../main.dart'; // supabase

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final uid = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select('nombre, telefono')
          .eq('id', uid)
          .single();
      
      setState(() {
        _nombreCtrl.text = data['nombre'] ?? '';
        _telefonoCtrl.text = data['telefono'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      
      await supabase.from('profiles').update({
        'nombre': _nombreCtrl.text,
        'telefono': _telefonoCtrl.text,
      }).eq('id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Perfil actualizado correctamente")),
        );
        Navigator.pop(context, true); // Retorna true para avisar que hubo cambios
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar grande (Visual)
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFC45A34),
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nombre Completo",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v!.isEmpty ? "El nombre es obligatorio" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Teléfono / Celular",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android),
                        helperText: "Para que el delivery pueda contactarte",
                      ),
                      validator: (v) => v!.isEmpty ? "El teléfono es obligatorio" : null,
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC45A34),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _guardarCambios,
                        child: const Text("GUARDAR CAMBIOS", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}