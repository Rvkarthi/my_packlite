import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/home_provider.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../presentation/providers/group_provider.dart';
import '../../../presentation/widgets/common/main_scaffold.dart';
import '../../../services/ai/weather_service.dart';
import '../../../domain/entities/trip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final trips = ref.watch(tripsProvider);
    final weather = ref.watch(homeWeatherProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar 
          SliverAppBar(
            floating: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.backpack_rounded,
                      color: Colors.white, size: 18),
                ),
                const Gap(8),
                Text('PackLite', style: theme.textTheme.titleLarge),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_rounded),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Weather ──────────────────────────────────────────
                  weather.when(
                    data: (w) => w != null
                        ? _WeatherCard(weather: w)
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const Gap(20),

                  // ── Group actions ────────────────────────────────────
                  _GroupActionsRow(),
                  const Gap(20),

                  // ── My Groups ────────────────────────────────────────
                  _GroupInvitesBanner(),

                  // ── Trips header ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Trips', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/trips'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const Gap(4),
                ],
              ),
            ),
          ),

          // ── Trip list ──────────────────────────────────────────────────
          trips.when(
            data: (tripList) => tripList.isEmpty
                ? SliverToBoxAdapter(child: _EmptyTrips())
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TripCard(trip: tripList[i]),
                        ),
                        childCount: tripList.length,
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, s) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),

          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }
}

// ── Group Actions Row ─────────────────────────────────────────────────────────

class _GroupActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final trips = ref.watch(tripsProvider).value ?? [];

    return Row(
      children: [
        // Create Group
        Expanded(
          child: _ActionCard(
            icon: Icons.group_add_rounded,
            label: 'Create Group',
            subtitle: 'Start a shared trip',
            color: cs.primary,
            onTap: () => _showCreateGroupSheet(context, ref, trips),
          ),
        ),
        const Gap(12),
        // Join Group
        Expanded(
          child: _ActionCard(
            icon: Icons.login_rounded,
            label: 'Join Group',
            subtitle: 'Enter invite code',
            color: cs.secondary,
            onTap: () => _showJoinGroupSheet(context, ref),
          ),
        ),
      ],
    );
  }

  void _showCreateGroupSheet(
      BuildContext context, WidgetRef ref, List<Trip> trips) {
    String? selectedTripId;
    String? selectedTripTitle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 24, right: 24, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.group_add_rounded, color: cs.primary),
                  const Gap(10),
                  Text('Create Group Trip',
                      style: theme.textTheme.titleLarge),
                ]),
                const Gap(6),
                Text(
                  'Link a trip and share the invite code with companions. All data syncs via Firebase.',
                  style: theme.textTheme.bodySmall,
                ),
                const Gap(20),
                if (trips.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: cs.primary, size: 18),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Create a trip first from the Trips tab.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Trip',
                      prefixIcon: Icon(Icons.luggage_rounded),
                    ),
                    items: trips
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.title,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedTripId = v;
                          selectedTripTitle =
                              trips.firstWhere((t) => t.id == v).title;
                        });
                      }
                    },
                  ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Create & Save to Firebase'),
                    onPressed: (selectedTripId == null || trips.isEmpty)
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            try {
                              final group = await ref
                                  .read(groupActionProvider.notifier)
                                  .createGroup(
                                    tripId: selectedTripId!,
                                    tripTitle: selectedTripTitle!,
                                  );
                              if (context.mounted) {
                                _showCodeDialog(context, group.inviteCode);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showJoinGroupSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    String? error;
    bool joining = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 24, right: 24, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.login_rounded, color: cs.primary),
                  const Gap(10),
                  Text('Join a Group', style: theme.textTheme.titleLarge),
                ]),
                const Gap(6),
                Text(
                  'Enter the 6-digit code from your trip organizer.',
                  style: theme.textTheme.bodySmall,
                ),
                const Gap(20),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 7,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '000-000',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.3),
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    errorText: error,
                  ),
                  onChanged: (v) {
                    final digits = v.replaceAll('-', '');
                    if (digits.length == 3 && !v.contains('-')) {
                      ctrl.value = TextEditingValue(
                        text: '$digits-',
                        selection: TextSelection.collapsed(
                            offset: digits.length + 1),
                      );
                    }
                  },
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: joining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.group_rounded),
                    label: Text(joining ? 'Joining...' : 'Join Group'),
                    onPressed: joining
                        ? null
                        : () async {
                            final code = ctrl.text.trim();
                            final digits = code.replaceAll('-', '');
                            if (digits.length != 6) {
                              setState(() =>
                                  error = 'Enter a valid 6-digit code');
                              return;
                            }
                            setState(() {
                              joining = true;
                              error = null;
                            });
                            try {
                              await ref
                                  .read(groupActionProvider.notifier)
                                  .joinGroup(code);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Joined group successfully!')),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                joining = false;
                                error =
                                    'Group not found. Check the code and try again.';
                              });
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCodeDialog(BuildContext context, String code) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Group Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code with your travel companions:',
                style: theme.textTheme.bodyMedium),
            const Gap(16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ),
            const Gap(12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied!')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done')),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(10),
            Text(label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Gap(2),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

// ── Group Invites Banner ──────────────────────────────────────────────────────

class _GroupInvitesBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Groups', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.push('/group'),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const Gap(8),
            ...groups.map((g) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.group_rounded,
                            color: cs.primary, size: 22),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code: ${g.inviteCode}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${g.members.length} member${g.members.length == 1 ? '' : 's'} · Firebase synced',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Group Tasks',
                        icon: Icon(Icons.check_circle_outline_rounded,
                            color: cs.primary),
                        onPressed: () =>
                            context.push('/group/${g.id}/todos'),
                      ),
                      IconButton(
                        tooltip: 'Group Containers',
                        icon: Icon(Icons.inventory_2_rounded,
                            color: cs.primary),
                        onPressed: () =>
                            context.push('/group/${g.id}/containers'),
                      ),
                    ],
                  ),
                )),
            const Gap(12),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

// ── Weather Card ──────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  final WeatherData weather;
  const _WeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Location',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70)),
              const Gap(4),
              Text(weather.cityName,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white)),
              const Gap(8),
              Row(
                children: [
                  Text(weather.icon,
                      style: const TextStyle(fontSize: 24)),
                  const Gap(8),
                  Text(
                    '${weather.tempCelsius.round()}°C',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const Gap(8),
                  Text(weather.condition,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends ConsumerWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  String _weatherIcon(String? condition) {
    if (condition == null) return '🌡️';
    final c = condition.toLowerCase();
    if (c.contains('clear') || c.contains('sunny')) return '☀️';
    if (c.contains('cloud') || c.contains('partly')) return '⛅';
    if (c.contains('fog')) return '🌫️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    return '🌡️';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isGroup = trip.type == TripType.group;
    final dateStr = trip.startDate != null
        ? DateFormat('MMM d').format(trip.startDate!) +
            (trip.endDate != null
                ? ' – ${DateFormat('MMM d, yyyy').format(trip.endDate!)}'
                : '')
        : 'No date set';

    return GestureDetector(
      onTap: () => context.push('/trips/${trip.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGroup
                        ? cs.tertiary.withValues(alpha: 0.2)
                        : cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isGroup ? 'GROUP' : 'INDIVIDUAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isGroup ? cs.tertiary : cs.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4)),
              ],
            ),
            const Gap(8),
            Text(trip.title, style: theme.textTheme.titleLarge),
            const Gap(4),
            Text(
              trip.locations.isNotEmpty
                  ? trip.locations.map((l) => l.name).join(' → ')
                  : 'No locations',
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Weather row — show temp for first location if available
            if (trip.locations.isNotEmpty &&
                trip.locations.first.tempCelsius != null) ...[
              const Gap(4),
              Row(
                children: [
                  Text(
                    _weatherIcon(trip.locations.first.weatherCondition),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Gap(4),
                  Text(
                    '${trip.locations.first.tempCelsius!.round()}°C',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    trip.locations.first.weatherCondition ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
            const Gap(4),
            Text(dateStr, style: theme.textTheme.bodySmall),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.0,
                      backgroundColor: cs.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const Gap(12),
                Text('ITEMS READY',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Trips ───────────────────────────────────────────────────────────────

class _EmptyTrips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.luggage_rounded,
              size: 64, color: cs.primary.withValues(alpha: 0.4)),
          const Gap(16),
          Text('No trips yet', style: theme.textTheme.titleLarge),
          const Gap(8),
          Text('Go to Trips tab to create your first trip',
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
