import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../presentation/providers/item_provider.dart';

class PackingScreen extends ConsumerStatefulWidget {
  final String tripId;
  const PackingScreen({super.key, required this.tripId});

  @override
  ConsumerState<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends ConsumerState<PackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<String>> _catalog = {};
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final raw = await rootBundle.loadString('assets/data/catalog.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final cats = data['categories'] as List;
    final map = <String, List<String>>{};
    for (final cat in cats) {
      map[cat['name'] as String] =
          (cat['items'] as List).cast<String>();
    }
    if (mounted) setState(() => _catalog = map);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(packingModeProvider);
    final hidePacked = ref.watch(hidePackedProvider);
    final itemsAsync = ref.watch(tripItemsProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing List'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            ref.read(packingModeProvider.notifier).set(
                i == 0 ? PackingMode.catalog : PackingMode.suitcase);
          },
          tabs: const [
            Tab(text: 'Catalog'),
            Tab(text: 'Suitcase'),
          ],
        ),
        actions: [
          if (mode == PackingMode.suitcase)
            IconButton(
              icon: Icon(hidePacked
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded),
              tooltip: hidePacked ? 'Show packed' : 'Hide packed',
              onPressed: () {
                ref.read(hidePackedProvider.notifier).toggle();
              },
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'reset') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset Packed'),
                    content: const Text(
                        'Mark all items as unpacked?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(tripItemsProvider(widget.tripId).notifier)
                      .resetPacked();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reset', child: Text('Reset Packed')),
            ],
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) => TabBarView(
          controller: _tabController,
          children: [
            _CatalogView(
              tripId: widget.tripId,
              catalog: _catalog,
              selectedItems: items,
              searchQuery: _searchQuery,
              selectedCategory: _selectedCategory,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              onCategoryChanged: (c) =>
                  setState(() => _selectedCategory = c),
            ),
            _SuitcaseView(
              tripId: widget.tripId,
              items: items,
              hidePacked: hidePacked,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── CATALOG VIEW ────────────────────────────────────────────────────────────

class _CatalogView extends ConsumerWidget {
  final String tripId;
  final Map<String, List<String>> catalog;
  final List<PackingItem> selectedItems;
  final String searchQuery;
  final String? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;

  const _CatalogView({
    required this.tripId,
    required this.catalog,
    required this.selectedItems,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedNames =
        selectedItems.where((i) => i.isSelected).map((i) => i.name).toSet();

    final categories = catalog.keys.toList();
    final displayCat = selectedCategory ?? (categories.isNotEmpty ? categories.first : null);
    final items = displayCat != null ? (catalog[displayCat] ?? []) : <String>[];
    final filtered = searchQuery.isEmpty
        ? items
        : items
            .where((i) => i.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search 250+ items...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            separatorBuilder: (ctx, i) => const Gap(8),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSelected = cat == displayCat;
              return FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => onCategoryChanged(cat),
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        const Gap(8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final name = filtered[i];
              final isSelected = selectedNames.contains(name);
              return _CatalogItemTile(
                name: name,
                category: displayCat ?? '',
                isSelected: isSelected,
                onTap: () async {
                  if (isSelected) {
                    // Deselect — find and toggle
                    final item = selectedItems
                        .where((it) => it.name == name && it.isSelected)
                        .firstOrNull;
                    if (item != null) {
                      await ref
                          .read(tripItemsProvider(tripId).notifier)
                          .toggleSelected(item.id);
                    }
                  } else {
                    // Check if item exists but unselected
                    final existing = selectedItems
                        .where((it) => it.name == name && !it.isSelected)
                        .firstOrNull;
                    if (existing != null) {
                      await ref
                          .read(tripItemsProvider(tripId).notifier)
                          .toggleSelected(existing.id);
                    } else {
                      await ref
                          .read(tripItemsProvider(tripId).notifier)
                          .addItem(name: name, category: displayCat ?? '');
                    }
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogItemTile extends StatelessWidget {
  final String name;
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  const _CatalogItemTile({
    required this.name,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      title: Text(name, style: theme.textTheme.bodyLarge),
      subtitle: Text(category, style: theme.textTheme.bodySmall),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
      onTap: onTap,
    );
  }
}

// ─── SUITCASE VIEW ───────────────────────────────────────────────────────────

class _SuitcaseView extends ConsumerWidget {
  final String tripId;
  final List<PackingItem> items;
  final bool hidePacked;

  const _SuitcaseView({
    required this.tripId,
    required this.items,
    required this.hidePacked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = items.where((i) => i.isSelected).toList();
    final displayed = hidePacked
        ? selected.where((i) => !i.isPacked).toList()
        : selected;

    final packed = selected.where((i) => i.isPacked).length;
    final total = selected.length;
    final progress = total > 0 ? packed / total : 0.0;

    if (selected.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.backpack_rounded,
                size: 64, color: cs.primary.withValues(alpha: 0.3)),
            const Gap(16),
            Text('No items selected', style: theme.textTheme.titleLarge),
            const Gap(8),
            Text('Go to Catalog to add items',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Group by category
    final byCategory = <String, List<PackingItem>>{};
    for (final item in displayed) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$packed / $total packed',
                      style: theme.textTheme.bodyMedium),
                  Text('${(progress * 100).round()}%',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.primary)),
                ],
              ),
              const Gap(8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: byCategory.length,
            itemBuilder: (ctx, catIdx) {
              final category = byCategory.keys.elementAt(catIdx);
              final catItems = byCategory[category]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Text(category,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: cs.primary)),
                  ),
                  ...catItems.map((item) => _SuitcaseItemTile(
                        item: item,
                        tripId: tripId,
                      )),
                  const Gap(8),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuitcaseItemTile extends ConsumerWidget {
  final PackingItem item;
  final String tripId;
  const _SuitcaseItemTile({required this.item, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Slidable(
      key: Key(item.id),
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
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => ref
            .read(tripItemsProvider(tripId).notifier)
            .togglePacked(item.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: item.isPacked
                ? cs.primary.withValues(alpha: 0.1)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isPacked
                  ? cs.primary.withValues(alpha: 0.3)
                  : cs.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isPacked ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: item.isPacked
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: item.isPacked
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: item.isPacked
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.isPacked
                        ? cs.onSurface.withValues(alpha: 0.5)
                        : cs.onSurface,
                  ),
                ),
              ),
              if (item.shareStatus != ShareStatus.personal)
                _ShareBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareBadge extends StatelessWidget {
  final PackingItem item;
  const _ShareBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSharing = item.shareStatus == ShareStatus.sharing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSharing
            ? cs.primary.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSharing
            ? item.providerName.isNotEmpty
                ? item.providerName
                : 'Sharing'
            : 'Needed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSharing ? cs.primary : Colors.orange,
        ),
      ),
    );
  }
}

