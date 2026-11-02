import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_status.dart';
import '../providers/game_list_provider.dart';
import '../providers/game_sort_order.dart';
import '../widgets/game_card.dart';
import 'game_form_screen.dart';
import 'game_detail_screen.dart';
import '../../../custom_lists/presentation/screens/custom_list_form_screen.dart';
import '../../../custom_lists/presentation/screens/custom_lists_view.dart';
import '../../../backup/presentation/widgets/backup_section.dart';
import '../../../stats/presentation/screens/stats_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Posição da aba Ajustes & Sync na barra (destino do atalho de backup da AppBar)
  static const int _settingsTabIndex = 3;

  int _currentIndex = 0; // Controla a aba ativa na BottomNavigationBar
  String? _selectedStatusFilter; // Status selecionado nos chips

  // Lista de status para os chips de filtro
  final List<Map<String, String>> _statusFilters = [
    {'id': '', 'label': 'Todos'},
    for (final status in GameStatus.values)
      {'id': status.id, 'label': status.label},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreador de Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Backup',
            onPressed: () {
              // Leva à aba Configurações, onde fica o backup local
              setState(() => _currentIndex = _settingsTabIndex);
            },
          ),
        ],
      ),

      // Exibe a aba baseada no índice atual
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLibraryTab(), // Aba 1: Biblioteca Geral
          _buildCustomListsTab(), // Aba 2: Minhas Listas Personalizadas
          const StatsView(), // Aba 3: Estatísticas da biblioteca
          _buildSettingsTab(), // Aba 4: Configurações & Backup local
        ],
      ),

      // Botão Flutuante (varia conforme a aba ativa)
      floatingActionButton: _buildFloatingActionButton(),

      // Navegação Inferior (4 Abas)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Minhas Listas',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Estatísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes & Sync',
          ),
        ],
      ),
    );
  }

  /// Retorna o FAB da aba ativa: "Novo Jogo" na Biblioteca e "Nova Lista" em Minhas Listas
  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const GameFormScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Novo Jogo'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CustomListFormScreen(),
              ),
            );
          },
          icon: const Icon(Icons.playlist_add),
          label: const Text('Nova Lista'),
        );
      default:
        return null;
    }
  }

  /// Menu "Ordenar" da Biblioteca, com a ordem atual marcada
  Widget _buildSortMenu() {
    final notifier = ref.read(gameListProvider.notifier);

    return PopupMenuButton<GameSortOrder>(
      icon: const Icon(Icons.sort),
      tooltip: 'Ordenar',
      onSelected: notifier.sortBy,
      itemBuilder: (context) => [
        for (final order in GameSortOrder.values)
          CheckedPopupMenuItem(
            value: order,
            checked: notifier.sortOrder == order,
            child: Text(order.label),
          ),
      ],
    );
  }

  // ==========================================
  // ABA 1: BIBLIOTECA GERAL DE JOGOS
  // ==========================================
  Widget _buildLibraryTab() {
    // Escuta o estado do gameListProvider
    final gamesState = ref.watch(gameListProvider);

    return Column(
      children: [
        // 1. Barra de Busca Rápida + menu de ordenação
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    ref.read(gameListProvider.notifier).search(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar jogo por nome...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _buildSortMenu(),
            ],
          ),
        ),

        // 2. Chips de Filtro Horizontal por Status
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusFilters.length,
            itemBuilder: (context, index) {
              final filter = _statusFilters[index];
              final isSelected = (_selectedStatusFilter ?? '') == filter['id'];

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newFilter = filter['id']!.isEmpty
                        ? null
                        : filter['id'];
                    setState(() {
                      _selectedStatusFilter = newFilter;
                    });
                    ref
                        .read(gameListProvider.notifier)
                        .filterByStatus(newFilter);
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 3. Grid de Jogos (Consumindo o Riverpod)
        Expanded(
          child: gamesState.when(
            data: (games) {
              if (games.isEmpty) {
                // Adicionado 'const' na raiz do widget do Center
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videogame_asset_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum jogo encontrado.',
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
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ABA 2: LISTAS PERSONALIZADAS
  // ==========================================
  Widget _buildCustomListsTab() {
    return const CustomListsView();
  }

  // ==========================================
  // ABA 3: CONFIGURAÇÕES E SYNC GOOGLE DRIVE
  // ==========================================
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [BackupSection()],
    );
  }
}
