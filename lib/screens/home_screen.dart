import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
// ✅ Sprint 2 screens
import 'events/event_list_screen.dart';
import 'events/my_events_screen.dart';
import 'events/create_edit_event_screen.dart';
import 'events/my_registrations_screen.dart';
import 'admin/admin_stats_screen.dart';
import 'organizer_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final auth = AuthService();
  final userService = UserService();
  final notificationService = NotificationService();


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

        final bool isStudent = role == 'estudiante';
        final bool isOrganizer = role == 'organizador';
        final bool isAdmin = role == 'admin';

        late final List<Widget> pages;
        late final List<NavigationDestination> destinations;

        if (isStudent) {
          pages = [
            EventListScreen(
              isAdmin: false,
              currentUid: u.uid,
              canRegister: true,
            ),
            const MyRegistrationsScreen(), // ✅ aqui
            const ProfileScreen(),
            const CalendarScreen(),   // 📅
            const HistoryScreen(),    
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event), label: 'Eventos'),
            NavigationDestination(icon: Icon(Icons.check_circle), label: 'Mis registros'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
            NavigationDestination(
  icon: Icon(Icons.calendar_today),
  label: 'Calendario',
),
NavigationDestination(
  icon: Icon(Icons.history),
  label: 'Historial',
),

          ];
        } else if (isOrganizer) {
          pages = [
            MyEventsScreen(currentUid: u.uid),
            const CreateEditEventScreen(),
            const ProfileScreen(),
            const OrganizerStatsScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event_note), label: 'Mis eventos'),
            NavigationDestination(icon: Icon(Icons.add_box), label: 'Crear'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
            NavigationDestination(icon: Icon(Icons.query_stats), label: 'Estadísticas'),
          ];
        } else if (isAdmin) {
          pages = [
            EventListScreen(
              isAdmin: true,
              currentUid: u.uid,
              canRegister: false, // ✅ admin NO se registra a eventos
            ),
            const AdminStatsScreen(),
            const ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.event_available), label: 'Eventos'),
            NavigationDestination(icon: Icon(Icons.query_stats), label: 'Estadísticas'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else {
          // fallback por si llega un rol raro
          pages = const [
            Center(child: Text('Rol no válido')),
            ProfileScreen(),
          ];
          destinations = const [
            NavigationDestination(icon: Icon(Icons.error), label: 'Error'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        }

        // Evitar out-of-range si cambian tabs/rol
        if (index >= pages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => index = 0);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Hola, ${u.name} (${u.role})'),
            actions: [

              // 🔔 NOTIFICACIONES
              StreamBuilder<List<AppNotification>>(
                stream: notificationService.getMyNotifications(u.uid),
                builder: (context, snap) {
                  final notifications = snap.data ?? [];
                  final unreadCount =
                      notifications.where((n) => !n.read).length;

                  return Stack(
                    children: [
                      IconButton(
                        tooltip: 'Notificaciones',
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),

                      // 🔴 BADGE SI HAY NO LEÍDAS
                      if (unreadCount > 0)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // 🚪 LOGOUT
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
