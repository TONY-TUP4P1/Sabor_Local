import 'dart:convert'; // Para convertir datos a JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // El paquete para el truco
import '../../../../main.dart'; 
import '../../../../core/constants/supabase_constants.dart'; // Tus llaves

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión de Personal"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.badge), text: "Colaboradores"),
              Tab(icon: Icon(Icons.people), text: "Clientes"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ListaColaboradores(), // Aquí está el botón de crear
            _ListaClientes(),
          ],
        ),
      ),
    );
  }
}

// --- PESTAÑA 1: COLABORADORES ---
class _ListaColaboradores extends StatefulWidget {
  const _ListaColaboradores();

  @override
  State<_ListaColaboradores> createState() => _ListaColaboradoresState();
}

class _ListaColaboradoresState extends State<_ListaColaboradores> {
  // Filtramos staff
  final staffStream = supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .neq('rol', 'cliente')
      .order('nombre', ascending: true);

  // --- FUNCIÓN PARA ABRIR DIÁLOGO DE CREACIÓN ---
  void _mostrarDialogoCrear() {
    showDialog(
      context: context,
      builder: (context) => const _CrearColaboradorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BOTÓN FLOTANTE REAL
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.person_add),
        label: const Text("Nuevo Staff"),
        onPressed: _mostrarDialogoCrear,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: staffStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;

          if (users.isEmpty) return const Center(child: Text("No hay colaboradores."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _StaffCard(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

// --- EL DIÁLOGO DE REGISTRO DE STAFF ---
class _CrearColaboradorDialog extends StatefulWidget {
  const _CrearColaboradorDialog();

  @override
  State<_CrearColaboradorDialog> createState() => _CrearColaboradorDialogState();
}

class _CrearColaboradorDialogState extends State<_CrearColaboradorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  String _rolSeleccionado = 'cocina'; // Por defecto
  bool _isLoading = false;

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();

    try {
      // 1. EL TRUCO HTTP: Llamada directa a la API de Supabase Auth
      // Esto crea el usuario SIN cerrar la sesión del Admin.
      final url = Uri.parse('${SupabaseConstants.url}/auth/v1/signup');
      
      final response = await http.post(
        url,
        headers: {
          'apikey': SupabaseConstants.anonKey, // Llave pública
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          // Pasamos el nombre en 'data' para que el Trigger lo agarre
          'data': {
            'nombre': nombre,
            'telefono': '000-000', // Teléfono dummy
          }
        }),
      );

      if (response.statusCode != 200) {
        throw "Error al crear: ${response.body}";
      }

      // Obtenemos el ID del nuevo usuario creado desde la respuesta
      final responseData = jsonDecode(response.body);
      final newUserId = responseData['id'] ?? responseData['user']['id'];

      // 2. ACTUALIZAR EL ROL
      // El trigger lo crea como 'cliente', así que ahora nosotros (Admin) lo subimos a 'cocina'
      // Esperamos un segundo para asegurarnos de que el Trigger ya creó la fila
      await Future.delayed(const Duration(seconds: 1));

      await supabase
          .from('profiles')
          .update({'rol': _rolSeleccionado})
          .eq('id', newUserId);

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Usuario $nombre creado como $_rolSeleccionado")),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Colaborador"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre", prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Correo", prefixIcon: Icon(Icons.email)),
                validator: (v) => v!.contains("@") ? null : "Email inválido",
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock)),
                validator: (v) => v!.length < 6 ? "Mín. 6 caracteres" : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(labelText: "Rol Asignado", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'cocina', child: Text("👨‍🍳 Cocina")),
                  DropdownMenuItem(value: 'admin', child: Text("👔 Gerente")),
                ],
                onChanged: (val) => setState(() => _rolSeleccionado = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: _isLoading ? null : _crearUsuario,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CREAR"),
        ),
      ],
    );
  }
}

// --- PESTAÑA 2: CLIENTES (Sin cambios mayores, solo la corrección de Opacity) ---
class _ListaClientes extends StatelessWidget {
  const _ListaClientes();

  @override
  Widget build(BuildContext context) {
    final clientStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('rol', 'cliente')
        .order('nombre', ascending: true);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: clientStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        if (users.isEmpty) return const Center(child: Text("No hay clientes."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final activo = user['activo'] ?? true;
            return Opacity(
              opacity: activo ? 1.0 : 0.6,
              child: Card(
                color: activo ? null : Colors.grey[200],
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['nombre'] ?? 'Sin nombre'),
                  subtitle: Text(user['email'] ?? 'Sin correo'),
                  trailing: Switch(
                    value: activo,
                    onChanged: (val) => _toggleActivo(context, user['id'], val),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- TARJETA DE STAFF (Igual que antes) ---
class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _StaffCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final activo = user['activo'] ?? true;
    final rol = user['rol'];
    
    return Opacity(
      opacity: activo ? 1.0 : 0.6,
      child: Card(
        color: activo ? Colors.white : Colors.grey[200],
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: rol == 'admin' ? Colors.red : Colors.orange,
            child: Icon(rol == 'admin' ? Icons.security : Icons.soup_kitchen, color: Colors.white),
          ),
          title: Text(user['nombre'] ?? 'Staff'),
          subtitle: Text(rol.toString().toUpperCase()),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Rol:"),
                      DropdownButton<String>(
                        value: rol,
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text("Gerente")),
                          DropdownMenuItem(value: 'cocina', child: Text("Cocina")),
                          DropdownMenuItem(value: 'cliente', child: Text("Bajar a Cliente")),
                        ],
                        onChanged: (val) => _updateRol(context, user['id'], val!),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Switch(value: activo, onChanged: (val) => _toggleActivo(context, user['id'], val)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), 
                        onPressed: () => _confirmarEliminar(context, user['id'])
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FUNCIONES GLOBALES DE BD ---
Future<void> _toggleActivo(BuildContext context, String uid, bool estado) async {
  await supabase.from('profiles').update({'activo': estado}).eq('id', uid);
}
Future<void> _updateRol(BuildContext context, String uid, String rol) async {
  await supabase.from('profiles').update({'rol': rol}).eq('id', uid);
}
Future<void> _confirmarEliminar(BuildContext context, String uid) async {
  // Lógica de borrado (igual que antes)
  await supabase.from('profiles').delete().eq('id', uid);
}