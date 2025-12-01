import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/supabase_constants.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/cart/logic/cart_provider.dart';
import 'features/admin/kitchen/kitchen_screen.dart'; // Importa la pantalla cocina
import 'features/menu/screens/menu_screen.dart';    // Importa el menú
import 'features/admin/admin_home_screen.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await initializeDateFormatting('es_ES', null);

  runApp(
    // Inyectamos el AuthProvider en toda la app
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const SaborLocalApp(),
    ),
  );
}

class SaborLocalApp extends StatelessWidget {
  const SaborLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaborLocal',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (por si acaso)
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC45A34),
          primary: const Color(0xFFC45A34),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.merriweatherTextTheme(),
      ),
      // AuthGate: Escucha si hay sesión
      home: const AuthGate(), 
      //home: const MenuScreen(),
    );
  }
}

// Esta clase decide qué pantalla mostrar
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Cargando inicial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        // 2. Si hay sesión, averiguamos el ROL del usuario
        if (session != null) {
          return FutureBuilder<Map<String, dynamic>>(
            // Consultamos la tabla 'profiles' buscando el rol
            future: supabase
                .from('profiles')
                .select('rol')
                .eq('id', session.user.id)
                .single(),
            builder: (context, snapshot) {
              // Mientras busca el rol...
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Colors.orange)),
                );
              }

              // AGREGAMOS ESTOS PRINTS PARA VER EN LA CONSOLA DE VSCODE
              if (snapshot.hasError) {
                print("❌ ERROR LEYENDO ROL: ${snapshot.error}");
                return const MenuScreen();
              }

              if (!snapshot.hasData) {
                print("⚠️ NO HAY DATOS EN PERFIL (¿RLS Bloqueado?)");
                return const MenuScreen();
              }

              final data = snapshot.data!;
              final rol = data['rol'];
              print("✅ ROL ENCONTRADO EN BD: $rol"); // <--- Esto es lo que queremos ver

              if (rol == 'admin') {
                return const AdminHomeScreen(); // <--- NUEVA RUTA
              } else if (rol == 'cocina') {
                return const KitchenScreen();
              } else {
                return const MenuScreen();
              }
            },
          );
        }

        // 3. Si NO hay sesión -> Login
        return const LoginScreen();
      },
    );
  }
}