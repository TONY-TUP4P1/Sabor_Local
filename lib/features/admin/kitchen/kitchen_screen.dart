import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // <--- Importante para Logout
import '../../../../main.dart'; 
import '../../auth/auth_provider.dart'; // <--- Importante para Logout
import 'kitchen_history_screen.dart'; // <--- Importa la nueva pantalla
import '../menu_management/admin_menu_screen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  // Stream: Escucha TODOS los pedidos que NO estén 'entregados'
  final _ordersStream = supabase
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true); // Los más viejos primero (FIFO)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👨‍🍳 Comidas Activas"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu), // Ícono de menú
            tooltip: "Gestionar Carta",
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const AdminMenuScreen()) // Importar archivo
              );
            },
          ),
          // 1. BOTÓN IR AL HISTORIAL
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Ver Entregados",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KitchenHistoryScreen()),
              );
            },
          ),
          // 2. BOTÓN CERRAR SESIÓN (LOGOUT)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Salir",
            onPressed: () {
              // Llamamos al AuthProvider para cerrar sesión
              context.read<AuthProvider>().signOut();
              // El AuthGate en main.dart detectará que no hay usuario 
              // y te mandará al Login automáticamente.
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pedidos = snapshot.data!
              .where((pedido) => pedido['estado'] != 'entregado') 
              .toList();

          if (pedidos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 20),
                  Text("¡Todo despachado! 🎉", style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          // Grid de comandas activas
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 0.75, // Ajustado un poco para que quepan botones
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              return _KitchenOrderCard(pedido: pedidos[index]);
            },
          );
        },
      ),
    );
  }
}

// --- TARJETA DE PEDIDO INDIVIDUAL ---
class _KitchenOrderCard extends StatelessWidget {
  final Map<String, dynamic> pedido;

  const _KitchenOrderCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final estado = pedido['estado'];
    final id = pedido['id'];
    final hora = DateFormat('HH:mm').format(DateTime.parse(pedido['created_at']).toLocal());

    Color cardColor;
    if (estado == 'pendiente') cardColor = Colors.white;
    else if (estado == 'en_cocina') cardColor = const Color(0xFFFFF3CD); // Amarillo suave
    else cardColor = const Color(0xFFD4EDDA); // Verde suave

    return Card(
      color: cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: ID y Hora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text("#$id", style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.black12,
                ),
                Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            
            // LISTA DE PLATOS (Necesitamos consultarlos)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                // Consultamos los detalles de ESTE pedido específico
                future: supabase
                    .from('detalle_pedido')
                    .select('cantidad, nota, platos(nombre)') // Join con tabla platos
                    .eq('pedido_id', id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!;

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final platoNombre = item['platos']['nombre'];
                      final cantidad = item['cantidad'];
                      final nota = item['nota'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${cantidad}x $platoNombre",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (nota != null)
                              Text("Nota: $nota", style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // BOTONES DE ACCIÓN
            const Divider(),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, estado, id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String estado, int id) {
    if (estado == 'pendiente') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.local_fire_department),
        label: const Text("COCINAR"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
        onPressed: () => _actualizarEstado(context, id, 'en_cocina'),
      );
    } else if (estado == 'en_cocina') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text("TERMINAR"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        onPressed: () => _actualizarEstado(context, id, 'listo'),
      );
    } else {
      return ElevatedButton.icon(
        icon: const Icon(Icons.delivery_dining),
        label: const Text("ENTREGADO"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
        onPressed: () => _actualizarEstado(context, id, 'entregado'),
      );
    }
  }

  Future<void> _actualizarEstado(BuildContext context, int id, String nuevoEstado) async {
    try {
      // Mostramos un mensajito de "Procesando..."
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cambiando a estado: $nuevoEstado..."), 
          duration: const Duration(milliseconds: 500)
        ),
      );

      // Intentamos actualizar
      // .select() es CLAVE: Si la actualización funciona, devuelve la fila. Si falla (RLS), lanza error.
      await supabase
          .from('pedidos')
          .update({'estado': nuevoEstado})
          .eq('id', id)
          .select(); 

    } catch (e) {
      // Si falla, mostramos el error en rojo en la pantalla
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: No tienes permiso para editar. \n$e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}