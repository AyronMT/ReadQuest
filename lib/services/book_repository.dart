import '../models/book.dart';
import 'database_helper.dart';

/// Opções de ordenação para a listagem da biblioteca.
enum BookSortOption {
  recentlyUpdated,
  titleAsc,
  mostPages;

  String get label {
    switch (this) {
      case BookSortOption.recentlyUpdated:
        return 'Atualizados recentemente';
      case BookSortOption.titleAsc:
        return 'Título (A-Z)';
      case BookSortOption.mostPages:
        return 'Mais páginas';
    }
  }

  String get _orderByClause {
    switch (this) {
      case BookSortOption.recentlyUpdated:
        return 'updated_at DESC';
      case BookSortOption.titleAsc:
        return 'title COLLATE NOCASE ASC';
      case BookSortOption.mostPages:
        return 'total_pages DESC';
    }
  }
}

/// Resultado de uma tentativa de ativar um livro.
enum SetActiveResult { success, limitReached }

class BookRepository {
  BookRepository._internal();
  static final BookRepository instance = BookRepository._internal();

  static const int maxActiveBooks = 10;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Retorna os livros não encerrados (status 'reading'), do mais
  /// recentemente atualizado para o mais antigo. Usado no Dashboard
  /// (limitado a 3).
  Future<List<Book>> getUnfinishedBooks({int? limit}) async {
    final db = await _dbHelper.database;

    final rows = await db.query(
      'books',
      where: 'status = ?',
      whereArgs: [BookStatus.reading.name],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return rows.map(Book.fromMap).toList();
  }

  /// Livros elegíveis para registro de leitura: os que estão
  /// marcados como ativos + os últimos 3 livros efetivamente lidos
  /// (por sessão mais recente). Evita que o seletor fique poluído
  /// com toda a biblioteca conforme ela cresce.
  Future<List<Book>> getEligibleBooksForReading() async {
    final db = await _dbHelper.database;

    final activeRows = await db.query(
      'books',
      columns: ['id'],
      where: 'is_active = 1 AND status = ?',
      whereArgs: [BookStatus.reading.name],
    );
    final activeIds = activeRows.map((r) => r['id'] as int).toSet();

    final recentRows = await db.rawQuery('''
      SELECT book_id, MAX(created_at) as last_read
      FROM reading_sessions
      GROUP BY book_id
      ORDER BY last_read DESC
      LIMIT 3
    ''');
    final recentIds = recentRows.map((r) => r['book_id'] as int).toSet();

    final allIds = {...activeIds, ...recentIds};
    if (allIds.isEmpty) {
      // Nenhum livro ativo nem lido ainda: cai de volta para os
      // livros em andamento mais recentes, pra não travar o usuário.
      return getUnfinishedBooks(limit: 3);
    }

    final placeholders = List.filled(allIds.length, '?').join(',');
    final rows = await db.query(
      'books',
      where: 'id IN ($placeholders) AND status = ?',
      whereArgs: [...allIds, BookStatus.reading.name],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Book.fromMap).toList();
  }

  /// Busca livros para a tela de Biblioteca, com filtros opcionais de
  /// status, gênero e texto de busca (título ou autor), e ordenação.
  Future<List<Book>> getFilteredBooks({
    BookStatus? status,
    String? genre,
    String? searchQuery,
    BookSortOption sortBy = BookSortOption.recentlyUpdated,
  }) async {
    final db = await _dbHelper.database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (status != null) {
      conditions.add('status = ?');
      args.add(status.name);
    }
    if (genre != null && genre.isNotEmpty) {
      conditions.add('genre = ?');
      args.add(genre);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR author LIKE ?)');
      final like = '%${searchQuery.trim()}%';
      args.addAll([like, like]);
    }

    final rows = await db.query(
      'books',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : args,
      orderBy: sortBy._orderByClause,
    );

    return rows.map(Book.fromMap).toList();
  }

  Future<Book?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  /// Cadastra um novo livro. Apenas título e total de páginas são
  /// obrigatórios — os demais campos podem vir nulos/vazios.
  Future<int> addBook(Book book) async {
    final db = await _dbHelper.database;
    return db.insert('books', book.toMap()..remove('id'));
  }

  /// Atualiza todos os campos editáveis de um livro já cadastrado.
  Future<void> updateBook(Book book) async {
    final db = await _dbHelper.database;
    await db.update(
      'books',
      book.toMap()
        ..remove('id')
        ..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Apaga um livro e todo o seu histórico de sessões de leitura.
  Future<void> deleteBook(int bookId) async {
    final db = await _dbHelper.database;
    await db.delete('reading_sessions', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    final rows = await db.query('books', where: 'is_active = 1');
    return rows.length;
  }

  /// Marca/desmarca um livro como ativo. Respeita o limite de
  /// [maxActiveBooks] ativos simultaneamente.
  Future<SetActiveResult> setActive(int bookId, bool active) async {
    if (active) {
      final currentCount = await getActiveCount();
      if (currentCount >= maxActiveBooks) {
        return SetActiveResult.limitReached;
      }
    }

    final db = await _dbHelper.database;
    await db.update(
      'books',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [bookId],
    );
    return SetActiveResult.success;
  }

  /// Atualiza a página atual de um livro após um registro de leitura.
  /// Marca automaticamente como concluído se atingir o total de páginas.
  Future<void> updateProgress(int bookId, int newCurrentPage) async {
    final db = await _dbHelper.database;
    final book = await getById(bookId);
    if (book == null) return;

    final clampedPage = newCurrentPage.clamp(0, book.totalPages);
    final isFinished = clampedPage >= book.totalPages;

    await db.update(
      'books',
      {
        'current_page': clampedPage,
        'status':
            isFinished ? BookStatus.finished.name : BookStatus.reading.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  /// Retorna os valores distintos já cadastrados (para os filtros da
  /// Biblioteca e para sugestões de autopreenchimento).
  Future<List<String>> getDistinctGenres() => _getDistinctValues('genre');
  Future<List<String>> getDistinctAuthors() => _getDistinctValues('author');
  Future<List<String>> getDistinctSeries() => _getDistinctValues('series');
  Future<List<String>> getDistinctPublishers() =>
      _getDistinctValues('publisher');

  Future<List<String>> _getDistinctValues(String column) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT $column FROM books WHERE $column IS NOT NULL AND $column != "" ORDER BY $column COLLATE NOCASE ASC',
    );
    return rows.map((r) => r[column] as String).toList();
  }
}
