import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cart/logic/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../../main.dart'; // Acceso a variable 'supabase'
import '../../../data/models/plato_model.dart';
import '../widgets/plato_card.dart';
import '../screens/plato_detail_screen.dart';
import '../../../core/widgets/side_menu.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Stream que escucha cambios en tiempo real en la tabla 'platos'
  // Si cambias un precio en Supabase, la app se actualiza sola al instante.
  final _platosStream = supabase
      .from('platos')
      .stream(primaryKey: ['id'])
      .order('id');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(), 
      
      appBar: AppBar(
        title: const Text("SaborLocal"),
        centerTitle: true, // Título centrado se ve mejor con menú a la izq
        backgroundColor: Colors.white,
        elevation: 0,
        
        // CAMBIO 2: Usamos 'leading' para el botón de la izquierda
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu, color: Colors.black),
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Abre el menú de la IZQUIERDA
            },
          ),
        ),
        
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _platosStream,
        builder: (context, snapshot) {
          // 1. Estado Cargando
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final platosRaw = snapshot.data!;
          
          // 2. Estado Vacío
          if (platosRaw.isEmpty) {
            return const Center(child: Text("No hay platos disponibles hoy."));
          }

          // 3. Convertir datos a objetos Plato
          final platos = platosRaw.map((e) => Plato.fromJson(e)).toList();

          // 4. Mostrar Lista
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];
              return PlatoCard(
                plato: plato,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlatoDetailScreen(plato: plato),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (_, cart, ch) => Badge(
          label: Text(cart.itemCount.toString()), // Muestra el número de items
          isLabelVisible: cart.itemCount > 0,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFC45A34),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const CartScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}