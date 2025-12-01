import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // supabase
import '../../features/auth/auth_provider.dart';
import '../../features/profile/screens/order_history_screen.dart';
import '../../features/menu/screens/reservation_screen.dart';
import '../../features/admin/admin_home_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  // Cargamos el nombre y rol para mostrarlo bonito en la cabecera
  Future<void> _cargarPerfil() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        final data = await supabase
            .from('profiles')
            .select('nombre, rol, email')
            .eq('id', uid)
            .single();
        
        if (mounted) {
          setState(() {
            _userProfile = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Si falla, mostramos datos genéricos
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _userProfile?['nombre'] ?? 'Invitado';
    final email = _userProfile?['email'] ?? supabase.auth.currentUser?.email ?? '';
    final rol = _userProfile?['rol'] ?? 'cliente';
    
    // Colores de la marca
    final colorPrimario = const Color(0xFFC45A34); // Terracota
    final colorSecundario = const Color(0xFFE8B948); // Mostaza

    return Drawer(
      backgroundColor: const Color(0xFFFDFBF7), // Crema suave de fondo
      child: Column(
        children: [
          // 1. CABECERA CON DEGRADADO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorPrimario, Colors.brown.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
              ),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : "S",
                    style: TextStyle(fontSize: 30, color: colorPrimario, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  nombre,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorSecundario,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    rol.toString().toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // 2. LISTA DE OPCIONES
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              children: [
                _MenuItem(
                  icon: Icons.restaurant_menu,
                  text: "Menú Principal",
                  color: Colors.orange,
                  onTap: () => Navigator.pop(context), // Cierra menú (ya estamos en home)
                ),
                
                _MenuItem(
                  icon: Icons.shopping_cart,
                  text: "Mi Carrito",
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                ),

                _MenuItem(
                  icon: Icons.receipt_long,
                  text: "Mis Pedidos",
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                ),

                _MenuItem(
                  icon: Icons.calendar_month,
                  text: "Mis Reservas",
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationScreen())),
                ),

                const Divider(height: 30),

                _MenuItem(
                  icon: Icons.settings,
                  text: "Configuración y Perfil",
                  color: Colors.blueGrey,
                  onTap: () async {
                    // Navegamos y esperamos el resultado
                    // Si devuelve 'true', es que cambió datos y hay que recargar
                    final resultado = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const EditProfileScreen())
                    );

                    if (resultado == true && mounted) {
                      _cargarPerfil(); // Recargamos el nombre en la cabecera del menú
                    }
                  },
                ),

                const Divider(height: 30),

                // OPCIÓN ESPECIAL PARA STAFF/ADMIN
                if (rol == 'admin' || rol == 'cocina')
                  _MenuItem(
                    icon: Icons.dashboard,
                    text: "Panel de Gestión",
                    color: Colors.redAccent,
                    isHighlight: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen())),
                  ),
              ],
            ),
          ),

          // 3. BOTÓN SALIR
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.grey),
                label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.grey)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                   context.read<AuthProvider>().signOut();
                   // El AuthGate nos llevará al login
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para que cada item se vea bonito
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;
  final bool isHighlight;

  const _MenuItem({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Fondo suave del color
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          color: isHighlight ? Colors.red.shade800 : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }
}