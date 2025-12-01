class Plato {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool esFestivo;

  Plato({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.esFestivo,
  });

  // Convierte el JSON de Supabase (Map) a nuestro Objeto Plato
  factory Plato.fromJson(Map<String, dynamic> json) {
    return Plato(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      // Supabase a veces devuelve enteros o flotantes, aseguramos double:
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagen_url'],
      esFestivo: json['es_festivo'] ?? false,
    );
  }
}