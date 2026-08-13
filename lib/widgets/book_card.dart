import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book.dart';

/// Card de livro em formato de grade — usado nos layouts padrão e infantil.
class BookGridCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final bool large;

  const BookGridCard({
    super.key,
    required this.book,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(large ? 14 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: book.coverPath != null
                    ? Image.file(
                        File(book.coverPath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        color: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: large ? 40 : 32,
                        ),
                      ),
              ),
            ),
            SizedBox(height: large ? 10 : 6),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (large
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleSmall)
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (book.author != null)
              Text(
                book.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: book.progress,
                minHeight: large ? 8 : 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de livro em formato de lista — usado no layout padrão e no
/// layout para idosos (com textos e alvos de toque maiores).
class BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final bool large;

  const BookListTile({
    super.key,
    required this.book,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverSize = large ? 64.0 : 48.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(large ? 16 : 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverPath != null
                  ? Image.file(
                      File(book.coverPath!),
                      width: coverSize,
                      height: coverSize * 1.35,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: coverSize,
                      height: coverSize * 1.35,
                      color: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: large ? 30 : 22,
                      ),
                    ),
            ),
            SizedBox(width: large ? 18 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (large
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.titleSmall)
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (book.author != null)
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: book.progress,
                      minHeight: large ? 8 : 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${book.currentPage}/${book.totalPages} páginas · ${book.status.label}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: large ? 28 : 22),
          ],
        ),
      ),
    );
  }
}
