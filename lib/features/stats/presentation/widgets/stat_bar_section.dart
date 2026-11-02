import 'package:flutter/material.dart';
import '../../data/models/game_stats.dart';

/// Bloco da aba Estatísticas: título e uma barra horizontal por item,
/// proporcional ao maior valor do bloco
class StatBarSection extends StatelessWidget {
  const StatBarSection({super.key, required this.title, required this.entries});

  final String title;
  final List<StatEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = entries.fold<int>(
      0,
      (max, entry) => entry.count > max ? entry.count : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text(
                'Sem dados ainda.',
                style: TextStyle(color: Colors.grey),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            // Bloco só com zeros (ex.: status sem jogos) fica com barras vazias
                            value: maxCount == 0 ? 0 : entry.count / maxCount,
                            minHeight: 10,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          entry.count.toString(),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
