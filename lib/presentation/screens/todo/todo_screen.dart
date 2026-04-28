import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import '../../../domain/entities/todo.dart';
import '../../../domain/entities/trip.dart';
import '../../../presentation/providers/todo_provider.dart';
import '../../../presentation/providers/trip_provider.dart';

class TodoScreen extends ConsumerStatefulWidget {
  final String? tripId;
  const TodoScreen({super.key, this.tripId});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTripId;
  bool _pickerShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedTripId = widget.tripId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTripPicker(List<Trip> trips) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.luggage_rounded, color: cs.primary),
                const Gap(10),
                Text('Select a Trip', style: theme.textTheme.titleLarge),
              ]),
              const Gap(6),
              Text('Which trip\'s tasks do you want to view?',
                  style: theme.textTheme.bodySmall),
              const Gap(16),
              ...trips.map((t) => ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          t.type == TripType.group
                              ? Icons.group_rounded
                              : Icons.person_rounded,
                          color: cs.primary,
                          size: 20),
                    ),
                    title: Text(t.title),
                    subtitle: t.locations.isNotEmpty
                        ? Text(t.locations.first.name,
                            style: theme.textTheme.bodySmall)
                        : null,
                    onTap: () {
                      setState(() => _selectedTripId = t.id);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final trips = tripsAsync.value ?? [];

    // Auto-show picker once when no tripId provided and trips are loaded
    if (!_pickerShown && widget.tripId == null && trips.isNotEmpty) {
      _pickerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedTripId == null) {
          _showTripPicker(trips);
        }
      });
    }

    final tripId = _selectedTripId ?? (trips.isNotEmpty ? trips.first.id : null);
    final selectedTrip = tripId != null
        ? trips.firstWhere((t) => t.id == tripId, orElse: () => trips.first)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTrip?.title ?? 'Tasks'),
        actions: [
          if (trips.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch trip',
              onPressed: () => _showTripPicker(trips),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Individual'),
            Tab(text: 'Group (Synced)'),
          ],
        ),
      ),
      body: tripId == null
          ? _NoTripState(onPick: trips.isNotEmpty ? () => _showTripPicker(trips) : null)
          : TabBarView(
              controller: _tabController,
              children: [
                _TodoList(tripId: tripId, isGroup: false),
                _TodoList(tripId: tripId, isGroup: true),
              ],
            ),
      floatingActionButton: tripId != null
          ? FloatingActionButton(
              onPressed: () => _showAddTodo(context, tripId,
                  _tabController.index == 1),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _showAddTodo(
      BuildContext context, String tripId, bool isGroup) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGroup ? 'Add Group Task' : 'Add Task',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const Gap(16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Task title...',
                prefixIcon: Icon(Icons.task_alt_rounded),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  ref
                      .read(tripTodosProvider(tripId).notifier)
                      .addTodo(title: v.trim(), isGroup: isGroup);
                  Navigator.pop(ctx);
                }
              },
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    ref
                        .read(tripTodosProvider(tripId).notifier)
                        .addTodo(
                            title: ctrl.text.trim(), isGroup: isGroup);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Task'),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}

class _TodoList extends ConsumerWidget {
  final String tripId;
  final bool isGroup;
  const _TodoList({required this.tripId, required this.isGroup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final todosAsync = ref.watch(tripTodosProvider(tripId));

    return todosAsync.when(
      data: (todos) {
        final filtered = todos.where((t) => t.isGroup == isGroup).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: cs.primary.withValues(alpha: 0.3)),
                const Gap(16),
                Text('No tasks yet', style: theme.textTheme.titleLarge),
                const Gap(8),
                Text('Tap + to add a task',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }
        final done = filtered.where((t) => t.isDone).length;
        return Column(
          children: [
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: filtered.isEmpty
                              ? 0
                              : done / filtered.length,
                          backgroundColor: cs.primary.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Text('$done/${filtered.length}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                separatorBuilder: (ctx, i) => const Gap(8),
                itemBuilder: (ctx, i) =>
                    _TodoTile(todo: filtered[i], tripId: tripId),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _TodoTile extends ConsumerWidget {
  final Todo todo;
  final String tripId;
  const _TodoTile({required this.todo, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Slidable(
      key: Key(todo.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEditDialog(context, ref),
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref
                .read(tripTodosProvider(tripId).notifier)
                .deleteTodo(todo.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => ref
            .read(tripTodosProvider(tripId).notifier)
            .toggleTodo(todo.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: todo.isDone
                ? cs.primary.withValues(alpha: 0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: todo.isDone
                  ? cs.primary.withValues(alpha: 0.2)
                  : cs.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: todo.isDone ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: todo.isDone
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: todo.isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  todo.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: todo.isDone
                        ? TextDecoration.lineThrough
                        : null,
                    color: todo.isDone
                        ? cs.onSurface.withValues(alpha: 0.5)
                        : cs.onSurface,
                  ),
                ),
              ),
              if (todo.isGroup)
                Icon(Icons.group_rounded,
                    size: 16, color: cs.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: todo.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref
                    .read(tripTodosProvider(tripId).notifier)
                    .updateTodo(todo.copyWith(title: ctrl.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NoTripState extends StatelessWidget {
  final VoidCallback? onPick;
  const _NoTripState({this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const Gap(16),
          Text('No trip selected', style: theme.textTheme.titleLarge),
          const Gap(8),
          Text('Select a trip to view its tasks',
              style: theme.textTheme.bodyMedium),
          if (onPick != null) ...[
            const Gap(20),
            ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.luggage_rounded),
              label: const Text('Select Trip'),
            ),
          ],
        ],
      ),
    );
  }
}


