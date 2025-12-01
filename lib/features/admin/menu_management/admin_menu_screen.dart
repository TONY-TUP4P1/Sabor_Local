import 'package:flutter/material.dart';
import '../../../../main.dart'; // supabase
import 'edit_dish_screen.dart'; // La crearemos en el paso 2

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  // Traemos TODOS los platos (incluso los inactivos) ordenados por ID
  final _menuStream = supabase
      .from('platos')
      .stream(primaryKey: ['id'])
      .order('id', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Carta"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFC45A34),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuevo Plato", style: TextStyle(color: Colors.white)),
        onPressed: () {
          // Navegar a pantalla de crear (sin plato = modo crear)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditDishScreen()));
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _menuStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final platos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];
              final activo = plato['activo'] as bool;

              return Opacity(
                opacity: activo ? 1.0 : 0.6, // 1.0 es visible, 0.6 es medio transparente
                child: Card(
                  // Ya no ponemos 'opacity' aquí adentro porque da error
                  color: activo ? null : Colors.grey[200],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(plato['imagen_url'] ?? ''),
                      backgroundColor: Colors.grey,
                    ),
                    title: Text(
                      plato['nombre'],
                      style: TextStyle(
                        decoration: activo ? null : TextDecoration.lineThrough,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text("S/ ${(plato['precio'] as num).toStringAsFixed(2)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón Activar/Desactivar
                        IconButton(
                          icon: Icon(
                            activo ? Icons.visibility : Icons.visibility_off,
                            color: activo ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _toggleActivo(plato['id'], !activo),
                        ),
                        // Botón Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => EditDishScreen(platoData: plato),
                              )
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleActivo(int id, bool nuevoEstado) async {
    await supabase.from('platos').update({'activo': nuevoEstado}).eq('id', id);
  }
}