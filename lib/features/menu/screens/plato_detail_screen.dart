import 'package:flutter/material.dart';
import '../../../data/models/plato_model.dart';
import 'package:provider/provider.dart';
import '../../cart/logic/cart_provider.dart';
import 'package:sabor_local/main.dart';

class PlatoDetailScreen extends StatelessWidget {
  final Plato plato;

  const PlatoDetailScreen({super.key, required this.plato});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hacemos que la imagen ocupe la parte superior incluso detrás de la barra de estado
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0), // Un poco de margen del borde
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5), // Círculo negro semi-transparente
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white), // Ícono blanco
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                plato.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  plato.imagenUrl != null
                      ? Image.network(plato.imagenUrl!, fit: BoxFit.cover)
                      : Container(color: Colors.orange),
                  // Gradiente oscuro abajo para que se lea el texto
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio y Botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "S/ ${plato.precio.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC45A34), // Terracota
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<CartProvider>().addItem(plato);
                          // Lógica de agregar al carrito (Próximamente)
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("¡${plato.nombre} agregado al pedido!"),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'DESHACER',
                                onPressed: () {
                                  context.read<CartProvider>().removeSingleItem(plato.id);
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text("Pedir"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC45A34),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Sección: Historia / Descripción
                  const Text(
                    "Historia y Origen",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plato.descripcion ?? "Sin información disponible.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),
                  const Divider(height: 40),

                  // Sección: Ingredientes (Estática por ahora, luego la conectamos a SQL)
                  const Text(
                    "Ingredientes & Origen",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    // Consultamos la tabla recetas unida con ingredientes
                    future: supabase
                        .from('recetas')
                        .select('cantidad_requerida, ingredientes(nombre, unidad_medida)')
                        .eq('plato_id', plato.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
                      }
                      
                      final recetas = snapshot.data;
                      
                      // Si no hay receta cargada para este plato
                      if (recetas == null || recetas.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: const Text("Información de ingredientes no disponible por el momento."),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recetas.map((item) {
                          final ingrediente = item['ingredientes'] as Map<String, dynamic>; // Datos del join
                          final nombre = ingrediente['nombre'];
                          // Opcional: Mostrar cantidad (ej: "0.5 kg Papas")
                          // final cantidad = item['cantidad_requerida']; 
                          // final unidad = ingrediente['unidad_medida'];

                          return Chip(
                            label: Text(nombre), // Solo mostramos el nombre para que se vea limpio
                            backgroundColor: const Color(0xFFE8B948).withOpacity(0.2),
                            avatar: const Icon(Icons.eco, size: 18, color: Color(0xFF5C4033)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}