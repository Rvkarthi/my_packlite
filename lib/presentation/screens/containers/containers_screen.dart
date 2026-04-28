import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import '../../../domain/entities/bag.dart';
import '../../../domain/entities/container_object.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../presentation/providers/bag_provider.dart';
import '../../../presentation/providers/container_object_provider.dart';
import '../../../presentation/providers/item_provider.dart';
import '../../../presentation/providers/trip_provider.dart';

class ContainersScreen extends ConsumerStatefulWidget {
  final String? tripId;
  const ContainersScreen({super.key, this.tripId});

  @override
  ConsumerState<ContainersScreen> createState() => _ContainersScreenState();
}

class _ContainersScreenState extends ConsumerState<ContainersScreen> {
  String? _selectedTripId;
  bool _pickerShown = false;

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.tripId;
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
                Icon(Icons.inventory_2_rounded, color: cs.primary),
                const Gap(10),
                Text('Select a Trip', style: theme.textTheme.titleLarge),
              ]),
              const Gap(6),
              Text('Which trip\'s containers do you want to view?',
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

    if (!_pickerShown && widget.tripId == null && trips.isNotEmpty) {
      _pickerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedTripId == null) {
          _showTripPicker(trips);
        }
      });
    }

    final effectiveTripId = _selectedTripId ?? (trips.isNotEmpty ? trips.first.id : null);

    if (effectiveTripId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Containers')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              const Gap(16),
              Text('No trip selected',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              Text('Select a trip to view containers',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    final selectedTrip = trips.firstWhere(
        (t) => t.id == effectiveTripId,
        orElse: () => trips.first);

    return _ContainersView(
      tripId: effectiveTripId,
      tripTitle: selectedTrip.title,
      allTrips: trips,
      onSwitchTrip: trips.length > 1 ? () => _showTripPicker(trips) : null,
    );
  }
}

class _ContainersView extends ConsumerWidget {
  final String tripId;
  final String tripTitle;
  final List<Trip> allTrips;
  final VoidCallback? onSwitchTrip;
  const _ContainersView({
    required this.tripId,
    required this.tripTitle,
    required this.allTrips,
    this.onSwitchTrip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bagsAsync = ref.watch(tripBagsProvider(tripId));
    final itemsAsync = ref.watch(tripItemsProvider(tripId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tripTitle),
        actions: [
          if (onSwitchTrip != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch trip',
              onPressed: onSwitchTrip,
            ),
          TextButton.icon(
            onPressed: () =>
                _showAddObject(context, ref, bagsAsync.value ?? []),
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
          const Gap(4),
        ],
      ),
      body: bagsAsync.when(
        data: (bags) => itemsAsync.when(
          data: (items) => bags.isEmpty
              ? _EmptyState(
                  onAddContainer: () => _showCreateBag(context, ref),
                  onAddObject: () => _showAddObject(context, ref, bags),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bags.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == bags.length) {
                      final unassigned = items
                          .where((it) => it.isSelected && it.bagId == null)
                          .toList();
                      if (unassigned.isEmpty) return const SizedBox.shrink();
                      return _BagSection(
                        bag: null,
                        packingItems: unassigned,
                        allBags: bags,
                        tripId: tripId,
                      );
                    }
                    final bag = bags[i];
                    final bagItems = items
                        .where((it) => it.isSelected && it.bagId == bag.id)
                        .toList();
                    return _BagSection(
                      bag: bag,
                      packingItems: bagItems,
                      allBags: bags,
                      tripId: tripId,
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
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
              Row(children: [
                const Icon(Icons.create_new_folder_rounded),
                const Gap(10),
                Text('New Container',
                    style: Theme.of(ctx).textTheme.titleLarge),
              ]),
              const Gap(16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Carry-On, Backpack, Checked Bag',
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
                  final color = Color(int.parse(c.replaceFirst('#', '0xFF')));
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
                      ref.read(tripBagsProvider(tripId).notifier).createBag(
                            name: ctrl.text.trim(), color: selectedColor);
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

  void _showAddObject(BuildContext context, WidgetRef ref, List<Bag> bags) {
    if (bags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Create a container first')));
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
                Row(children: [
                  const Icon(Icons.add_box_rounded),
                  const Gap(10),
                  Text('Add Object',
                      style: Theme.of(ctx).textTheme.titleLarge),
                ]),
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
                    onPressed:
                        quantity > 1 ? () => setState(() => quantity--) : null,
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
                          .read(bagObjectsProvider(selectedBagId).notifier)
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

// ── Bag Section ───────────────────────────────────────────────────────────────

class _BagSection extends ConsumerWidget {
  final Bag? bag;
  final List<PackingItem> packingItems;
  final List<Bag> allBags;
  final String tripId;
  const _BagSection({
    required this.bag,
    required this.packingItems,
    required this.allBags,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bagColor = bag != null
        ? Color(int.parse(bag!.color.replaceFirst('#', '0xFF')))
        : cs.onSurface.withValues(alpha: 0.3);

    final objectsAsync =
        bag != null ? ref.watch(bagObjectsProvider(bag!.id)) : null;
    final objects = objectsAsync?.value ?? [];
    final totalItems = packingItems.length + objects.length;

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
                      Text(bag?.name ?? 'Unassigned',
                          style: theme.textTheme.titleMedium),
                      Text('$totalItems item${totalItems == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (bag != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => ref
                        .read(tripBagsProvider(tripId).notifier)
                        .deleteBag(bag!.id),
                  ),
              ],
            ),
          ),
          if (packingItems.isNotEmpty) ...[
            _SectionLabel('Packing Items', Icons.backpack_rounded),
            ...packingItems.map((item) => _PackingItemTile(
                  item: item, bags: allBags, tripId: tripId)),
          ],
          if (objects.isNotEmpty) ...[
            _SectionLabel('Objects', Icons.add_box_rounded),
            ...objects.map((obj) =>
                _ObjectTile(obj: obj, bagId: bag!.id)),
          ],
          const Gap(8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: cs.primary.withValues(alpha: 0.7)),
          const Gap(6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Packing Item Tile ─────────────────────────────────────────────────────────

class _PackingItemTile extends ConsumerWidget {
  final PackingItem item;
  final List<Bag> bags;
  final String tripId;
  const _PackingItemTile(
      {required this.item, required this.bags, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Slidable(
      key: Key('pi_${item.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref
                .read(tripItemsProvider(tripId).notifier)
                .deleteItem(item.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Remove',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.backpack_rounded,
            size: 18,
            color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        title: Text(item.name, style: theme.textTheme.bodyLarge),
        subtitle: Text(item.category, style: theme.textTheme.bodySmall),
        trailing: PopupMenuButton<String?>(
          icon: const Icon(Icons.move_to_inbox_rounded, size: 18),
          tooltip: 'Move to container',
          onSelected: (bagId) {
            ref.read(tripItemsProvider(tripId).notifier).updateItem(
                  item.copyWith(bagId: bagId));
          },
          itemBuilder: (_) => [
            const PopupMenuItem<String?>(
                value: null, child: Text('Unassigned')),
            ...bags.map((b) =>
                PopupMenuItem<String?>(value: b.id, child: Text(b.name))),
          ],
        ),
      ),
    );
  }
}

// ── Container Object Tile ─────────────────────────────────────────────────────

class _ObjectTile extends ConsumerWidget {
  final ContainerObject obj;
  final String bagId;
  const _ObjectTile({required this.obj, required this.bagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Slidable(
      key: Key('obj_${obj.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref
                .read(bagObjectsProvider(bagId).notifier)
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
        onTap: () =>
            ref.read(bagObjectsProvider(bagId).notifier).togglePacked(obj.id),
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
                    if (obj.notes != null && obj.notes!.isNotEmpty)
                      Text('Note: ${obj.notes}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.primary.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic)),
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

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddContainer;
  final VoidCallback onAddObject;
  const _EmptyState(
      {required this.onAddContainer, required this.onAddObject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 64, color: cs.primary.withValues(alpha: 0.3)),
          const Gap(16),
          Text('No containers yet', style: theme.textTheme.titleLarge),
          const Gap(8),
          Text('Create bags to organize your items',
              style: theme.textTheme.bodyMedium),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onAddContainer,
                icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                label: const Text('Add Container'),
              ),
              const Gap(12),
              OutlinedButton.icon(
                onPressed: onAddObject,
                icon: const Icon(Icons.add_box_rounded, size: 18),
                label: const Text('Add Object'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
