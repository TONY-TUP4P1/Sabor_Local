import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'dashboard/sales_dashboard_screen.dart';
import 'menu_management/admin_menu_screen.dart';
import 'users/user_management_screen.dart';
import 'kitchen/kitchen_screen.dart'; // El admin también puede querer ver la cocina
import 'inventory/inventory_screen.dart';
import 'reservations/admin_reservations_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Gerencia"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _AdminCard(
            title: "Reporte Ventas",
            icon: Icons.bar_chart,
            color: Colors.blue[800]!,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesDashboardScreen())),
          ),
          _AdminCard(
            title: "Gestionar Menú",
            icon: Icons.restaurant_menu,
            color: Colors.orange[800]!,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMenuScreen())),
          ),
          _AdminCard(
            title: "Personal y Roles",
            icon: Icons.people_alt,
            color: Colors.purple[800]!,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
          ),
          // NUEVA TARJETA: INVENTARIO
          _AdminCard(
            title: "Inventario",
            icon: Icons.inventory,
            color: Colors.teal[700]!, // Color verde azulado
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
          ),
          _AdminCard(
            title: "Ver Cocina",
            icon: Icons.soup_kitchen,
            color: Colors.green[800]!,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenScreen())),
          ),
          _AdminCard(
            title: "Reservas",
            icon: Icons.calendar_today,
            color: Colors.purple[700]!,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReservationsScreen())),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}