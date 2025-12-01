import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../cart/logic/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../../data/models/plato_model.dart';
import '../../../main.dart'; // Para supabase

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream de mis pedidos
    final _misPedidosStream = supabase
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Estado de mis Pedidos")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _misPedidosStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!;

          if (pedidos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Aún no has hecho pedidos", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              return _PedidoProgressCard(pedido: pedidos[index]);
            },
          );
        },
      ),
    );
  }
}

// --- NUEVO WIDGET: TARJETA CON BARRA DE PROGRESO ---
class _PedidoProgressCard extends StatelessWidget {
  final Map<String, dynamic> pedido;

  const _PedidoProgressCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final estado = pedido['estado'] ?? 'pendiente';
    final fecha = DateTime.parse(pedido['created_at']).toLocal();
    final total = (pedido['total'] as num).toDouble();

    // Lógica visual según el estado
    double progreso = 0.0;
    Color color = Colors.grey;
    String mensaje = "";
    IconData icono = Icons.help;

    switch (estado) {
      case 'pendiente':
        progreso = 0.2;
        color = Colors.orange;
        mensaje = "Tu pedido está en cola de espera.";
        icono = Icons.hourglass_top;
        break;
      case 'en_cocina':
        progreso = 0.6;
        color = Colors.blue;
        mensaje = "¡El chef está cocinando tus platos! 🔥";
        icono = Icons.soup_kitchen;
        break;
      case 'listo':
        progreso = 0.9;
        color = Colors.green;
        mensaje = "¡Ya está listo! Esperando entrega.";
        icono = Icons.dinner_dining;
        break;
      case 'entregado':
        progreso = 1.0;
        color = Colors.grey; // Color neutro porque ya acabó
        mensaje = "Pedido completado. ¡Buen provecho!";
        icono = Icons.check_circle;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera (ID y Fecha)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pedido #${pedido['id']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  DateFormat('HH:mm').format(fecha),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 2. Barra de Progreso e Ícono
            Row(
              children: [
                // Ícono circular
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: color, size: 30),
                ),
                const SizedBox(width: 15),
                
                // Barra Lineal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progreso,
                          backgroundColor: Colors.grey[200],
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Texto de estado (ej: "En Cocina")
                      Text(
                        estado.toString().toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: color, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            const Divider(),
            
            // 3. Mensaje amigable y Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mensaje,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "S/ ${total.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFC45A34)),
                    ),
                    const SizedBox(height: 5),

                    // --- LÓGICA DE BOTONES SEGÚN ESTADO ---
                    
                    // CASO 1: AÚN SE PUEDE EDITAR (Pendiente)
                    if (estado == 'pendiente')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text("Modificar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, 
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _modificarPedido(context, pedido['id']),
                      )
                    
                    // CASO 2: YA ESTÁ EN COCINA (Bloqueado)
                    else if (estado == 'en_cocina')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.grey)
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text("En preparación", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      )
                      
                    // CASO 3: YA TERMINÓ (Opcional: aquí podrías poner Repetir si quisieras en el futuro)
                    else
                      const SizedBox.shrink(), // No mostramos nada
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _modificarPedido(BuildContext context, int pedidoId) async {
    // 1. Preguntar confirmación (Importante porque borraremos el pedido actual)
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Modificar pedido?"),
        content: const Text("Esto cancelará la orden actual y moverá los productos al carrito para que puedas editarlos."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("MODIFICAR")),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recuperando productos...")));
      }

      // 2. Traer los detalles del pedido (qué platos eran)
      final response = await supabase
          .from('detalle_pedido')
          .select('platos(*)') // Join con tabla platos
          .eq('pedido_id', pedidoId);

      final detalles = response as List<dynamic>;

      // 3. Convertirlos a objetos Plato
      List<Plato> platosRecuperados = [];
      for (var item in detalles) {
        if (item['platos'] != null) {
          // OJO: Si pediste 2 veces el mismo plato, aquí lo agregamos 2 veces a la lista
          // El CartProvider se encargará de agruparlos.
          // Si tu detalle tiene cantidad > 1, deberíamos hacer un bucle, pero para este MVP
          // asumiremos que addItem suma de 1 en 1.
          
          // *Mejora técnica:* Si en detalle dice cantidad: 2, lo agregamos 2 veces al array
          int cantidad = item['cantidad'] ?? 1;
          for(int i=0; i<cantidad; i++){
             platosRecuperados.add(Plato.fromJson(item['platos']));
          }
        }
      }

      // 4. ELIMINAR EL PEDIDO VIEJO DE LA BASE DE DATOS
      // Nota: Debemos borrar primero los detalles y luego la cabecera, 
      // O si configuraste "Cascade Delete" en SQL, basta con borrar la cabecera.
      // Por seguridad lo hacemos en orden:
      await supabase.from('detalle_pedido').delete().eq('pedido_id', pedidoId);
      await supabase.from('pedidos').delete().eq('id', pedidoId);

      // 5. Cargar al carrito y navegar
      if (context.mounted) {
        context.read<CartProvider>().cargarItemsParaEditar(platosRecuperados);
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const CartScreen())
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pedido recuperado. Haz tus cambios.")),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}