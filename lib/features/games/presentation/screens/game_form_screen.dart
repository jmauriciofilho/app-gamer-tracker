import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../data/models/game.dart';
import '../../data/models/game_status.dart';
import '../providers/game_list_provider.dart';
import '../../../game_lookup/data/models/game_lookup_result.dart';
import '../../../game_lookup/presentation/widgets/game_lookup_sheet.dart';

class GameFormScreen extends ConsumerStatefulWidget {
  final Game? gameToEdit; // Se for nulo, é criação. Se informado, é edição!

  const GameFormScreen({super.key, this.gameToEdit});

  @override
  ConsumerState<GameFormScreen> createState() => _GameFormScreenState();
}

class _GameFormScreenState extends ConsumerState<GameFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  late TextEditingController _titleController;
  late TextEditingController _developerController;
  late TextEditingController _genreController;
  late TextEditingController _platformController;
  late TextEditingController _releaseYearController;
  late TextEditingController _coverUrlController;

  // Campos de Seleção
  String _selectedStatus = GameStatus.paraJogar.id;
  double _rating = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;

  // Plataformas do jogo escolhido na busca, oferecidas como chips (vazio = sem chips)
  List<String> _platformOptions = [];

  @override
  void initState() {
    super.initState();
    final game = widget.gameToEdit;

    // Se estivermos editando, preenchemos os campos com os dados existentes
    _titleController = TextEditingController(text: game?.title ?? '');
    _developerController = TextEditingController(text: game?.developer ?? '');
    _genreController = TextEditingController(text: game?.genre ?? '');
    _platformController = TextEditingController(text: game?.platform ?? '');
    _releaseYearController = TextEditingController(
      text: game?.releaseYear != null ? game!.releaseYear.toString() : '',
    );
    _coverUrlController = TextEditingController(text: game?.coverUrl ?? '');

    if (game != null) {
      _selectedStatus = game.status;
      _rating = game.rating;
      _startDate = game.startDate;
      _endDate = game.endDate;
    }
  }

  @override
  void dispose() {
    // É boa prática dar dispose nos controllers para liberar memória
    _titleController.dispose();
    _developerController.dispose();
    _genreController.dispose();
    _platformController.dispose();
    _releaseYearController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  /// Exibe o seletor de data nativo do sistema
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Abre a busca de dados do jogo com o título digitado e aplica o resultado escolhido
  Future<void> _openLookup() async {
    final result = await showGameLookupSheet(
      context,
      initialQuery: _titleController.text,
    );
    if (result == null || !mounted) return;
    _applyLookup(result);
  }

  /// Preenche o formulário com o jogo escolhido.
  /// O título é sempre trocado (era o termo da busca); os demais campos só se estiverem vazios.
  /// Status, nota e datas nunca mudam.
  void _applyLookup(GameLookupResult result) {
    void fillIfEmpty(TextEditingController controller, String? value) {
      if (value != null && controller.text.trim().isEmpty) {
        controller.text = value;
      }
    }

    setState(() {
      _titleController.text = result.title;
      fillIfEmpty(_developerController, result.developer);
      fillIfEmpty(_genreController, result.genre);
      fillIfEmpty(_releaseYearController, result.releaseYear?.toString());
      fillIfEmpty(_coverUrlController, result.coverUrl);

      // Uma plataforma: preenche direto; várias: o usuário escolhe nos chips
      if (result.platforms.length == 1) {
        fillIfEmpty(_platformController, result.platforms.first);
        _platformOptions = [];
      } else {
        _platformOptions = result.platforms;
      }
    });
  }

  /// Valida e salva o jogo no banco local Isar
  Future<void> _submitForm() async {
    // 1. Adicionado 'async'
    if (_formKey.currentState!.validate()) {
      // Cria ou reutiliza a instância do jogo
      final game = widget.gameToEdit ?? Game();

      game.title = _titleController.text.trim();
      game.developer = _developerController.text.trim().isEmpty
          ? null
          : _developerController.text.trim();
      game.genre = _genreController.text.trim().isEmpty
          ? null
          : _genreController.text.trim();
      game.platform = _platformController.text.trim().isEmpty
          ? null
          : _platformController.text.trim();
      game.releaseYear = int.tryParse(_releaseYearController.text.trim());
      game.coverUrl = _coverUrlController.text.trim().isEmpty
          ? null
          : _coverUrlController.text.trim();
      game.status = _selectedStatus;
      game.rating = _rating;
      game.startDate = _startDate;
      game.endDate = _endDate;

      // 2. AGUARDA a gravação no Isar ser concluída antes de prosseguir
      try {
        await ref.read(gameListProvider.notifier).saveGame(game);
      } catch (_) {
        // Falha na gravação: avisa o usuário e mantém o formulário aberto
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o jogo. Tente novamente.'),
          ),
        );
        return;
      }

      // 3. Verifica se o widget continua montado após a operação assíncrona
      if (!mounted) return;

      // Exibe mensagem de confirmação e fecha a tela
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.gameToEdit == null
                ? 'Jogo cadastrado com sucesso!'
                : 'Jogo atualizado com sucesso!',
          ),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.gameToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Jogo' : 'Novo Jogo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TÍTULO DO JOGO (Obrigatório)
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título do Jogo *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.videogame_asset),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.travel_explore),
                    tooltip: 'Buscar dados do jogo',
                    onPressed: _openLookup,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o título do jogo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. URL DA CAPA
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL da Imagem da Capa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://exemplo.com/capa.jpg',
                ),
                onChanged: (_) =>
                    setState(() {}), // Atualiza pré-visualização em tempo real
              ),
              const SizedBox(height: 16),

              // 3. STATUS DO JOGO (Dropdown)
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status do Jogo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: GameStatus.values.map((status) {
                  return DropdownMenuItem<String>(
                    value: status.id,
                    child: Text(status.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 4. PLATAFORMA & DESENVOLVEDORA (2 Colunas)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _platformController,
                      decoration: const InputDecoration(
                        labelText: 'Plataforma',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: PS1, PS5, PC',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _developerController,
                      decoration: const InputDecoration(
                        labelText: 'Desenvolvedora',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Capcom',
                      ),
                    ),
                  ),
                ],
              ),

              // Plataformas do jogo escolhido na busca (um toque preenche o campo)
              if (_platformOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Plataformas deste jogo:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final platform in _platformOptions)
                      ActionChip(
                        label: Text(platform),
                        onPressed: () => setState(() {
                          _platformController.text = platform;
                          _platformOptions = [];
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // 5. GÊNERO & ANO DE LANÇAMENTO (2 Colunas)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _genreController,
                      decoration: const InputDecoration(
                        labelText: 'Gênero',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: RPG, Ação',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _releaseYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 1998',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. AVALIAÇÃO EM ESTRELAS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sua Nota:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7. SELEÇÃO DE DATAS (Início e Término)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _startDate == null
                            ? 'Data de Início'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.event_available, size: 18),
                      label: Text(
                        _endDate == null
                            ? 'Data de Término'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 8. BOTÃO DE SALVAR
              ElevatedButton.icon(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  isEditing ? 'Atualizar Jogo' : 'Salvar Jogo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
