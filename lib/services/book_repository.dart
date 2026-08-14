import 'package:sqflite/sqflite.dart';
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

class BookRepository {
  BookRepository._internal();
  static final BookRepository instance = BookRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Retorna os livros não encerrados (status 'reading'), do mais
  /// recentemente atualizado para o mais antigo. Usado no Dashboard
  /// (limitado a 3) e no seletor de livro do registro de leitura
  /// (sem limite).
  Future<List<Book>> getUnfinishedBooks({int? limit}) async {
    final db = await _dbHelper.database;
    await _seedSampleBooksIfEmpty(db);

    final rows = await db.query(
      'books',
      where: 'status = ?',
      whereArgs: [BookStatus.reading.name],
      orderBy: 'updated_at DESC',
      limit: limit,
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
    await _seedSampleBooksIfEmpty(db);

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

  /// Atualiza todos os dados de um livro existente.
  Future<void> updateBook(Book book) async {
    final db = await _dbHelper.database;
    if (book.id == null) return;

    await db.update(
      'books',
      book.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Deleta um livro e todos os seus registros de leitura.
  Future<void> deleteBook(int bookId) async {
    final db = await _dbHelper.database;
    
    // Deleta registros de leitura do livro
    await db.delete(
      'reading_sessions',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    
    // Deleta o livro
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  /// Retorna os gêneros distintos já cadastrados (para os filtros da
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

  /// Popula dois livros de exemplo na primeira execução, para que o
  /// Dashboard e o registro de leitura já tenham o que mostrar antes
  /// do usuário cadastrar seus próprios livros.
  Future<void> _seedSampleBooksIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM books'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now().toIso8601String();
    await db.insert('books', {
      'title': 'Duna',
      'author': 'Frank Herbert',
      'total_pages': 688,
      'current_page': 120,
      'status': BookStatus.reading.name,
      'genre': 'Ficção científica',
      'series': 'Crônicas de Duna',
      'publisher': 'Aleph',
      'updated_at': now,
    });
    await db.insert('books', {
      'title': 'O Hobbit',
      'author': 'J.R.R. Tolkien',
      'total_pages': 310,
      'current_page': 40,
      'status': BookStatus.reading.name,
      'genre': 'Fantasia',
      'series': 'O Senhor dos Anéis',
      'publisher': 'HarperCollins',
      'updated_at': now,
    });
  }
}
