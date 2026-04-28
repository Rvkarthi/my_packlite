import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import '../../../domain/entities/bag.dart';
import '../../../domain/entities/container_object.dart';
import '../../../presentation/providers/group_provider.dart';

class GroupContainersScreen extends ConsumerWidget {
  final String groupId;
  const GroupContainersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bagsAsync = ref.watch(groupContainersProvider(groupId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Containers'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddObject(context, ref,
                bagsAsync.value ?? []),
            icon: const Icon(Icons.add_box_rounded, size: 18),
            label: const Text('Add Object'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
          ),
          TextButton.icon(
            onPressed: () => _showCreateBag(context, ref),
            icon: const Icon(Icons.create_new_folder_rounded, size: 18),
            label: const Text('Add Container'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
          ),
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
                Text('Live',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: bagsAsync.when(
        data: (bags) => bags.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 64, color: cs.primary.withValues(alpha: 0.3)),
                    const Gap(16),
                    Text('No containers yet',
                        style: theme.textTheme.titleLarge),
                    const Gap(8),
                    Text('Tap "Add Container" to get started',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bags.length,
                itemBuilder: (ctx, i) =>
                    _GroupBagSection(bag: bags[i], groupId: groupId),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateBag(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    String selectedColor = '#4CAF50';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Container',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const Gap(16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Shared Bag, Group Gear',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
              ),
              const Gap(16),
              Text('Color', style: Theme.of(ctx).textTheme.titleMedium),
              const Gap(8),
              Wrap(
                spacing: 12,
                children: [
                  '#4CAF50', '#2196F3', '#FF5722', '#9C27B0',
                  '#FF9800', '#00BCD4', '#E91E63', '#607D8B',
                ].map((c) {
                  final color =
                      Color(int.parse(c.replaceFirst('#', '0xFF')));
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == c
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) {
                      ref
                          .read(groupContainerActionsProvider(groupId)
                              .notifier)
                          .addContainer(ctrl.text.trim(), selectedColor);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Create Container'),
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddObject(
      BuildContext context, WidgetRef ref, List<Bag> bags) {
    if (bags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a container first')));
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedBagId = bags.first.id;
    String selectedCategory = 'General';
    int quantity = 1;
    const categories = [
      'General', 'Clothing', 'Electronics', 'Toiletries',
      'Documents', 'Food & Snacks', 'Medicine', 'Accessories', 'Other',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Object',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const Gap(16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Object name *',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const Gap(12),
                DropdownButtonFormField<String>(
                  initialValue: selectedBagId,
                  decoration: const InputDecoration(
                    labelText: 'Container',
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                  items: bags
                      .map((b) => DropdownMenuItem(
                            value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedBagId = v);
                  },
                ),
                const Gap(12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedCategory = v);
                  },
                ),
                const Gap(12),
                Row(children: [
                  const Icon(Icons.numbers_rounded, size: 20),
                  const Gap(8),
                  Text('Quantity',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                  ),
                  Text('$quantity',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: () => setState(() => quantity++),
                  ),
                ]),
                const Gap(12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  ),
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      ref
                          .read(groupObjectActionsProvider(
                                  groupBagKey(groupId, selectedBagId))
                              .notifier)
                          .addObject(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            category: selectedCategory,
                            quantity: quantity,
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add Object'),
                  ),
                ),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Group Bag Section ─────────────────────────────────────────────────────────

class _GroupBagSection extends ConsumerWidget {
  final Bag bag;
  final String groupId;
  const _GroupBagSection({required this.bag, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bagColor =
        Color(int.parse(bag.color.replaceFirst('#', '0xFF')));
    final objectsAsync =
        ref.watch(groupObjectsProvider(groupBagKey(groupId, bag.id)));
    final objects = objectsAsync.value ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bagColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bagColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      color: bagColor, size: 20),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bag.name, style: theme.textTheme.titleMedium),
                      Text(
                          '${objects.length} object${objects.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => ref
                      .read(groupContainerActionsProvider(groupId).notifier)
                      .deleteContainer(bag.id),
                ),
              ],
            ),
          ),
          if (objects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.add_box_rounded,
                      size: 13, color: cs.primary.withValues(alpha: 0.7)),
                  const Gap(6),
                  Text(
                    'OBJECTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ...objects.map((obj) => _GroupObjectTile(
                obj: obj, groupId: groupId, bagId: bag.id)),
          ],
          const Gap(8),
        ],
      ),
    );
  }
}

// ── Group Object Tile ─────────────────────────────────────────────────────────

class _GroupObjectTile extends ConsumerWidget {
  final ContainerObject obj;
  final String groupId;
  final String bagId;
  const _GroupObjectTile(
      {required this.obj, required this.groupId, required this.bagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final key = groupBagKey(groupId, bagId);

    return Slidable(
      key: Key('gobj_${obj.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref
                .read(groupObjectActionsProvider(key).notifier)
                .deleteObject(obj.id),
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
            .read(groupObjectActionsProvider(key).notifier)
            .togglePacked(obj.id, obj.isPacked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: obj.isPacked
                ? cs.primary.withValues(alpha: 0.08)
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: obj.isPacked
                  ? cs.primary.withValues(alpha: 0.25)
                  : cs.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: obj.isPacked ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: obj.isPacked
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: obj.isPacked
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            obj.quantity > 1
                                ? '${obj.name} ×${obj.quantity}'
                                : obj.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration: obj.isPacked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: obj.isPacked
                                  ? cs.onSurface.withValues(alpha: 0.45)
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(obj.category,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (obj.description != null &&
                        obj.description!.isNotEmpty)
                      Text(obj.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
