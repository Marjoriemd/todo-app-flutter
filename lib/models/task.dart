/// Modelo que representa una tarea en la aplicación.
/// Contiene todos los campos necesarios para gestionar una tarea,
/// incluyendo soporte para serialización a/desde Map (SQLite).
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String priority; // 'alta', 'media', 'baja'
  final DateTime createdAt;
  final DateTime? dueDate;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 'media',
    required this.createdAt,
    this.dueDate,
  });

  /// Crea una copia de la tarea con los campos especificados modificados.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  /// Convierte la tarea a un Map para almacenar en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
    };
  }

  /// Crea una instancia de Task a partir de un Map de SQLite.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: (map['is_completed'] as int) == 1,
      priority: map['priority'] as String? ?? 'media',
      createdAt: DateTime.parse(map['created_at'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
}
