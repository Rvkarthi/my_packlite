import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeCtrl = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final raw = _codeCtrl.text.trim();
    final code = raw.replaceAll('-', '');
    if (code.length != 6) {
      setState(() => _error = 'Please enter a valid 6-digit code');
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await ref.read(groupActionProvider.notifier).joinGroup(raw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the group!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Group not found. Check the code and try again.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Invite Code', style: theme.textTheme.headlineSmall),
            const Gap(8),
            Text(
              'Ask your trip organizer for the 6-digit invite code.',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(32),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 7,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '000-000',
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 8,
                ),
                counterText: '',
                errorText: _error,
              ),
              onChanged: (v) {
                final digits = v.replaceAll('-', '');
                if (digits.length == 3 && !v.contains('-')) {
                  _codeCtrl.value = TextEditingValue(
                    text: '$digits-',
                    selection:
                        TextSelection.collapsed(offset: digits.length + 1),
                  );
                }
              },
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _joining ? null : _join,
                child: _joining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Join Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
