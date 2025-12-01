import 'package:flutter/material.dart';
import '../../../data/models/plato_model.dart';
import '../../../main.dart';

// Clase auxiliar para saber qué y cuánto lleva
class CartItem {
  final Plato plato;
  int cantidad;

  CartItem({required this.plato, this.cantidad = 1});

  double get total => plato.precio * cantidad;
}

class CartProvider extends ChangeNotifier {
  // Mapa para guardar los items: ID del plato -> Item del Carrito
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  // Cantidad total de productos (para el numerito rojo en el ícono)
  int get itemCount => _items.length;

  // Precio total de la cuenta
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.total;
    });
    return total;
  }

  Future<bool> confirmarPedido() async {
    // 1. Verificamos que haya usuario logueado
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw "Debes iniciar sesión para pedir.";
    }

    try {
      // 2. Insertamos la CABECERA (Tabla 'pedidos')
      // .select() al final es vital para que nos devuelva el ID del pedido creado
      final response = await supabase.from('pedidos').insert({
        'user_id': user.id,
        'total': totalAmount, // Usamos el getter que ya calculaba el total
        'estado': 'pendiente',
        'tipo_entrega': 'delivery',
        'created_at': DateTime.now().toIso8601String(),
      }).select().single(); // .single() nos da el mapa directo, no una lista

      final nuevoPedidoId = response['id'];

      // 3. Preparamos los DETALLES (Tabla 'detalle_pedido')
      final List<Map<String, dynamic>> detallesParaInsertar = [];
      
      _items.forEach((key, cartItem) {
        detallesParaInsertar.add({
          'pedido_id': nuevoPedidoId,
          'plato_id': cartItem.plato.id,
          'cantidad': cartItem.cantidad,
          'precio_unitario': cartItem.plato.precio, // Guardamos el precio al momento de la compra
        });
      });

      // 4. Insertamos todos los detalles de una sola vez
      await supabase.from('detalle_pedido').insert(detallesParaInsertar);

      // 5. Limpiamos el carrito local
      clear(); 
      return true; // Todo salió bien

    } catch (e) {
      print("Error creando pedido: $e");
      return false; // Algo falló
    }
  }

  // AGREGAR AL CARRITO
  void addItem(Plato plato) {
    if (_items.containsKey(plato.id)) {
      // Si ya existe, aumentamos la cantidad
      _items.update(
        plato.id,
        (existingItem) => CartItem(
          plato: existingItem.plato,
          cantidad: existingItem.cantidad + 1,
        ),
      );
    } else {
      // Si es nuevo, lo agregamos
      _items.putIfAbsent(
        plato.id,
        () => CartItem(plato: plato),
      );
    }
    notifyListeners(); // ¡Avisar a la pantalla que actualice!
  }

  // QUITAR UN ITEM (Disminuir cantidad o borrar)
  void removeSingleItem(int platoId) {
    if (!_items.containsKey(platoId)) return;

    if (_items[platoId]!.cantidad > 1) {
      _items.update(
        platoId,
        (existingItem) => CartItem(
          plato: existingItem.plato,
          cantidad: existingItem.cantidad - 1,
        ),
      );
    } else {
      _items.remove(platoId);
    }
    notifyListeners();
  }

  // LIMPIAR CARRITO (Después de pagar)
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  void cargarItemsParaEditar(List<Plato> platosLista) {
    // 1. Limpiamos el carrito actual para no mezclar
    clear(); 
    
    // 2. Agregamos los platos recuperados
    for (var plato in platosLista) {
      addItem(plato); 
    }
    notifyListeners();
  }
}