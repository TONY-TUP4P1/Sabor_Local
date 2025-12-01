import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';

class ClientReservationsScreen extends StatefulWidget {
  const ClientReservationsScreen({super.key});

  @override
  State<ClientReservationsScreen> createState() => _ClientReservationsScreenState();
}

class _ClientReservationsScreenState extends State<ClientReservationsScreen> {
  // Stream: Mis reservas futuras (ordenadas por fecha)
  final _myReservasStream = supabase
      .from('reservas')
      .stream(primaryKey: ['id'])
      .eq('user_id', supabase.auth.currentUser!.id)
      .order('fecha_hora', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Reservas")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _myReservasStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reservas = snapshot.data!;

          if (reservas.isEmpty) {
            return const Center(child: Text("No tienes reservas activas."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index];
              return _ReservaCard(reserva: reserva);
            },
          );
        },
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Map<String, dynamic> reserva;

  const _ReservaCard({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final fechaReserva = DateTime.parse(reserva['fecha_hora']).toLocal();
    final ahora = DateTime.now();
    
    // LÓGICA DE LAS 24 HORAS
    // Calculamos la diferencia entre la fecha de la reserva y el momento actual
    final diferencia = fechaReserva.difference(ahora);
    final puedeEditar = diferencia.inHours >= 24;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      // Si ya pasó la fecha, la ponemos gris
      color: fechaReserva.isBefore(ahora) ? Colors.grey[200] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: puedeEditar ? Colors.orange : Colors.grey),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE d MMMM, y', 'es_ES').format(fechaReserva),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        DateFormat('h:mm a').format(fechaReserva),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFC45A34)),
                      ),
                      Text("Mesa para ${reserva['personas']} personas"),
                      if (reserva['nota'] != null && reserva['nota'].isNotEmpty)
                        Text("Nota: ${reserva['nota']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // ZONA DE ACCIONES (Botones o Mensaje de Bloqueo)
            if (puedeEditar)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Reprogramar"),
                    onPressed: () => _reprogramarFecha(context, reserva),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text("Cancelar"),
                    onPressed: () => _cancelarReserva(context, reserva['id']),
                  ),
                ],
              )
            else if (fechaReserva.isAfter(ahora))
              // Si es futuro pero faltan menos de 24h
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No se puede modificar (menos de 24h de antelación). Llame al restaurante.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text("Reserva pasada", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelarReserva(BuildContext context, int id) async {
    // Confirmación simple
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cancelar Reserva?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Volver")),
          TextButton(
            child: const Text("CANCELAR", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              await supabase.from('reservas').delete().eq('id', id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva eliminada")));
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _reprogramarFecha(BuildContext context, Map<String, dynamic> reserva) async {
    // Reutilizamos lógica básica de DatePicker para actualizar
    DateTime fechaActual = DateTime.parse(reserva['fecha_hora']);
    
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaActual,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('es', 'ES'),
    );

    if (nuevaFecha != null && context.mounted) {
      final nuevaHora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaActual),
      );

      if (nuevaHora != null) {
        final fechaHoraFinal = DateTime(
          nuevaFecha.year, nuevaFecha.month, nuevaFecha.day,
          nuevaHora.hour, nuevaHora.minute,
        );

        await supabase
            .from('reservas')
            .update({'fecha_hora': fechaHoraFinal.toIso8601String()})
            .eq('id', reserva['id']);
            
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva reprogramada")));
        }
      }
    }
  }
}