import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_list.dart';
import '../../../games/data/models/game_status.dart';
import '../providers/custom_list_provider.dart';

class CustomListCard extends ConsumerWidget {
  final CustomList customList;
  final VoidCallback onTap;

  const CustomListCard({
    super.key,
    required this.customList,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta os jogos da lista para exibir a contagem atualizada
    final gamesState = ref.watch(customListGamesProvider(customList.id));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NOME DA LISTA E QUANTIDADE DE JOGOS
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customList.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gamesState.when(
                      data: (games) => _formatCount(games.length),
                      loading: () => '...',
                      error: (err, stack) => '-',
                    ),
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. CHIPS COM OS FILTROS ATIVOS
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _activeFilters()
                    .map(
                      (filter) => Chip(
                        avatar: Icon(filter.icon, size: 16),
                        label: Text(filter.label),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Monta a lista de filtros preenchidos com ícone e rótulo
  List<({IconData icon, String label})> _activeFilters() {
    final status = customList.filterStatus;

    return [
      if (customList.filterDeveloper != null)
        (icon: Icons.business, label: customList.filterDeveloper!),
      if (customList.filterPlatform != null)
        (icon: Icons.devices, label: customList.filterPlatform!),
      if (customList.filterGenre != null)
        (icon: Icons.category, label: customList.filterGenre!),
      if (status != null) (icon: Icons.flag, label: GameStatus.labelOf(status)),
    ];
  }

  /// Formata a contagem respeitando singular e plural
  String _formatCount(int count) => count == 1 ? '1 jogo' : '$count jogos';
}
