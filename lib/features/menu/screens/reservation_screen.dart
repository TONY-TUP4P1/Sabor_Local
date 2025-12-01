import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'client_reservations_screen.dart';
import '../../../../main.dart'; // supabase

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1)); // Mañana por defecto
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 13, minute: 00); // 1:00 PM
  int _personas = 2;
  final _notaCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es', 'ES'), // Para calendario en español
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (picked != null) setState(() => _horaSeleccionada = picked);
  }

  Future<void> _guardarReserva() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "Debes iniciar sesión";

      // Combinar Fecha y Hora en un solo objeto DateTime
      final fechaHoraFinal = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      await supabase.from('reservas').insert({
        'user_id': user.id,
        'fecha_hora': fechaHoraFinal.toIso8601String(),
        'personas': _personas,
        'nota': _notaCtrl.text,
        'estado': 'confirmada',
      });

      if (mounted) {
        Navigator.pop(context); // Cerrar pantalla
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ ¡Mesa reservada con éxito!")),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar Mesa"),
        backgroundColor: const Color(0xFFC45A34),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: const Text("Mis Reservas", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientReservationsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Cuándo vienes?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // SELECTOR DE FECHA
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Color(0xFFC45A34)),
              title: Text(DateFormat('EEEE d, MMMM y', 'es_ES').format(_fechaSeleccionada)),
              subtitle: const Text("Toca para cambiar fecha"),
              onTap: _seleccionarFecha,
            ),
            const Divider(),

            // SELECTOR DE HORA
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: Color(0xFFC45A34)),
              title: Text(_horaSeleccionada.format(context)),
              subtitle: const Text("Toca para cambiar hora"),
              onTap: _seleccionarHora,
            ),
            const Divider(),

            const SizedBox(height: 20),
            const Text("¿Cuántos son?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            // SELECTOR DE PERSONAS
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _personas > 1 ? () => setState(() => _personas--) : null,
                ),
                Text("$_personas personas", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _personas < 20 ? () => setState(() => _personas++) : null,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            TextField(
              controller: _notaCtrl,
              decoration: const InputDecoration(
                labelText: "Notas (Opcional)",
                hintText: "Ej: Necesito silla para bebé",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC45A34), 
                  foregroundColor: Colors.white
                ),
                onPressed: _isLoading ? null : _guardarReserva,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CONFIRMAR RESERVA"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}