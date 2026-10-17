import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_list.dart';
import '../providers/custom_list_provider.dart';
import '../widgets/custom_list_card.dart';

class CustomListFormScreen extends ConsumerStatefulWidget {
  final CustomList?
  listToEdit; // Se for nulo, é criação. Se informado, é edição!

  const CustomListFormScreen({super.key, this.listToEdit});

  @override
  ConsumerState<CustomListFormScreen> createState() =>
      _CustomListFormScreenState();
}

class _CustomListFormScreenState extends ConsumerState<CustomListFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  late TextEditingController _nameController;
  late TextEditingController _developerController;
  late TextEditingController _platformController;
  late TextEditingController _genreController;

  // Status selecionado (nulo = "Qualquer")
  String? _selectedStatus;

  // Mensagem exibida quando nenhum filtro foi preenchido
  String? _filterError;

  @override
  void initState() {
    super.initState();
    final customList = widget.listToEdit;

    // Se estivermos editando, preenchemos os campos com os dados existentes
    _nameController = TextEditingController(text: customList?.name ?? '');
    _developerController = TextEditingController(
      text: customList?.filterDeveloper ?? '',
    );
    _platformController = TextEditingController(
      text: customList?.filterPlatform ?? '',
    );
    _genreController = TextEditingController(
      text: customList?.filterGenre ?? '',
    );
    _selectedStatus = customList?.filterStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _developerController.dispose();
    _platformController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  /// Converte o texto do campo em valor do filtro (vazio vira nulo)
  String? _filterValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  /// Valida e salva a lista no banco local Isar
  Future<void> _submitForm() async {
    final isNameValid = _formKey.currentState!.validate();

    final developer = _filterValue(_developerController);
    final platform = _filterValue(_platformController);
    final genre = _filterValue(_genreController);

    // Exige pelo menos um filtro preenchido
    final hasFilter =
        developer != null ||
        platform != null ||
        genre != null ||
        _selectedStatus != null;

    setState(() {
      _filterError = hasFilter ? null : 'Preencha pelo menos um filtro';
    });

    if (!isNameValid || !hasFilter) return;

    // Cria ou reutiliza a instância da lista (mantém o id na edição)
    final customList = widget.listToEdit ?? CustomList();

    customList.name = _nameController.text.trim();
    customList.filterDeveloper = developer;
    customList.filterPlatform = platform;
    customList.filterGenre = genre;
    customList.filterStatus = _selectedStatus;

    // Aguarda a gravação no Isar antes de fechar a tela
    try {
      await ref.read(customListProvider.notifier).saveCustomList(customList);
    } catch (_) {
      // Falha na gravação: avisa o usuário e mantém o formulário aberto
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a lista. Tente novamente.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.listToEdit == null
              ? 'Lista criada com sucesso!'
              : 'Lista atualizada com sucesso!',
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.listToEdit != null;

    // Sugestões de autocompletar vindas dos jogos já cadastrados
    final options =
        ref.watch(gameFilterOptionsProvider).value ??
        const GameFilterOptions(developers: [], platforms: [], genres: []);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Lista' : 'Nova Lista')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. NOME DA LISTA (Obrigatório)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Lista *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da lista';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Filtros (preencha pelo menos um)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 2. FILTROS DE TEXTO COM AUTOCOMPLETAR
              _AutocompleteField(
                key: const Key('filterDeveloperField'),
                controller: _developerController,
                options: options.developers,
                label: 'Desenvolvedora',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),
              _AutocompleteField(
                key: const Key('filterPlatformField'),
                controller: _platformController,
                options: options.platforms,
                label: 'Plataforma',
                icon: Icons.devices,
              ),
              const SizedBox(height: 16),
              _AutocompleteField(
                key: const Key('filterGenreField'),
                controller: _genreController,
                options: options.genres,
                label: 'Gênero',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),

              // 3. FILTRO DE STATUS (Dropdown)
              DropdownButtonFormField<String?>(
                key: const Key('filterStatusField'),
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Qualquer'),
                  ),
                  ...customListStatusLabels.entries.map(
                    (status) => DropdownMenuItem<String?>(
                      value: status.key,
                      child: Text(status.value),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),

              // Erro de validação dos filtros
              if (_filterError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _filterError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 32),

              // 4. BOTÃO SALVAR
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Salvar Alterações' : 'Criar Lista'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de texto com sugestões de autocompletar que também aceita valor livre
class _AutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> options;
  final String label;
  final IconData icon;

  const _AutocompleteField({
    super.key,
    required this.controller,
    required this.options,
    required this.label,
    required this.icon,
  });

  @override
  State<_AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<_AutocompleteField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Filtra as sugestões que contêm o texto digitado (sem diferenciar maiúsculas)
  Iterable<String> _buildOptions(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) return const Iterable<String>.empty();

    return widget.options.where(
      (option) =>
          option.toLowerCase().contains(query) && option.toLowerCase() != query,
    );
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder garante que a caixa de sugestões tenha a largura do campo
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: _buildOptions,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(widget.icon),
              ),
              onFieldSubmitted: (_) => onSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
