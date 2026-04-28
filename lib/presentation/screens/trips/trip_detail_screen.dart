import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/trip.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../presentation/providers/item_provider.dart';
import '../../../presentation/providers/home_provider.dart';
import '../../../services/ai/offline_ai_service.dart';
import 'create_trip_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    return tripsAsync.when(
      data: (trips) {
        final trip = trips.where((t) => t.id == tripId).firstOrNull;
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Trip not found')),
          );
        }
        return _TripDetailView(trip: trip);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _TripDetailView extends ConsumerWidget {
  final Trip trip;
  const _TripDetailView({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final itemsAsync = ref.watch(tripItemsProvider(trip.id));
    final fmt = DateFormat('MMM d, yyyy');

    // AI suggestions for first location
    final firstLocation =
        trip.locations.isNotEmpty ? trip.locations.first : null;
    final aiParams = firstLocation != null
        ? AiSuggestionParams(
            locationName: firstLocation.name,
            tempCelsius: firstLocation.tempCelsius,
            weatherCondition: firstLocation.weatherCondition,
          )
        : null;
    final aiAsync =
        aiParams != null ? ref.watch(aiSuggestionsProvider(aiParams)) : null;

    double progress = 0.0;
    if (itemsAsync.hasValue) {
      final items = itemsAsync.value!;
      final selected = items.where((i) => i.isSelected).length;
      final packed = items.where((i) => i.isSelected && i.isPacked).length;
      progress = selected > 0 ? packed / selected : 0.0;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.luggage_rounded,
                      size: 80, color: Colors.white24),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTripScreen(existingTrip: trip),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Trip'),
                      content: Text('Delete "${trip.title}"?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(tripsProvider.notifier)
                        .deleteTrip(trip.id);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trip Plan Progress',
                              style: theme.textTheme.bodySmall,
                            ),
                            const Gap(6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: cs.primary.withValues(alpha: 0.15),
                                valueColor:
                                    AlwaysStoppedAnimation(cs.primary),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      Text('${(progress * 100).round()}%',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: cs.primary)),
                    ],
                  ),
                  const Gap(20),
                  // Dates
                  if (trip.startDate != null)
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      text: trip.endDate != null
                          ? '${fmt.format(trip.startDate!)} – ${fmt.format(trip.endDate!)}'
                          : fmt.format(trip.startDate!),
                    ),
                  // Locations
                  if (trip.locations.isNotEmpty) ...[
                    const Gap(8),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      text: trip.locations.map((l) => l.name).join(' → '),
                    ),
                  ],
                  const Gap(24),
                  // Action buttons
                  Text('Trip Plan', style: theme.textTheme.titleLarge),
                  const Gap(12),
                  _ActionGrid(trip: trip),
                  const Gap(24),
                  // AI Suggestions
                  if (aiAsync != null) ...[
                    Text('AI Suggestions', style: theme.textTheme.titleLarge),
                    const Gap(8),
                    aiAsync.when(
                      data: (ai) => _AiSuggestionsCard(
                          ai: ai, tripId: trip.id, ref: ref),
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const Gap(8),
        Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final Trip trip;
  const _ActionGrid({required this.trip});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _ActionCard(
          icon: Icons.backpack_rounded,
          label: 'Packing List',
          onTap: () => context.push('/trips/${trip.id}/packing'),
        ),
        _ActionCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Tasks',
          onTap: () => context.push('/trips/${trip.id}/todo'),
        ),
        _ActionCard(
          icon: Icons.inventory_2_rounded,
          label: 'Containers',
          onTap: () => context.push('/trips/${trip.id}/containers'),
        ),
        if (trip.type == TripType.group)
          _ActionCard(
            icon: Icons.group_rounded,
            label: 'Group',
            onTap: () => context.push('/group'),
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const Gap(8),
            Text(label, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _AiSuggestionsCard extends StatelessWidget {
  final AiSuggestion ai;
  final String tripId;
  final WidgetRef ref;
  const _AiSuggestionsCard(
      {required this.ai, required this.tripId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 18),
              const Gap(8),
              Expanded(
                child: Text(ai.reasoning,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.primary)),
              ),
            ],
          ),
          const Gap(12),
          if (ai.places.isNotEmpty) ...[
            Text('Suggested Places', style: theme.textTheme.titleMedium),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ai.places
                  .take(6)
                  .map((p) => Chip(
                        label: Text(p, style: const TextStyle(fontSize: 12)),
                        avatar: Icon(Icons.place_rounded,
                            size: 14, color: cs.primary),
                      ))
                  .toList(),
            ),
            const Gap(12),
          ],
          Text('Suggested Items', style: theme.textTheme.titleMedium),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ai.packingItems
                .take(10)
                .map((item) => ActionChip(
                      label: Text(item, style: const TextStyle(fontSize: 12)),
                      avatar: Icon(Icons.add_rounded,
                          size: 14, color: cs.primary),
                      onPressed: () {
                        ref
                            .read(tripItemsProvider(tripId).notifier)
                            .addItem(name: item, category: 'AI Suggested');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"$item" added to list')),
                        );
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

