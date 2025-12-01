import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu Pedido"),
      ),
      body: Column(
        children: [
          // LISTA DE ITEMS
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("Tu bandeja está vacía", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(item.plato.imagenUrl ?? ''),
                              backgroundColor: Colors.grey[200],
                            ),
                            title: Text(item.plato.nombre),
                            subtitle: Text("Total: S/ ${item.total.toStringAsFixed(2)}"),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      cart.removeSingleItem(item.plato.id);
                                    },
                                  ),
                                  Text("${item.cantidad}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC45A34)),
                                    onPressed: () {
                                      cart.addItem(item.plato);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // RESUMEN Y BOTÓN PAGAR
          Card(
            margin: const EdgeInsets.all(15),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total a Pagar:", style: TextStyle(fontSize: 18)),
                      Text(
                        "S/ ${cart.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC45A34)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: cart.items.isEmpty 
                    ? null 
                    : () async {
                        // Mostramos indicador de carga
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          // Llamamos a la función del Provider
                          await Provider.of<CartProvider>(context, listen: false).confirmarPedido();
                          
                          // Cerramos el indicador de carga
                          if (context.mounted) Navigator.pop(context);

                          // Mostramos éxito y volvemos al menú
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ ¡Pedido enviado a cocina!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context); // Cierra la pantalla del carrito
                          }
                        } catch (e) {
                          // Cerramos el indicador de carga
                          if (context.mounted) Navigator.pop(context);
                          
                          // Mostramos error (probablemente "Debes iniciar sesión")
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF556B2F), // Verde Oliva
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("CONFIRMAR PEDIDO"),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}