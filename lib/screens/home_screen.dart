import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

/// Pantalla principal que muestra el listado de tareas.
/// Permite filtrar entre pendientes y completadas, y acceder
/// a las funciones de crear, editar y eliminar tareas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _databaseService = DatabaseService();
  late final TabController _tabController;

  List<Task> _pendingTasks = [];
  List<Task> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carga todas las tareas desde la base de datos y las separa por estado.
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final allTasks = await _databaseService.getAllTasks();
      setState(() {
        _pendingTasks = allTasks.where((t) => !t.isCompleted).toList();
        _completedTasks = allTasks.where((t) => t.isCompleted).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar las tareas');
    }
  }

  /// Cambia el estado de completado de una tarea.
  Future<void> _toggleTask(Task task) async {
    try {
      await _databaseService.toggleTaskCompletion(
        task.id,
        !task.isCompleted,
      );
      await _loadTasks();
    } catch (e) {
      _showError('Error al actualizar la tarea');
    }
  }

  /// Elimina una tarea con confirmación del usuario.
  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Estás segura de que quieres eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteTask(task.id);
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea eliminada')),
          );
        }
      } catch (e) {
        _showError('Error al eliminar la tarea');
      }
    }
  }

  /// Navega al formulario para crear o editar una tarea.
  Future<void> _openTaskForm({Task? task}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    if (result == true) await _loadTasks();
  }

  /// Elimina todas las tareas completadas con confirmación.
  Future<void> _clearCompleted() async {
    if (_completedTasks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar completadas'),
        content: Text(
          '¿Eliminar ${_completedTasks.length} tarea(s) completada(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.deleteCompletedTasks();
      await _loadTasks();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Pendientes (${_pendingTasks.length})'),
            Tab(text: 'Completadas (${_completedTasks.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearCompleted,
            tooltip: 'Limpiar completadas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TaskList(
                  tasks: _pendingTasks,
                  emptyMessage: 'No hay tareas pendientes.\n¡Agrega una nueva!',
                  emptyIcon: Icons.check_circle_outline,
                  onToggle: _toggleTask,
                  onEdit: _openTaskForm,
                  onDelete: _deleteTask,
                ),
                _TaskList(
                  tasks: _completedTasks,
                  emptyMessage: 'No hay tareas completadas aún.',
                  emptyIcon: Icons.inbox_outlined,
                  onToggle: _toggleTask,
                  onEdit: _openTaskForm,
                  onDelete: _deleteTask,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Tarea'),
      ),
    );
  }
}

/// Widget privado que muestra una lista de tareas o un estado vacío.
class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String emptyMessage;
  final IconData emptyIcon;
  final void Function(Task) onToggle;
  final void Function({Task? task}) onEdit;
  final void Function(Task) onDelete;

  const _TaskList({
    required this.tasks,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onToggle: () => onToggle(task),
            onEdit: () => onEdit(task: task),
            onDelete: () => onDelete(task),
          );
        },
      ),
    );
  }
}
