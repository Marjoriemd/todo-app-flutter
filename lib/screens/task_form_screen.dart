import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Pantalla para crear o editar una tarea.
/// Si se recibe una [task] como parámetro, entra en modo edición;
/// de lo contrario, entra en modo creación.
class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = crear nueva tarea

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _databaseService = DatabaseService();
  final _uuid = const Uuid();

  String _selectedPriority = 'media';
  DateTime? _selectedDueDate;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, pre-cargamos los datos de la tarea
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedPriority = widget.task!.priority;
      _selectedDueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Guarda la tarea (crea o actualiza según el modo).
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        // Actualizar tarea existente
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );
        await _databaseService.updateTask(updatedTask);
      } else {
        // Crear nueva tarea
        final newTask = Task(
          id: _uuid.v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          createdAt: DateTime.now(),
          dueDate: _selectedDueDate,
        );
        await _databaseService.insertTask(newTask);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la tarea: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Muestra el selector de fecha de vencimiento.
  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDueDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Tarea' : 'Nueva Tarea'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTask,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Campo: Título ──────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'Escribe el título de la tarea',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'El título debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Campo: Descripción ─────────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Agrega más detalles sobre la tarea',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 16),

              // ── Selector: Prioridad ────────────────────────────────────
              Text(
                'Prioridad',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _PrioritySelector(
                selected: _selectedPriority,
                onChanged: (p) => setState(() => _selectedPriority = p),
              ),
              const SizedBox(height: 20),

              // ── Selector: Fecha de vencimiento ─────────────────────────
              Text(
                'Fecha de Vencimiento',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                            : 'Sin fecha de vencimiento',
                        style: TextStyle(
                          color: _selectedDueDate != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDueDate != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDueDate = null),
                          child: const Icon(Icons.close,
                              size: 18, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Botón Guardar ──────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTask,
                icon: Icon(_isEditing ? Icons.save : Icons.add_task),
                label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Tarea'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable para seleccionar la prioridad de una tarea.
class _PrioritySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  static const _priorities = [
    ('alta', 'Alta', Icons.keyboard_double_arrow_up_rounded),
    ('media', 'Media', Icons.drag_handle_rounded),
    ('baja', 'Baja', Icons.keyboard_double_arrow_down_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _priorities.map((entry) {
        final (value, label, icon) = entry;
        final color = AppTheme.getPriorityColor(value);
        final isSelected = selected == value;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
