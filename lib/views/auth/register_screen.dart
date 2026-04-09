import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_appbar.dart';

/// Écran d'inscription
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _accepteCGU = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepteCGU) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez accepter les conditions d\'utilisation'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.inscrire(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      nom: _nomCtrl.text,
      telephone: _telCtrl.text.isEmpty ? null : _telCtrl.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé ! En attente de validation par un administrateur.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Erreur lors de l\'inscription'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titre: 'Créer un compte'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Rejoignez notre bibliothèque',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Votre compte sera activé après validation.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Nom
              TextFormField(
                controller: _nomCtrl,
                textCapitalization: TextCapitalization.words,
                validator: Validators.nom,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'Adresse email *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Téléphone (optionnel)
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                validator: Validators.telephone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                validator: Validators.password,
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  helperText: 'Minimum 6 caractères',
                ),
              ),
              const SizedBox(height: 16),

              // Confirmation mot de passe
              TextFormField(
                controller: _passConfirmCtrl,
                obscureText: _obscureConfirm,
                validator: Validators.confirmPassword(_passCtrl.text),
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CGU
              Row(
                children: [
                  Checkbox(
                    value: _accepteCGU,
                    onChanged: (v) => setState(() => _accepteCGU = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _accepteCGU = !_accepteCGU),
                      child: const Text(
                        'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Bouton inscription
              Consumer<AuthController>(
                builder: (_, auth, __) => SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _inscrire,
                    child: auth.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text("S'inscrire",
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ? ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
