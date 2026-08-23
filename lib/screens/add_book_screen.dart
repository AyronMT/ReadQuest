import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book.dart';
import '../services/book_repository.dart';

/// Tela de cadastro (ou edição, se [editingBook] for informado) de um
/// livro. Apenas título e total de páginas são obrigatórios. Autor,
/// gênero, saga e editora sugerem autopreenchimento com base em
/// livros já cadastrados anteriormente.
class AddBookScreen extends StatefulWidget {
  final Book? editingBook;

  const AddBookScreen({super.key, this.editingBook});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookRepository = BookRepository.instance;

  final _titleController = TextEditingController();
  final _pagesController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _seriesController = TextEditingController();
  final _publisherController = TextEditingController();
  final _isbnController = TextEditingController();

  List<String> _authorSuggestions = [];
  List<String> _genreSuggestions = [];
  List<String> _seriesSuggestions = [];
  List<String> _publisherSuggestions = [];

  String? _coverPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();

    final book = widget.editingBook;
    if (book != null) {
      _titleController.text = book.title;
      _pagesController.text = book.totalPages.toString();
      _authorController.text = book.author ?? '';
      _genreController.text = book.genre ?? '';
      _seriesController.text = book.series ?? '';
      _publisherController.text = book.publisher ?? '';
      _isbnController.text = book.isbn ?? '';
      _coverPath = book.coverPath;
    }
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

    final isEditing = widget.editingBook != null;

    final book = Book(
      id: widget.editingBook?.id,
      title: _titleController.text.trim(),
      totalPages: int.parse(_pagesController.text.trim()),
      currentPage: widget.editingBook?.currentPage ?? 0,
      status: widget.editingBook?.status ?? BookStatus.reading,
      isActive: widget.editingBook?.isActive ?? false,
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
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      await _bookRepository.updateBook(book);
    } else {
      await _bookRepository.addBook(book);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
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
        // Mantém os dois controllers sincronizados.
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
      appBar: AppBar(title: Text(widget.editingBook != null ? 'Editar livro' : 'Novo livro')),
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
                                'Capa\n(opcional)',
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
                icon: Icons.collections_bookmark_outlined,
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
                  prefixIcon: Icon(Icons.qr_code_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.editingBook != null ? 'Salvar alterações' : 'Adicionar à biblioteca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
