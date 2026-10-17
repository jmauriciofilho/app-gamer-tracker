import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_list.dart';
import '../providers/custom_list_provider.dart';
import '../../../games/presentation/screens/game_detail_screen.dart';
import '../../../games/presentation/widgets/game_card.dart';
import 'custom_list_form_screen.dart';

class CustomListDetailScreen extends ConsumerWidget {
  final int listId;

  const CustomListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Busca a lista atualizada no provider (reflete edições automaticamente)
    final listsState = ref.watch(customListProvider);

    return listsState.when(
      data: (customLists) {
        final customList = customLists
            .where((list) => list.id == listId)
            .firstOrNull;

        // Lista removida ou inexistente
        if (customList == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Lista não encontrada.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customList.name),
            actions: [
              // Botão Editar
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar Lista',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomListFormScreen(listToEdit: customList),
                    ),
                  );
                },
              ),
              // Botão Excluir
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: 'Excluir Lista',
                onPressed: () => _confirmDelete(context, ref, customList),
              ),
            ],
          ),
          body: _buildGamesGrid(ref),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro ao carregar lista: $err')),
      ),
    );
  }

  /// Grade com os jogos que atendem aos filtros da lista
  Widget _buildGamesGrid(WidgetRef ref) {
    final gamesState = ref.watch(customListGamesProvider(listId));

    return gamesState.when(
      data: (games) {
        if (games.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videogame_asset_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum jogo corresponde aos filtros desta lista.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 colunas
            childAspectRatio: 0.7, // Proporção do card da capa
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return GameCard(
              game: game,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameDetailScreen(game: game),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Erro ao carregar jogos: $err')),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomList customList,
  ) {
    // Guarda o nome antes da exclusão para usar na mensagem
    final listName = customList.name;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lista'),
        content: Text('Tem certeza que deseja excluir a lista "$listName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);

              // Captura o messenger e o navigator antes da operação assíncrona
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                await ref
                    .read(customListProvider.notifier)
                    .deleteCustomList(customList.id);
              } catch (_) {
                // Falha na exclusão: avisa o usuário e mantém o detalhe aberto
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Não foi possível excluir a lista. Tente novamente.',
                    ),
                  ),
                );
                return;
              }

              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('$listName foi removida.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
