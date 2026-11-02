import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/games/data/models/game.dart';
import '../../data/models/game_status.dart';
import '../providers/game_repository_provider.dart';
import '../providers/game_list_provider.dart';
import 'game_form_screen.dart';

class GameDetailScreen extends ConsumerStatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  late Game _currentGame;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
  }

  /// Busca os dados mais recentes do jogo no Isar e atualiza a UI
  Future<void> _refreshGame() async {
    final repository = ref.read(gameRepositoryProvider);
    final updatedGame = await repository.getGameById(_currentGame.id);

    if (updatedGame != null && mounted) {
      setState(() {
        _currentGame = updatedGame;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentGame.title),
        actions: [
          // Botão Editar
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Jogo',
            onPressed: () async {
              // 1. Aguarda o usuário terminar de editar e fechar a GameFormScreen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GameFormScreen(gameToEdit: _currentGame),
                ),
              );

              // 2. Assim que retorna para esta tela, busca os dados atualizados no Isar
              await _refreshGame();
            },
          ),
          // Botão Excluir
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: 'Excluir Jogo',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentGame.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentGame.developer != null &&
                      _currentGame.developer!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Desenvolvido por: ${_currentGame.developer}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.sports_esports, size: 18),
                        label: Text(_currentGame.platform ?? 'Não informada'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                      Chip(
                        avatar: const Icon(Icons.flag, size: 18),
                        label: Text(GameStatus.labelOf(_currentGame.status)),
                        backgroundColor: _getStatusColor(
                          _currentGame.status,
                        ).withValues(alpha: 0.2),
                      ),
                      if (_currentGame.genre != null &&
                          _currentGame.genre!.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.category, size: 18),
                          label: Text(_currentGame.genre!),
                        ),
                      if (_currentGame.releaseYear != null)
                        Chip(
                          avatar: const Icon(Icons.calendar_today, size: 18),
                          label: Text('${_currentGame.releaseYear}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Sua Avaliação',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RatingBarIndicator(
                    rating: _currentGame.rating,
                    itemBuilder: (context, index) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 28.0,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(height: 24),
                  if (_currentGame.startDate != null ||
                      _currentGame.endDate != null) ...[
                    Text(
                      'Histórico de Jogatina',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            if (_currentGame.startDate != null)
                              _buildDateRow(
                                icon: Icons.play_arrow,
                                label: 'Iniciado em:',
                                date: _currentGame.startDate!,
                              ),
                            if (_currentGame.startDate != null &&
                                _currentGame.endDate != null)
                              const Divider(height: 12),
                            if (_currentGame.endDate != null)
                              _buildDateRow(
                                icon: Icons.check_circle,
                                label: 'Concluído em:',
                                date: _currentGame.endDate!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    if (_currentGame.coverUrl == null || _currentGame.coverUrl!.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey[800],
        child: const Icon(
          Icons.videogame_asset,
          size: 80,
          color: Colors.white54,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: _currentGame.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required String label,
    required DateTime date,
  }) {
    final formattedDate =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(formattedDate, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (GameStatus.fromId(status)) {
      case GameStatus.paraJogar:
        return Colors.blue;
      case GameStatus.jogando:
        return Colors.orange;
      case GameStatus.jogado:
        return Colors.purple;
      case GameStatus.finalizado:
        return Colors.green;
      case GameStatus.completo:
        return Colors.amber;
      case null:
        return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Jogo'),
        content: Text(
          'Tem certeza que deseja excluir "${_currentGame.title}" da sua biblioteca?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(gameListProvider.notifier)
                    .deleteGame(_currentGame.id);
              } catch (_) {
                // Falha na exclusão: avisa o usuário e mantém o detalhe aberto
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Não foi possível excluir o jogo. Tente novamente.',
                      ),
                    ),
                  );
                }
                return;
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_currentGame.title} foi removido.'),
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
