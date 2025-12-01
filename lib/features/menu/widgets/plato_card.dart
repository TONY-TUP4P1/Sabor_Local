import 'package:flutter/material.dart';
import '../../../data/models/plato_model.dart';

class PlatoCard extends StatelessWidget {
  final Plato plato;
  final VoidCallback onTap; // Para cuando toquen el plato (ver detalle)

  const PlatoCard({super.key, required this.plato, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Para que la imagen respete los bordes redondeados
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen del plato
            SizedBox(
              height: 150,
              width: double.infinity,
              child: plato.imagenUrl != null
                  ? Image.network(
                      plato.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stack) => 
                          Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.restaurant)),
            ),
            
            // 2. Información
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plato.nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (plato.esFestivo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8B948), // Mostaza
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Festivo", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plato.descripcion ?? "Sin descripción",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "S/ ${plato.precio.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFC45A34), // Terracota
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.add_circle, color: Color(0xFFC45A34)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}