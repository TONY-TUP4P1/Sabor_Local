import 'package:flutter/material.dart';
import '../../../../main.dart'; // supabase

class EditDishScreen extends StatefulWidget {
  final Map<String, dynamic>? platoData; // null = Crear, Map = Editar

  const EditDishScreen({super.key, this.platoData});

  @override
  State<EditDishScreen> createState() => _EditDishScreenState();
}

class _EditDishScreenState extends State<EditDishScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores del Plato
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();

  // Controladores para agregar ingredientes
  final _cantidadIngredienteCtrl = TextEditingController();
  Map<String, dynamic>? _ingredienteSeleccionado; // El objeto del dropdown

  // Estado
  bool _isLoading = false;
  List<Map<String, dynamic>> _todosLosIngredientes = []; // Lista para el Dropdown
  List<Map<String, dynamic>> _recetaActual = []; // La lista que estamos armando visualmente

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar catálogo de ingredientes para el dropdown
      final responseIngredientes = await supabase
          .from('ingredientes')
          .select('id, nombre, unidad_medida')
          .order('nombre');
      
      // 2. Si estamos EDITANDO, cargar la receta existente
      if (widget.platoData != null) {
        _nombreCtrl.text = widget.platoData!['nombre'];
        _descCtrl.text = widget.platoData!['descripcion'] ?? '';
        _precioCtrl.text = widget.platoData!['precio'].toString();
        _imgCtrl.text = widget.platoData!['imagen_url'] ?? '';

        final responseReceta = await supabase
            .from('recetas')
            .select('cantidad_requerida, ingredientes(id, nombre, unidad_medida)')
            .eq('plato_id', widget.platoData!['id']);
        
        // Convertimos la respuesta de Supabase a nuestra estructura local
        final dataReceta = responseReceta as List<dynamic>;
        for (var item in dataReceta) {
          final ing = item['ingredientes'];
          _recetaActual.add({
            'ingrediente_id': ing['id'],
            'nombre': ing['nombre'],
            'unidad': ing['unidad_medida'],
            'cantidad': (item['cantidad_requerida'] as num).toDouble(),
          });
        }
      }

      setState(() {
        _todosLosIngredientes = List<Map<String, dynamic>>.from(responseIngredientes);
        _isLoading = false;
      });

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cargando: $e")));
      setState(() => _isLoading = false);
    }
  }

  // Agregar ingrediente a la lista local (Memoria)
  void _agregarIngredienteALista() {
    if (_ingredienteSeleccionado == null || _cantidadIngredienteCtrl.text.isEmpty) return;

    final cantidad = double.tryParse(_cantidadIngredienteCtrl.text);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cantidad inválida")));
      return;
    }

    setState(() {
      // Verificamos si ya existe para sumarlo o agregarlo
      final existe = _recetaActual.indexWhere((e) => e['ingrediente_id'] == _ingredienteSeleccionado!['id']);
      
      if (existe != -1) {
        // Si ya está, actualizamos la cantidad
        _recetaActual[existe]['cantidad'] = cantidad; 
      } else {
        // Nuevo item
        _recetaActual.add({
          'ingrediente_id': _ingredienteSeleccionado!['id'],
          'nombre': _ingredienteSeleccionado!['nombre'],
          'unidad': _ingredienteSeleccionado!['unidad_medida'],
          'cantidad': cantidad,
        });
      }
      
      // Limpiar campos pequeños
      _ingredienteSeleccionado = null;
      _cantidadIngredienteCtrl.clear();
    });
  }

  void _quitarIngrediente(int index) {
    setState(() {
      _recetaActual.removeAt(index);
    });
  }

  Future<void> _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. GUARDAR EL PLATO (Cabecera)
      final datosPlato = {
        'nombre': _nombreCtrl.text,
        'descripcion': _descCtrl.text,
        'precio': double.parse(_precioCtrl.text),
        'imagen_url': _imgCtrl.text,
        'activo': widget.platoData?['activo'] ?? true,
      };

      int platoId;

      if (widget.platoData == null) {
        // CREAR
        final res = await supabase.from('platos').insert(datosPlato).select().single();
        platoId = res['id'];
      } else {
        // ACTUALIZAR
        platoId = widget.platoData!['id'];
        await supabase.from('platos').update(datosPlato).eq('id', platoId);
        
        // Borramos receta vieja para reescribirla (Estrategia simple)
        await supabase.from('recetas').delete().eq('plato_id', platoId);
      }

      // 2. GUARDAR LA RECETA (Detalle)
      if (_recetaActual.isNotEmpty) {
        final listaParaInsertar = _recetaActual.map((item) => {
          'plato_id': platoId,
          'ingrediente_id': item['ingrediente_id'],
          'cantidad_requerida': item['cantidad'],
        }).toList();

        await supabase.from('recetas').insert(listaParaInsertar);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Plato y receta guardados")));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.platoData != null;

    if (_isLoading && _todosLosIngredientes.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Plato y Receta" : "Nuevo Plato"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN 1: DATOS DEL PLATO ---
              const Text("Información General", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre del Plato", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Precio (S/)", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imgCtrl,
                decoration: const InputDecoration(labelText: "URL Imagen", border: OutlineInputBorder()),
              ),
              
              const Divider(height: 40, thickness: 2),

              // --- SECCIÓN 2: RECETA ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ingredientes (Receta)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  // Botón para ir al inventario rápido si falta algo
                  TextButton.icon(
                    icon: const Icon(Icons.add_link),
                    label: const Text("Crear Insumo"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ve a Gestión > Inventario para crear nuevos insumos")));
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),

              // Buscador / Dropdown de Ingredientes
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _ingredienteSeleccionado,
                      isExpanded: true,
                      hint: const Text("Selecciona insumo..."),
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                      items: _todosLosIngredientes.map((ing) {
                        return DropdownMenuItem(
                          value: ing,
                          child: Text("${ing['nombre']} (${ing['unidad_medida']})"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _ingredienteSeleccionado = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _cantidadIngredienteCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Cant.",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: _agregarIngredienteALista,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),

              // Lista visual de la receta
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: _recetaActual.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("Sin ingredientes añadidos", style: TextStyle(color: Colors.grey))),
                      )
                    : ListView.separated(
                        shrinkWrap: true, // Importante para estar dentro de Column
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recetaActual.length,
                        separatorBuilder: (_,__) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _recetaActual[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.restaurant, color: Colors.orange, size: 20),
                            title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${item['cantidad']} ${item['unidad']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  onPressed: () => _quitarIngrediente(index),
                                )
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 30),

              // BOTÓN GUARDAR FINAL
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC45A34), foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _guardarTodo,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("GUARDAR PLATO Y RECETA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}