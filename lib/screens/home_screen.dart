import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';

// ✅ Sprint 2 screens
import 'events/event_list_screen.dart';
import 'events/my_events_screen.dart';
import 'events/create_edit_event_screen.dart';

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

        // =========================
        // PÁGINAS POR ROL
        // =========================
        late final List<Widget> pages;
        late final List<NavigationDestination> destinations;

        if (role == 'estudiante') {
          pages = [
            EventListScreen(isAdmin: false, currentUid: u.uid),
            const Center(child: Text('Mis registros (Sprint 3)')),
            const ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event), label: 'Eventos'),
            NavigationDestination(icon: Icon(Icons.check_circle), label: 'Mis registros'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else if (role == 'organizador') {
          pages = [
            MyEventsScreen(currentUid: u.uid),
            const CreateEditEventScreen(),
            const ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event_note), label: 'Mis eventos'),
            NavigationDestination(icon: Icon(Icons.add_box), label: 'Crear'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else {
          // admin
          pages = [
            EventListScreen(isAdmin: true, currentUid: u.uid),
            const Center(child: Text('Gestión admin (Sprint 3)')),
            const ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event_available), label: 'Eventos'),
            NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Gestión'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        }

        // Evitar out-of-range si cambia el rol o cambian tabs
        if (index >= pages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => index = 0);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Hola, ${u.name} (${u.role})'),
            actions: [
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
