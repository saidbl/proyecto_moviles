import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final auth = AuthService();
  final userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser>(
      stream: userService.streamMe(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final u = snap.data!;
        final role = u.role;

        // Páginas por rol
        final List<Widget> pages;
        final List<NavigationDestination> destinations;

        if (role == 'estudiante') {
          pages = const [
            Center(child: Text('Eventos (Sprint 2)')),
            Center(child: Text('Mis registros (Sprint 4)')),
            ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event), label: 'Eventos'),
            NavigationDestination(icon: Icon(Icons.check_circle), label: 'Mis registros'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else if (role == 'organizador') {
          pages = const [
            Center(child: Text('Mis eventos (Sprint 2)')),
            Center(child: Text('Crear evento (Sprint 2)')),
            ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event_note), label: 'Mis eventos'),
            NavigationDestination(icon: Icon(Icons.add_box), label: 'Crear'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else {
          // admin
          pages = const [
            Center(child: Text('Todos los eventos (Sprint 2)')),
            Center(child: Text('Gestión admin (Sprint 2/3)')),
            ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event_available), label: 'Eventos'),
            NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Gestión'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        }

        // Evitar out of range si cambias rol
        if (index >= pages.length) index = 0;

        return Scaffold(
          appBar: AppBar(
            title: Text('Hola, ${u.name} (${u.role})'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    role,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () async => auth.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: pages[index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
