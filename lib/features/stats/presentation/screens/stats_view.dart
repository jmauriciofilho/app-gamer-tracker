import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_stats.dart';
import '../providers/game_stats_provider.dart';
import '../widgets/stat_bar_section.dart';

/// Conteúdo da aba "Estatísticas" exibida na HomeScreen
class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  /// Nota com 1 casa decimal e vírgula (ex.: 4,3); "—" quando não há nota
  static String formatRating(double? rating) =>
      rating == null ? '—' : rating.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(gameStatsProvider);

    return statsState.when(
      data: (stats) {
        if (stats.total == 0) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insights, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Cadastre jogos para ver estatísticas.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(stats: stats),
            const SizedBox(height: 12),
            StatBarSection(title: 'Por status', entries: stats.byStatus),
            const SizedBox(height: 12),
            StatBarSection(
              title: 'Terminados por ano',
              entries: stats.finishedByYear,
            ),
            const SizedBox(height: 12),
            StatBarSection(
              title: 'Top plataformas',
              entries: stats.topPlatforms,
            ),
            const SizedBox(height: 12),
            StatBarSection(title: 'Top gêneros', entries: stats.topGenres),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(
        child: Text('Não foi possível carregar as estatísticas.'),
      ),
    );
  }
}

/// Cartão com os totais: jogos, terminados e nota média
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final GameStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            _SummaryValue(label: 'Jogos', value: stats.total.toString()),
            _SummaryValue(
              label: 'Terminados',
              value: stats.finished.toString(),
            ),
            _SummaryValue(
              label: 'Nota média',
              value: StatsView.formatRating(stats.averageRating),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
