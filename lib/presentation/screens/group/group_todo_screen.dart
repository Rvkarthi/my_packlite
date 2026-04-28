import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import '../../../domain/entities/todo.dart';
import '../../../presentation/providers/group_provider.dart';

class GroupTodoScreen extends ConsumerWidget {
  final String groupId;
  const GroupTodoScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(groupTodosProvider(groupId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Tasks'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done_rounded, size: 14, color: cs.primary),
                const Gap(4),
                Text('Live Sync',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: todosAsync.when(
        data: (todos) {
          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: cs.primary.withValues(alpha: 0.3)),
                  const Gap(16),
                  Text('No group tasks yet', style: theme.textTheme.titleLarge),
                  const Gap(8),
                  Text('Tap + to add a shared task',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          final done = todos.where((t) => t.isDone).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: todos.isEmpty ? 0 : done / todos.length,
                          backgroundColor: cs.primary.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Text('$done/${todos.length}',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: todos.length,
                  separatorBuilder: (ctx, i) => const Gap(8),
                  itemBuilder: (ctx, i) =>
                      _GroupTodoTile(todo: todos[i], groupId: groupId),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodo(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddTodo(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Group Task',
                style: Theme.of(ctx).textTheme.titleLarge),
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
                      .read(groupTodoActionsProvider(groupId).notifier)
                      .addTodo(v.trim());
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
                        .read(groupTodoActionsProvider(groupId).notifier)
                        .addTodo(ctrl.text.trim());
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

class _GroupTodoTile extends ConsumerWidget {
  final Todo todo;
  final String groupId;
  const _GroupTodoTile({required this.todo, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Slidable(
      key: Key(todo.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref
                .read(groupTodoActionsProvider(groupId).notifier)
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
            .read(groupTodoActionsProvider(groupId).notifier)
            .toggleTodo(todo.id, todo.isDone),
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
                width: 26, height: 26,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    if (todo.assignedTo != null)
                      Text(
                        'by ${todo.assignedTo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.primary.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
              Icon(Icons.group_rounded,
                  size: 16, color: cs.primary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
