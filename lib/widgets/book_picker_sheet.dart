import 'package:flutter/material.dart';
import '../models/book.dart';

/// Bottom sheet para escolher qual livro está sendo registrado.
/// O livro passado em [preselected] (o "atual") vem destacado e
/// selecionado por padrão, sempre em primeiro na lista.
class BookPickerSheet extends StatefulWidget {
  final List<Book> books;
  final Book? preselected;

  const BookPickerSheet({
    super.key,
    required this.books,
    this.preselected,
  });

  @override
  State<BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends State<BookPickerSheet> {
  late Book? _selected;
  late List<Book> _orderedBooks;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected ?? (widget.books.isNotEmpty ? widget.books.first : null);

    _orderedBooks = [...widget.books];
    if (widget.preselected != null) {
      _orderedBooks.removeWhere((b) => b.id == widget.preselected!.id);
      _orderedBooks.insert(0, widget.preselected!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Qual livro você está lendo?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _orderedBooks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final book = _orderedBooks[index];
                  final isSelected = _selected?.id == book.id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selected = book),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${book.currentPage}/${book.totalPages} páginas',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
