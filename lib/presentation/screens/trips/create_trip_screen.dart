import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/trip.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../core/di/providers.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  final Trip? existingTrip;
  const CreateTripScreen({super.key, this.existingTrip});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  TripType _type = TripType.individual;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<TripLocation> _locations = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTrip != null) {
      final t = widget.existingTrip!;
      _titleCtrl.text = t.title;
      _type = t.type;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _locations.addAll(t.locations);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _addLocation() async {
    final name = _locationCtrl.text.trim();
    if (name.isEmpty) return;
    // Add immediately with no weather data
    setState(() {
      _locations.add(TripLocation(name: name));
      _locationCtrl.clear();
    });
    // Fetch weather in background and update the location
    final weather =
        await ref.read(weatherServiceProvider).getWeatherForLocation(name);
    if (weather != null && mounted) {
      setState(() {
        final idx = _locations.indexWhere((l) => l.name == name);
        if (idx != -1) {
          _locations[idx] = _locations[idx].copyWith(
            tempCelsius: weather.tempCelsius,
            weatherCondition: weather.condition,
          );
        }
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final trip = await ref.read(tripsProvider.notifier).createTrip(
            title: _titleCtrl.text.trim(),
            locations: _locations,
            startDate: _startDate,
            endDate: _endDate,
            type: _type,
          );
      if (mounted) context.pushReplacement('/trips/${trip.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrip == null ? 'New Trip' : 'Edit Trip'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g. Scandinavian Summer',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(20),
            Text('Trip Type', style: theme.textTheme.titleMedium),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Individual',
                    icon: Icons.person_rounded,
                    selected: _type == TripType.individual,
                    onTap: () => setState(() => _type = TripType.individual),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _TypeButton(
                    label: 'Group',
                    icon: Icons.group_rounded,
                    selected: _type == TripType.group,
                    onTap: () => setState(() => _type = TripType.group),
                  ),
                ),
              ],
            ),
            const Gap(20),
            Text('Dates', style: theme.textTheme.titleMedium),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Start Date',
                    date: _startDate != null ? fmt.format(_startDate!) : null,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _DateButton(
                    label: 'End Date',
                    date: _endDate != null ? fmt.format(_endDate!) : null,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const Gap(20),
            Text('Locations', style: theme.textTheme.titleMedium),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a city or location',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    onFieldSubmitted: (_) => _addLocation(),
                  ),
                ),
                const Gap(8),
                IconButton.filled(
                  onPressed: _addLocation,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const Gap(12),
            if (_locations.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _locations.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _locations.removeAt(oldIndex);
                    _locations.insert(newIndex, item);
                  });
                },
                itemBuilder: (ctx, i) => ListTile(
                  key: Key('loc_$i'),
                  leading: CircleAvatar(
                    backgroundColor: cs.primary,
                    radius: 14,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(_locations[i].name),
                  subtitle: _locations[i].tempCelsius != null
                      ? Text(
                          '${_locations[i].tempCelsius!.round()}°C · ${_locations[i].weatherCondition}',
                          style: TextStyle(
                              color: cs.primary, fontSize: 12),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20),
                        onPressed: () =>
                            setState(() => _locations.removeAt(i)),
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                ),
              ),
            const Gap(32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(
                  widget.existingTrip == null ? 'Create Trip' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : cs.onSurface),
            const Gap(4),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String? date;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, this.date, required this.onTap});

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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const Gap(4),
            Text(
              date ?? 'Select date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: date != null ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

