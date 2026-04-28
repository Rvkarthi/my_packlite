import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/group_trip.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/group_provider.dart';
import '../../../presentation/providers/trip_provider.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGroups = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Group Packing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Create group ─────────────────────────────────────────────
            _CreateGroupCard(),
            const Gap(20),
            // ── Join group ───────────────────────────────────────────────
            _JoinGroupCard(),
            const Gap(24),
            // ── My groups ────────────────────────────────────────────────
            Text('My Groups', style: theme.textTheme.titleLarge),
            const Gap(12),
            myGroups.when(
              data: (groups) => groups.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.group_outlined,
                                size: 48,
                                color: cs.primary.withValues(alpha: 0.3)),
                            const Gap(12),
                            Text('No groups yet',
                                style: theme.textTheme.titleMedium),
                            const Gap(4),
                            Text('Create or join a group above',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: groups
                          .map((g) => _GroupCard(group: g))
                          .toList(),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Group Card ─────────────────────────────────────────────────────────

class _CreateGroupCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final trips = ref.watch(tripsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.group_add_rounded, color: cs.primary),
            const Gap(8),
            Text('Create a Group', style: theme.textTheme.titleLarge),
          ]),
          const Gap(8),
          Text(
            'Link a trip to a group and share the invite code with companions.',
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context, ref, trips.value ?? []),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Group'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, WidgetRef ref, List trips) {
    String? selectedTripId;
    String? selectedTripTitle;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Group Trip', style: theme.textTheme.titleLarge),
                const Gap(16),
                if (trips.isEmpty)
                  Text('Create a trip first to link it to a group.',
                      style: theme.textTheme.bodyMedium)
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Trip',
                      prefixIcon: Icon(Icons.luggage_rounded),
                    ),
                    items: trips
                        .map((t) => DropdownMenuItem<String>(
                              value: t.id as String,
                              child: Text(t.title as String),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedTripId = v;
                          selectedTripTitle = (trips.firstWhere(
                                  (t) => t.id == v))
                              .title as String;
                        });
                      }
                    },
                  ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedTripId == null
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
                                _showInviteCode(context, group.inviteCode);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    child: const Text('Create Group'),
                  ),
                ),
                const Gap(20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInviteCode(BuildContext context, String code) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── Join Group Card ───────────────────────────────────────────────────────────

class _JoinGroupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.login_rounded, color: cs.primary),
            const Gap(8),
            Text('Join a Group', style: theme.textTheme.titleLarge),
          ]),
          const Gap(8),
          Text(
            'Enter a 6-digit code to join your group\'s packing list.',
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/group/join'),
              icon: const Icon(Icons.keyboard_rounded),
              label: const Text('Enter Invite Code'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────

class _GroupCard extends ConsumerWidget {
  final GroupTrip group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.value?.uid;
    final isOrganizer = group.organizerId == uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
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
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOrganizer ? 'ORGANIZER' : 'MEMBER',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.primary),
                ),
              ),
              const Spacer(),
              if (isOrganizer)
                GestureDetector(
                  onTap: () => _showCode(context, group.inviteCode),
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded,
                          size: 16, color: cs.primary),
                      const Gap(4),
                      Text('Share Code',
                          style: TextStyle(
                              color: cs.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(10),
          Text('Code: ${group.inviteCode}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Gap(4),
          Text('${group.members.length} member${group.members.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall),
          const Gap(12),
          // Members avatars
          Wrap(
            spacing: 8,
            children: group.members.map((m) {
              final color = Color(
                  int.parse(m.avatarColor.replaceFirst('#', '0xFF')));
              return Tooltip(
                message: m.name,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/group/${group.id}/todos'),
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 16),
                  label: const Text('Group Tasks'),
                ),
              ),
              const Gap(8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/group/${group.id}/containers'),
                  icon: const Icon(Icons.inventory_2_rounded, size: 16),
                  label: const Text('Containers'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code $code copied!')),
    );
  }
}
