import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book.dart';
import '../services/book_repository.dart';

/// Tela de edição de um livro existente. Permite editar todos os campos
/// e deletar o livro da biblioteca.
class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookRepository = BookRepository.instance;

  late TextEditingController _titleController;
  late TextEditingController _pagesController;
  late TextEditingController _authorController;
  late TextEditingController _genreController;
  late TextEditingController _seriesController;
  late TextEditingController _publisherController;
  late TextEditingController _isbnController;
  late TextEditingController _currentPageController;

  List<String> _authorSuggestions = [];
  List<String> _genreSuggestions = [];
  List<String> _seriesSuggestions = [];
  List<String> _publisherSuggestions = [];

  String? _coverPath;
  late BookStatus _selectedStatus;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _pagesController = TextEditingController(text: widget.book.totalPages.toString());
    _authorController = TextEditingController(text: widget.book.author ?? '');
    _genreController = TextEditingController(text: widget.book.genre ?? '');
    _seriesController = TextEditingController(text: widget.book.series ?? '');
    _publisherController = TextEditingController(text: widget.book.publisher ?? '');
    _isbnController = TextEditingController(text: widget.book.isbn ?? '');
    _currentPageController = TextEditingController(text: widget.book.currentPage.toString());
    
    _coverPath = widget.book.coverPath;
    _selectedStatus = widget.book.status;
    
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final authors = await _bookRepository.getDistinctAuthors();
    final genres = await _bookRepository.getDistinctGenres();
    final series = await _bookRepository.getDistinctSeries();
    final publishers = await _bookRepository.getDistinctPublishers();

    if (!mounted) return;
    setState(() {
      _authorSuggestions = authors;
      _genreSuggestions = genres;
      _seriesSuggestions = series;
      _publisherSuggestions = publishers;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pagesController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _seriesController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    _currentPageController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _coverPath = picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível acessar a galeria.')),
      );
    }
  }

  String? _requireField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $label';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedBook = Book(
      id: widget.book.id,
      title: _titleController.text.trim(),
      totalPages: int.parse(_pagesController.text.trim()),
      currentPage: int.parse(_currentPageController.text.trim()),
      author: _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
      genre: _genreController.text.trim().isEmpty
          ? null
          : _genreController.text.trim(),
      series: _seriesController.text.trim().isEmpty
          ? null
          : _seriesController.text.trim(),
      publisher: _publisherController.text.trim().isEmpty
          ? null
          : _publisherController.text.trim(),
      isbn: _isbnController.text.trim().isEmpty
          ? null
          : _isbnController.text.trim(),
      coverPath: _coverPath,
      status: _selectedStatus,
      updatedAt: DateTime.now(),
    );

    await _bookRepository.updateBook(updatedBook);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deletar livro?'),
          content: Text(
            'Tem certeza que deseja deletar "${widget.book.title}"? Todos os registros de leitura também serão removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Deletar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    await _bookRepository.deleteBook(widget.book.id!);

    if (!mounted) return;
    setState(() => _isDeleting = false);
    Navigator.of(context).pop(true);
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required List<String> suggestions,
    required String label,
    required IconData icon,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return suggestions.where(
          (s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        fieldController.text = controller.text;
        fieldController.addListener(() {
          controller.text = fieldController.text;
        });
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar livro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _handleDelete,
            tooltip: 'Deletar livro',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickCover,
                  child: Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      image: _coverPath != null
                          ? DecorationImage(
                              image: FileImage(File(_coverPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverPath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Alterar capa',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _requireField(v, 'o nome do livro'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pagesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de páginas *',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final err = _requireField(v, 'o número de páginas');
                  if (err != null) return err;
                  final parsed = int.tryParse(v!.trim());
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Página atual *',
                  prefixIcon: Icon(Icons.bookmark_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final err = _requireField(v, 'a página atual');
                  if (err != null) return err;
                  final parsed = int.tryParse(v!.trim());
                  if (parsed == null || parsed < 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BookStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                items: BookStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildAutocompleteField(
                controller: _authorController,
                suggestions: _authorSuggestions,
                label: 'Autor',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildAutocompleteField(
                controller: _genreController,
                suggestions: _genreSuggestions,
                label: 'Gênero',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              _buildAutocompleteField(
                controller: _seriesController,
                suggestions: _seriesSuggestions,
                label: 'Saga',
                icon: Icons.collections_outlined,
              ),
              const SizedBox(height: 16),
              _buildAutocompleteField(
                controller: _publisherController,
                suggestions: _publisherSuggestions,
                label: 'Editora',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isbnController,
                decoration: const InputDecoration(
                  labelText: 'ISBN',
                  prefixIcon: Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _isSaving || _isDeleting ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar alterações'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
