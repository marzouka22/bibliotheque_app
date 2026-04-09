import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/evenement_controller.dart';
import '../../models/evenement.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AjouterEvenementScreen extends StatefulWidget {
  final Evenement? evenement;
  const AjouterEvenementScreen({super.key, this.evenement});

  @override
  State<AjouterEvenementScreen> createState() =>
      _AjouterEvenementScreenState();
}

class _AjouterEvenementScreenState extends State<AjouterEvenementScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _titreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _lieuCtrl;
  late final TextEditingController _capaciteCtrl;

  TypeEvenement _type = TypeEvenement.lecture;
  DateTime _dateDebut = DateTime.now().add(const Duration(days: 1));
  DateTime _dateFin   = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _estPublic = true;

  @override
  void initState() {
    super.initState();
    final e = widget.evenement;
    _titreCtrl   = TextEditingController(text: e?.titre ?? '');
    _descCtrl    = TextEditingController(text: e?.description ?? '');
    _lieuCtrl    = TextEditingController(text: e?.lieu ?? '');
    _capaciteCtrl = TextEditingController(
        text: e?.capaciteMax?.toString() ?? '');
    if (e != null) {
      _type      = e.type;
      _dateDebut = e.dateDebut;
      _dateFin   = e.dateFin;
      _estPublic = e.estPublic;
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _lieuCtrl.dispose();
    _capaciteCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDateHeure({required bool isDebut}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isDebut ? _dateDebut : _dateFin),
    );
    if (heure == null) return;

    final dt = DateTime(
        date.year, date.month, date.day, heure.hour, heure.minute);
    setState(() {
      if (isDebut) {
        _dateDebut = dt;
        if (_dateFin.isBefore(_dateDebut)) {
          _dateFin = _dateDebut.add(const Duration(hours: 2));
        }
      } else {
        _dateFin = dt;
      }
    });
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateFin.isBefore(_dateDebut)) {
      Helpers.showError(context,
          'La date de fin doit être après la date de début');
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final ctrl = context.read<EvenementController>();

    final evenement = Evenement(
      id: widget.evenement?.id ?? '',
      titre: _titreCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      dateDebut: _dateDebut,
      dateFin: _dateFin,
      lieu: _lieuCtrl.text.trim(),
      capaciteMax: _capaciteCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_capaciteCtrl.text),
      nbInscrits: widget.evenement?.nbInscrits ?? 0,
      participantsIds: widget.evenement?.participantsIds ?? [],
      organisateurId: auth.uid ?? '',
      organisateurNom: auth.membre?.nom ?? 'Admin',
      estPublic: _estPublic,
      estAnnule: widget.evenement?.estAnnule ?? false,
      photos: widget.evenement?.photos ?? [],
      dateCreation: widget.evenement?.dateCreation ?? DateTime.now(),
    );

    try {
      if (widget.evenement == null) {
        await ctrl.creerEvenement(evenement);
        if (mounted) Helpers.showSuccess(context, 'Événement créé !');
      } else {
        await ctrl.modifierEvenement(
            widget.evenement!.id, evenement.toFirestore());
        if (mounted) Helpers.showSuccess(context, 'Événement modifié !');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estModif = widget.evenement != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(estModif ? 'Modifier l\'événement' : 'Créer un événement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : TextButton.icon(
                  onPressed: _sauvegarder,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Enregistrer',
                      style: TextStyle(color: Colors.white)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Informations principales ──
            _sectionLabel('Informations'),
            _champ(
              ctrl: _titreCtrl,
              label: 'Titre de l\'événement *',
              icon: Icons.event,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Titre requis' : null,
            ),
            _champ(
              ctrl: _lieuCtrl,
              label: 'Lieu *',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Lieu requis' : null,
            ),

            // ── Type ──
            const SizedBox(height: 4),
            _sectionLabel('Type d\'événement'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<TypeEvenement>(
                  value: _type,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                    border: InputBorder.none,
                  ),
                  items: TypeEvenement.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
              ),
            ),

            // ── Dates ──
            const SizedBox(height: 8),
            _sectionLabel('Date et heure'),
            _dateTile(
              label: 'Début',
              dt: _dateDebut,
              icon: Icons.play_circle_outline,
              color: AppColors.primary,
              onTap: () => _choisirDateHeure(isDebut: true),
            ),
            const SizedBox(height: 8),
            _dateTile(
              label: 'Fin',
              dt: _dateFin,
              icon: Icons.stop_circle_outlined,
              color: AppColors.accent,
              onTap: () => _choisirDateHeure(isDebut: false),
            ),

            // ── Capacité ──
            const SizedBox(height: 8),
            _sectionLabel('Capacité (optionnel)'),
            _champ(
              ctrl: _capaciteCtrl,
              label: 'Nombre de places max',
              icon: Icons.people_outline,
              keyboardType: TextInputType.number,
            ),

            // ── Visibilité ──
            Card(
              child: SwitchListTile(
                value: _estPublic,
                onChanged: (v) => setState(() => _estPublic = v),
                title: const Text('Événement public'),
                subtitle: const Text('Visible par tous les utilisateurs'),
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.public,
                    color: AppColors.primary),
              ),
            ),

            // ── Description ──
            const SizedBox(height: 8),
            _sectionLabel('Description'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: _descCtrl,
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Description requise'
                          : null,
                  decoration: const InputDecoration(
                    labelText: 'Description de l\'événement *',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.notes_outlined),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sauvegarder,
              icon: const Icon(Icons.save_outlined),
              label: Text(estModif
                  ? 'Modifier l\'événement'
                  : 'Créer l\'événement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        titre.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _champ({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime dt,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
        subtitle: Text(
          Helpers.formatDateHeure(dt),
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
        trailing: const Icon(Icons.edit_calendar_outlined,
            color: AppColors.textLight),
        onTap: onTap,
      ),
    );
  }
}
