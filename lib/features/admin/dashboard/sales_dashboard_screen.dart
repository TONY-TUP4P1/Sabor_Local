import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart'; // supabase

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  // Variables para las métricas
  double _ventasHoy = 0.0;
  int _pedidosHoy = 0;
  double _ticketPromedio = 0.0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosDelDia();
  }

  Future<void> _cargarDatosDelDia() async {
    try {
      // 1. Definir rango de tiempo: Desde las 00:00 de hoy hasta mañana
      final now = DateTime.now();
      final inicioDia = DateTime(now.year, now.month, now.day).toIso8601String();
      final finDia = DateTime(now.year, now.month, now.day + 1).toIso8601String();

      // 2. Consultar pedidos de HOY que no estén cancelados (si tuviéramos estado 'cancelado')
      // Para este MVP sumamos todo lo que no sea 'pendiente' (asumiendo que pendiente es venta no cerrada)
      final response = await supabase
          .from('pedidos')
          .select('total, estado')
          .gte('created_at', inicioDia)
          .lt('created_at', finDia)
          .neq('estado', 'pendiente'); // Solo contamos lo que entró a cocina o se entregó

      final data = response as List<dynamic>;

      double totalVentas = 0;
      int cantidadPedidos = data.length;

      for (var pedido in data) {
        totalVentas += (pedido['total'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _ventasHoy = totalVentas;
          _pedidosHoy = cantidadPedidos;
          _ticketPromedio = cantidadPedidos > 0 ? totalVentas / cantidadPedidos : 0;
          _cargando = false;
        });
      }
    } catch (e) {
      print("Error cargando reporte: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaHoy = DateFormat('EEEE d, MMMM', 'es_ES').format(DateTime.now()); 
    // Nota: Si no tienes configurado el locale español, saldrá en inglés. No es crítico.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumen de Ventas"),
        backgroundColor: const Color(0xFF1A237E), // Azul oscuro corporativo
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _cargando = true);
              _cargarDatosDelDia();
            },
          )
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Resultados de Hoy",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  Text(
                    fechaHoy, // Ej: Lunes 12, Octubre
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 20),

                  // TARJETAS DE MÉTRICAS (KPIs)
                  Row(
                    children: [
                      // Tarjeta 1: Ventas Totales
                      Expanded(
                        child: _KpiCard(
                          titulo: "Venta Total",
                          valor: "S/ ${_ventasHoy.toStringAsFixed(2)}",
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Tarjeta 2: Cantidad Pedidos
                      Expanded(
                        child: _KpiCard(
                          titulo: "Pedidos",
                          valor: "$_pedidosHoy",
                          icon: Icons.receipt,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Tarjeta 3: Ticket Promedio
                  _KpiCard(
                    titulo: "Ticket Promedio (Gasto por cliente)",
                    valor: "S/ ${_ticketPromedio.toStringAsFixed(2)}",
                    icon: Icons.pie_chart,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  // SECCIÓN: OBJETIVO DEL DÍA (Gamificación simple)
                  const Text("Objetivo Diario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (_ventasHoy / 1000).clamp(0.0, 1.0), // Meta ficticia de 1000 soles
                    minHeight: 15,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Colors.grey[300],
                    color: const Color(0xFFC45A34),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Meta: S/ 1,000.00 (${((_ventasHoy / 1000) * 100).toStringAsFixed(1)}%)",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }
}

// Widget auxiliar para las tarjetas bonitas
class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 15),
          Text(titulo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
    );
  }
}