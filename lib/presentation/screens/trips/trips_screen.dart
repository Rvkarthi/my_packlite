import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../domain/entities/trip.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/trips/create'),
          ),
        ],
      ),
      body: trips.when(
        data: (list) => list.isEmpty
            ? _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (ctx, i) => const Gap(12),
                itemBuilder: (ctx, i) => _TripListItem(trip: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading trips: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trips/create'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TripListItem extends ConsumerWidget {
  final Trip trip;
  const _TripListItem({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateStr = trip.startDate != null
        ? DateFormat('MMM d').format(trip.startDate!)
        : 'No date';

    return Dismissible(
      key: Key(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) {
        ref.read(tripsProvider.notifier).deleteTrip(trip.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${trip.title}" deleted')),
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/trips/${trip.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  trip.type == TripType.group
                      ? Icons.group_rounded
                      : Icons.person_rounded,
                  color: cs.primary,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: theme.textTheme.titleMedium),
                    const Gap(2),
                    Text(
                      trip.locations.isNotEmpty
                          ? trip.locations.map((l) => l.name).join(' → ')
                          : 'No locations',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(dateStr, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_rounded,
              size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const Gap(16),
          Text('No trips yet', style: theme.textTheme.headlineSmall),
          const Gap(8),
          Text('Create your first trip to get started',
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

