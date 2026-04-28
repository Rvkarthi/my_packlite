import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

// Global key so any screen can open the shell drawer
final scaffoldKey = GlobalKey<ScaffoldState>();

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/trips')) return 1;
    if (location.startsWith('/todo')) return 2;
    if (location.startsWith('/containers')) return 3;
    if (location.startsWith('/chat')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      key: scaffoldKey,
      drawer: const _AppDrawer(),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1C1E21)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GNav(
              gap: 8,
              activeColor: Colors.white,
              iconSize: 22,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: cs.primary,
              color: cs.onSurface.withValues(alpha: 0.5),
              selectedIndex: _locationToIndex(location),
              onTabChange: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/trips');
                    break;
                  case 2:
                    context.go('/todo');
                    break;
                  case 3:
                    context.go('/containers');
                    break;
                  case 4:
                    context.go('/chat');
                    break;
                }
              },
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.luggage_rounded, text: 'Trips'),
                GButton(
                    icon: Icons.check_circle_outline_rounded, text: 'Tasks'),
                GButton(icon: Icons.inventory_2_rounded, text: 'Containers'),
                GButton(icon: Icons.auto_awesome_rounded, text: 'AI Chat'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.mode == ThemeMode.dark;

    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.value;
    final displayName = user?.displayName ?? 'Traveler';
    final email = user?.email ?? '';

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── User header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: cs.primary,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        if (email.isNotEmpty)
                          Text(email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.6)),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.group_rounded,
                    label: 'Group Packing',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/group');
                    },
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // ── Settings label ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(
                          'APPEARANCE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Dark / Light toggle ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          key: ValueKey(isDark),
                          color: cs.primary,
                        ),
                      ),
                      title: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        isDark ? 'Tap to switch to light' : 'Tap to switch to dark',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) =>
                            ref.read(themeProvider.notifier).toggle(),
                        activeThumbColor: cs.primary,
                        activeTrackColor: cs.primary.withValues(alpha: 0.3),
                      ),
                      onTap: () => ref.read(themeProvider.notifier).toggle(),
                    ),
                  ),
                  // ── Color scheme picker ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_rounded,
                                size: 16,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Text(
                              'THEME COLOR',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(
                            appColorSchemes.length,
                            (i) {
                              final scheme = appColorSchemes[i];
                              final isSelected =
                                  themeState.colorIndex == i;
                              return GestureDetector(
                                onTap: () => ref
                                    .read(themeProvider.notifier)
                                    .setColorIndex(i),
                                child: Tooltip(
                                  message: scheme.name,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          scheme.primary,
                                          scheme.secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: isSelected
                                          ? Border.all(
                                              color: cs.onSurface,
                                              width: 2.5,
                                            )
                                          : Border.all(
                                              color: Colors.transparent,
                                              width: 2.5,
                                            ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: scheme.primary
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 18)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appColorSchemes[themeState.colorIndex].name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'All Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                ],
              ),
            ),
            // ── Footer ───────────────────────────────────────────────────
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              iconColor: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 4),
            Text('PackLite v1.0.0', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon,
            color: iconColor ?? theme.colorScheme.primary),
        title: Text(label, style: theme.textTheme.titleMedium),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
