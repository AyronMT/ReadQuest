/// Como aquela sessão de leitura foi registrada.
enum ReadingMode {
  timer,
  manual;

  static ReadingMode fromString(String value) {
    return ReadingMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ReadingMode.manual,
    );
  }
}

/// Emoção do usuário em relação à leitura daquela sessão —
/// opcional, escolhida entre opções pré-definidas.
enum ReadingEmotion {
  loving,
  enjoying,
  neutral,
  bored,
  frustrated;

  static ReadingEmotion? fromString(String? value) {
    if (value == null) return null;
    return ReadingEmotion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReadingEmotion.neutral,
    );
  }

  String get emoji {
    switch (this) {
      case ReadingEmotion.loving:
        return '😍';
      case ReadingEmotion.enjoying:
        return '🙂';
      case ReadingEmotion.neutral:
        return '😐';
      case ReadingEmotion.bored:
        return '😕';
      case ReadingEmotion.frustrated:
        return '😣';
    }
  }

  String get label {
    switch (this) {
      case ReadingEmotion.loving:
        return 'Amando';
      case ReadingEmotion.enjoying:
        return 'Gostando';
      case ReadingEmotion.neutral:
        return 'Neutro';
      case ReadingEmotion.bored:
        return 'Meh';
      case ReadingEmotion.frustrated:
        return 'Frustrado';
    }
  }
}

class ReadingSession {
  final int? id;
  final int bookId;
  final int pagesRead;
  final int durationMinutes;
  final ReadingMode mode;
  final ReadingEmotion? emotion;
  final String? feedback;
  final DateTime createdAt;

  const ReadingSession({
    this.id,
    required this.bookId,
    required this.pagesRead,
    required this.durationMinutes,
    required this.mode,
    this.emotion,
    this.feedback,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'pages_read': pagesRead,
      'duration_minutes': durationMinutes,
      'mode': mode.name,
      'emotion': emotion?.name,
      'feedback': feedback,
      'session_date': _dateKey(createdAt),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  factory ReadingSession.fromMap(Map<String, Object?> map) {
    return ReadingSession(
      id: map['id'] as int?,
      bookId: map['book_id'] as int,
      pagesRead: map['pages_read'] as int,
      durationMinutes: map['duration_minutes'] as int,
      mode: ReadingMode.fromString(map['mode'] as String),
      emotion: ReadingEmotion.fromString(map['emotion'] as String?),
      feedback: map['feedback'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Resumo estatístico exibido no pop-up logo após um registro de leitura.
class ReadingStats {
  final String bookTitle;
  final int pagesReadNow;
  final int durationMinutesNow;
  final int totalPagesToday;
  final int totalMinutesToday;
  final int currentStreak;
  final ReadingEmotion? emotion;
  final int pointsEarned;

  const ReadingStats({
    required this.bookTitle,
    required this.pagesReadNow,
    required this.durationMinutesNow,
    required this.totalPagesToday,
    required this.totalMinutesToday,
    required this.currentStreak,
    this.emotion,
    this.pointsEarned = 0,
  });

  /// Páginas por minuto nesta sessão específica.
  double get pagesPerMinute {
    if (durationMinutesNow <= 0) return 0;
    return pagesReadNow / durationMinutesNow;
  }

  /// Minutos gastos, em média, para ler uma página nesta sessão.
  double get minutesPerPage {
    if (pagesReadNow <= 0) return 0;
    return durationMinutesNow / pagesReadNow;
  }
}
