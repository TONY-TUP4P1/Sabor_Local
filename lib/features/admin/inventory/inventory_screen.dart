import 'package:flutter/material.dart';
import '../../../../main.dart'; // supabase

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Escuchamos la tabla ingredientes
  final _stockStream = supabase
      .from('ingredientes')
      .stream(primaryKey: ['id'])
      .order('nombre', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Stock"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      // Botón para añadir nuevo ingrediente (Compra de mercado)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () => _mostrarDialogoEditar(context, null),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stockStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final ingredientes = snapshot.data!;

          if (ingredientes.isEmpty) return const Center(child: Text("Inventario vacío."));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ingredientes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = ingredientes[index];
              final stock = (item['stock_actual'] as num).toDouble();
              final minimo = (item['stock_minimo'] as num).toDouble();
              final esCritico = stock <= minimo;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: esCritico ? Colors.red[100] : Colors.green[100],
                  child: Icon(
                    esCritico ? Icons.warning : Icons.inventory_2,
                    color: esCritico ? Colors.red : Colors.green[800],
                  ),
                ),
                title: Text(
                  item['nombre'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Mínimo requerido: $minimo ${item['unidad_medida']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de cantidad grande
                    Text(
                      "$stock ${item['unidad_medida']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: esCritico ? Colors.red : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botón editar
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialogoEditar(context, item),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // DIÁLOGO PARA CREAR O ACTUALIZAR STOCK
  void _mostrarDialogoEditar(BuildContext context, Map<String, dynamic>? item) {
    final esEdicion = item != null;
    final nombreCtrl = TextEditingController(text: esEdicion ? item['nombre'] : '');
    final stockCtrl = TextEditingController(text: esEdicion ? item['stock_actual'].toString() : '');
    final minCtrl = TextEditingController(text: esEdicion ? item['stock_minimo'].toString() : '');
    final unidadCtrl = TextEditingController(text: esEdicion ? item['unidad_medida'] : 'kg');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? "Actualizar Stock" : "Nuevo Ingrediente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre (ej: Papas)"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Stock Actual"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unidadCtrl,
                      decoration: const InputDecoration(labelText: "Unidad (kg/lt)"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Alerta Stock Mínimo"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final datos = {
                'nombre': nombreCtrl.text,
                'stock_actual': double.tryParse(stockCtrl.text) ?? 0,
                'stock_minimo': double.tryParse(minCtrl.text) ?? 0,
                'unidad_medida': unidadCtrl.text,
              };

              if (esEdicion) {
                await supabase.from('ingredientes').update(datos).eq('id', item['id']);
              } else {
                await supabase.from('ingredientes').insert(datos);
              }
              
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("GUARDAR"),
          )
        ],
      ),
    );
  }
}