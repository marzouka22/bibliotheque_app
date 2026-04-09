import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/evenement_controller.dart';
import '../../models/evenement.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_appbar.dart'; // inclut LoadingWidget, EmptyStateWidget, SectionTitre
import '../admin/ajouter_evenement_screen.dart';

/// Écran des événements avec calendrier interactif
class EvenementsScreen extends StatefulWidget {
  const EvenementsScreen({super.key});

  @override
  State<EvenementsScreen> createState() => _EvenementsScreenState();
}

class _EvenementsScreenState extends State<EvenementsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvenementController>().ecouterEvenements();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Evenement> _evenementsDuJour(List<Evenement> tous, DateTime jour) {
    return tous.where((e) => isSameDay(e.dateDebut, jour)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titre: 'Événements',
        showBack: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Calendrier'),
            Tab(text: 'Liste'),
          ],
        ),
      ),
      body: Consumer<EvenementController>(
        builder: (_, ctrl, __) {
          if (ctrl.isLoading) return const LoadingWidget();
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildCalendrier(ctrl),
              _buildListe(ctrl),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (_, auth, __) => auth.membre?.estAdmin == true
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AjouterEvenementScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nouvel événement'),
                backgroundColor: AppColors.primary,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCalendrier(EvenementController ctrl) {
    return Column(
      children: [
        TableCalendar<Evenement>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: (day) => _evenementsDuJour(ctrl.evenements, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
 fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Builder(
            builder: (_) {
              final evenementsDuJour = _selectedDay != null
                  ? _evenementsDuJour(ctrl.evenements, _selectedDay!)
                  : [];

              if (evenementsDuJour.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.event_available,
                  titre: 'Aucun événement ce jour',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: evenementsDuJour.length,
                itemBuilder: (_, i) =>
                    _EvenementCard(evenement: evenementsDuJour[i] as Evenement),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListe(EvenementController ctrl) {
    final aVenir = ctrl.evenementsAVenir;
    final passes = ctrl.evenementsPasses;

    if (aVenir.isEmpty && passes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.event_busy,
        titre: 'Aucun événement',
        sousTitre: 'Les événements à venir apparaîtront ici',
      );
    }

    return ListView(
      children: [
        if (aVenir.isNotEmpty) ...[
          const SectionTitre(titre: 'À venir'),
          ...aVenir.map((e) => _EvenementCard(evenement: e)),
        ],
        if (passes.isNotEmpty) ...[
          const SectionTitre(titre: 'Passés'),
          ...passes.take(5).map((e) => _EvenementCard(evenement: e)),
        ],
      ],
    );
  }
}

/// Carte d'un événement
class _EvenementCard extends StatelessWidget {
  final Evenement evenement;

  const _EvenementCard({required this.evenement});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<EvenementController>();
    final estInscrit = auth.uid != null &&
        ctrl.estInscrit(evenement, auth.uid!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header coloré selon le type
          Container(
            decoration: BoxDecoration(
              color: _typeColor(evenement.type).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(_typeIcon(evenement.type),
                    color: _typeColor(evenement.type), size: 20),
                const SizedBox(width: 8),
                Text(
                  evenement.type.label,
                  style: TextStyle(
                      color: _typeColor(evenement.type),
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (evenement.estAnnule)
                  const Chip(
                    label: Text('Annulé',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evenement.titre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                _infoRow(Icons.schedule,
                    '${Helpers.formatDateHeure(evenement.dateDebut)} — ${Helpers.formatHeure(evenement.dateFin)}'),
                const SizedBox(height: 4),
                _infoRow(Icons.location_on_outlined, evenement.lieu),
                const SizedBox(height: 4),
                _infoRow(Icons.person_outline, evenement.organisateurNom),
                if (evenement.capaciteMax != null) ...[
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.people_outline,
                    '${evenement.nbInscrits}/${evenement.capaciteMax} inscrits',
                    color: evenement.placesDispo
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ],
                const SizedBox(height: 8),
                Text(evenement.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                // Bouton inscription
                if (!evenement.estPasse && !evenement.estAnnule && auth.estConnecte)
                  SizedBox(
                    width: double.infinity,
                    child: estInscrit
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              await ctrl.seDesinscrire(
                                  evenement.id, auth.uid!);
                              if (context.mounted) {
                                Helpers.showInfo(
                                    context, 'Désinscription effectuée.');
                              }
                            },
                            icon: const Icon(Icons.event_busy_outlined,
                                size: 16),
                            label: const Text('Se désinscrire'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error),
                          )
                        : ElevatedButton.icon(
                            onPressed: evenement.placesDispo
                                ? () async {
                                    final ok = await ctrl.sInscrire(
                                        evenement.id, auth.uid!);
                                    if (context.mounted) {
                                      ok
                                          ? Helpers.showSuccess(context,
                                              'Inscription confirmée !')
                                          : Helpers.showError(context,
                                              ctrl.errorMessage ?? 'Erreur');
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.how_to_reg, size: 16),
                            label: Text(evenement.placesDispo
                                ? 'S\'inscrire'
                                : 'Complet'),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, color: color ?? AppColors.textSecondary)),
        ),
      ],
    );
  }

  Color _typeColor(TypeEvenement type) {
    switch (type) {
      case TypeEvenement.lecture:
        return AppColors.primary;
      case TypeEvenement.conference:
        return AppColors.accent;
      case TypeEvenement.atelier:
        return AppColors.success;
      case TypeEvenement.exposition:
        return AppColors.secondary;
      case TypeEvenement.club:
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(TypeEvenement type) {
    switch (type) {
      case TypeEvenement.lecture:
        return Icons.menu_book;
      case TypeEvenement.conference:
        return Icons.mic;
      case TypeEvenement.atelier:
        return Icons.handyman;
      case TypeEvenement.exposition:
        return Icons.art_track;
      case TypeEvenement.club:
        return Icons.groups;
      default:
        return Icons.event;
    }
  }
}
