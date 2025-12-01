import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart'; // Para supabase

class KitchenHistoryScreen extends StatelessWidget {
  const KitchenHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream: Escucha SOLO los pedidos con estado 'entregado'
    final historyStream = supabase
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .eq('estado', 'entregado') // <--- FILTRO CLAVE
        .order('created_at', ascending: false); // Los más recientes arriba

    return Scaffold(
      appBar: AppBar(
        title: const Text("📜 Historial de Entregas"),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: historyStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!;

          if (pedidos.isEmpty) {
            return const Center(child: Text("No hay entregas registradas aún."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final fecha = DateTime.parse(pedido['created_at']).toLocal();

              return Card(
                color: Colors.grey[200], // Color apagado para indicar "pasado"
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  title: Text(
                    "Pedido #${pedido['id']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Entregado: ${DateFormat('dd/MM - HH:mm').format(fecha)}",
                  ),
                  trailing: Text(
                    "S/ ${(pedido['total'] as num).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}