import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';

class AdminReservationsScreen extends StatelessWidget {
  const AdminReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream: Todas las reservas desde HOY en adelante
    final _adminStream = supabase
        .from('reservas')
        .stream(primaryKey: ['id'])
        .gte('fecha_hora', DateTime.now().toIso8601String()) // Solo futuras
        .order('fecha_hora', ascending: true); // Lo más próximo primero

    return Scaffold(
      appBar: AppBar(
        title: const Text("Libro de Reservas"),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _adminStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reservas = snapshot.data!;

          if (reservas.isEmpty) return const Center(child: Text("No hay reservas próximas."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index];
              final fecha = DateTime.parse(reserva['fecha_hora']).toLocal();
              
              // Buscamos el nombre del cliente (Join manual simple)
              // Nota: Idealmente haríamos un join en SQL, pero para MVP hacemos fetch del perfil
              return FutureBuilder(
                future: supabase.from('profiles').select('nombre, telefono').eq('id', reserva['user_id']).single(),
                builder: (context, userSnap) {
                  final userName = userSnap.hasData ? userSnap.data!['nombre'] : 'Cargando...';
                  final userTel = userSnap.hasData ? userSnap.data!['telefono'] : '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple[100],
                        child: Text(DateFormat('d').format(fecha)), // Día del mes
                      ),
                      title: Text("$userName (${reserva['personas']} pax)"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${DateFormat('EEEE, h:mm a', 'es_ES').format(fecha)}"),
                          if (reserva['nota'] != null) 
                            Text("Nota: ${reserva['nota']}", style: const TextStyle(color: Colors.red)),
                          Text("Tel: $userTel", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.grey),
                        onPressed: () async {
                          // Admin puede borrar sin restricción de 24h
                           await supabase.from('reservas').delete().eq('id', reserva['id']);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}