import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_lookup_result.dart';
import '../providers/game_lookup_provider.dart';

/// Abre a folha de busca de dados do jogo já pesquisando [initialQuery].
///
/// Devolve o jogo escolhido (com a capa resolvida), ou `null` se a folha for fechada sem escolha.
Future<GameLookupResult?> showGameLookupSheet(
  BuildContext context, {
  required String initialQuery,
}) {
  return showModalBottomSheet<GameLookupResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => GameLookupSheet(initialQuery: initialQuery),
  );
}

/// Folha com campo de busca e lista de jogos encontrados no Wikidata
class GameLookupSheet extends ConsumerStatefulWidget {
  const GameLookupSheet({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<GameLookupSheet> createState() => _GameLookupSheetState();
}

class _GameLookupSheetState extends ConsumerState<GameLookupSheet> {
  late final TextEditingController _queryController;

  List<GameLookupResult>? _results; // null = ainda não buscou
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery.trim());
    // A folha abre a partir do botão de busca: já pesquisa o título digitado
    if (_queryController.text.isNotEmpty) _search();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await ref.read(gameLookupServiceProvider).search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Resolve a capa do jogo escolhido e fecha a folha devolvendo o resultado
  Future<void> _select(GameLookupResult result) async {
    setState(() => _loading = true);
    final coverUrl = await ref
        .read(gameLookupServiceProvider)
        .findCoverUrl(result);
    if (!mounted) return;
    Navigator.of(context).pop(result.withCoverUrl(coverUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Mantém o campo visível acima do teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Nome do jogo',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.travel_explore),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Buscar',
                    onPressed: _loading ? null : _search,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Dados do Wikidata; capas da Steam quando disponíveis.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Não foi possível buscar agora. Verifique a conexão.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    final results = _results;
    if (results == null) return const SizedBox.shrink();
    if (results.isEmpty) {
      return const Center(child: Text('Nenhum jogo encontrado.'));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        final details = [
          if (result.description != null) result.description!,
          if (result.developer != null) result.developer!,
        ].join(' · ');

        return ListTile(
          leading: const Icon(Icons.sports_esports),
          title: Text(result.title),
          subtitle: details.isEmpty ? null : Text(details),
          trailing: result.releaseYear == null
              ? null
              : Text(result.releaseYear.toString()),
          onTap: () => _select(result),
        );
      },
    );
  }
}
