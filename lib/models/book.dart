/// Status de leitura de um livro na estante do usuário.
enum BookStatus {
  reading,
  finished,
  onHold;

  static BookStatus fromString(String value) {
    return BookStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => BookStatus.reading,
    );
  }

  String get label {
    switch (this) {
      case BookStatus.reading:
        return 'Lendo';
      case BookStatus.finished:
        return 'Concluído';
      case BookStatus.onHold:
        return 'Em pausa';
    }
  }
}

/// Um livro na biblioteca do usuário.
/// Apenas [title] e [totalPages] são obrigatórios no cadastro —
/// todos os outros campos são opcionais.
class Book {
  final int? id;
  final String title;
  final String? author;
  final int totalPages;
  final int currentPage;
  final BookStatus status;
  final String? isbn;
  final String? coverPath;
  final String? series; // "saga"
  final String? genre;
  final String? publisher;
  final bool isActive;
  final DateTime updatedAt;

  const Book({
    this.id,
    required this.title,
    this.author,
    required this.totalPages,
    this.currentPage = 0,
    this.status = BookStatus.reading,
    this.isbn,
    this.coverPath,
    this.series,
    this.genre,
    this.publisher,
    this.isActive = false,
    required this.updatedAt,
  });

  /// Progresso de leitura, de 0.0 a 1.0.
  double get progress {
    if (totalPages <= 0) return 0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    BookStatus? status,
    String? isbn,
    String? coverPath,
    String? series,
    String? genre,
    String? publisher,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      isbn: isbn ?? this.isbn,
      coverPath: coverPath ?? this.coverPath,
      series: series ?? this.series,
      genre: genre ?? this.genre,
      publisher: publisher ?? this.publisher,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'current_page': currentPage,
      'status': status.name,
      'isbn': isbn,
      'cover_path': coverPath,
      'series': series,
      'genre': genre,
      'publisher': publisher,
      'is_active': isActive ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, Object?> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String?,
      totalPages: map['total_pages'] as int,
      currentPage: map['current_page'] as int,
      status: BookStatus.fromString(map['status'] as String),
      isbn: map['isbn'] as String?,
      coverPath: map['cover_path'] as String?,
      series: map['series'] as String?,
      genre: map['genre'] as String?,
      publisher: map['publisher'] as String?,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
