import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/custom_list_provider.dart';
import '../widgets/custom_list_card.dart';
import 'custom_list_detail_screen.dart';

/// Conteúdo da aba "Minhas Listas" exibida na HomeScreen
class CustomListsView extends ConsumerWidget {
  const CustomListsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta as listas salvas (já ordenadas por nome pelo repositório)
    final listsState = ref.watch(customListProvider);

    return listsState.when(
      data: (customLists) {
        if (customLists.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma lista criada ainda.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          // Espaço inferior extra para o FAB não cobrir o último card
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: customLists.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final customList = customLists[index];
            return CustomListCard(
              customList: customList,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CustomListDetailScreen(listId: customList.id),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Erro ao carregar listas: $err')),
    );
  }
}
