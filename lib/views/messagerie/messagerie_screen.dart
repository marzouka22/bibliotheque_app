import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/message_controller.dart';
import '../../models/message.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_appbar.dart';

/// Écran de messagerie interne
class MessagerieScreen extends StatefulWidget {
  const MessagerieScreen({super.key});

  @override
  State<MessagerieScreen> createState() => _MessagerieScreenState();
}

class _MessagerieScreenState extends State<MessagerieScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().uid;
      if (uid != null) {
        context.read<MessageController>().ecouterConversations(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.estConnecte) {
      return Scaffold(
        appBar: const CustomAppBar(titre: 'Messages', showBack: false),
        body: EmptyStateWidget(
          icon: Icons.chat_bubble_outline,
          titre: 'Connexion requise',
          sousTitre: 'Connectez-vous pour accéder à la messagerie',
          action: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Se connecter'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(titre: 'Messages', showBack: false),
      body: Consumer<MessageController>(
        builder: (_, msgCtrl, __) {
          final convs = msgCtrl.conversations;
          if (convs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              titre: 'Aucune conversation',
              sousTitre: 'Commencez une discussion avec un membre ou un bibliothécaire',
            );
          }

          return ListView.separated(
            itemCount: convs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final conv = convs[i];
              final nbNonLus = conv.nbNonLusPour(auth.uid!);
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    Helpers.initiales(
                        conv.nomAutreParticipant(auth.uid!)),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                title: Text(
                  conv.nomAutreParticipant(auth.uid!),
                  style: TextStyle(
                    fontWeight:
                        nbNonLus > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  conv.dernierMessage ?? 'Démarrer la conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: nbNonLus > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                    color: nbNonLus > 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conv.dateDernierMessage != null)
                      Text(
                        Helpers.dateRelative(conv.dateDernierMessage!),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight),
                      ),
                    if (nbNonLus > 0) ...[
                      const SizedBox(height: 4),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '$nbNonLus',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      conversationId: conv.id,
                      titreConv: conv.nomAutreParticipant(auth.uid!),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Écran d'une conversation
class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String titreConv;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.titreConv,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<MessageController>().ecouterMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty) return;
    final auth = context.read<AuthController>();
    final ctrl = context.read<MessageController>();

    _msgCtrl.clear();
    await ctrl.envoyerMessage(
      conversationId: widget.conversationId,
      expediteurId: auth.uid!,
      expediteurNom: auth.membre?.nom ?? '',
      contenu: texte,
      expediteurAvatar: auth.membre?.avatarUrl,
    );

    // Scroll vers le bas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: CustomAppBar(
        titre: widget.titreConv,
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline), onPressed: () {})
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageController>(
              builder: (_, ctrl, __) {
                final messages = ctrl.messagesActuels;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Commencez la conversation !',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    message: messages[i],
                    isMine: messages[i].expediteurId == auth.uid,
                  ),
                );
              },
            ),
          ),
          // Zone de saisie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Écrivez un message...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _envoyer(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _envoyer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulle de message
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                message.expediteurNom,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.primary),
              ),
            Text(
              message.contenu,
              style: TextStyle(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4),
            ),
            const SizedBox(height: 2),
            Text(
              Helpers.formatHeure(message.dateEnvoi),
              style: TextStyle(
                  fontSize: 10,
                  color: isMine
                      ? Colors.white70
                      : AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
