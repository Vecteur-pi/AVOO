import 'package:flutter/material.dart';
import '../../../../theme/avoo_theme.dart';
import 'primary_sticky_button.dart';

class ScheduleDay {
  ScheduleDay(this.name, {this.isOpen = true, this.openTime = const TimeOfDay(hour: 9, minute: 0), this.closeTime = const TimeOfDay(hour: 22, minute: 0)});
  
  final String name;
  bool isOpen;
  TimeOfDay openTime;
  TimeOfDay closeTime;

  String get shortName => name.substring(0, 3);
}

class ScheduleBottomSheet extends StatefulWidget {
  const ScheduleBottomSheet({super.key, required this.initialScheduleText});

  final String initialScheduleText;

  static Future<String?> show(BuildContext context, String currentSchedule) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleBottomSheet(initialScheduleText: currentSchedule),
    );
  }

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  late List<ScheduleDay> _days;

  @override
  void initState() {
    super.initState();
    // Default smart configuration
    _days = [
      ScheduleDay('Lundi'),
      ScheduleDay('Mardi'),
      ScheduleDay('Mercredi'),
      ScheduleDay('Jeudi'),
      ScheduleDay('Vendredi'),
      ScheduleDay('Samedi', isOpen: false),
      ScheduleDay('Dimanche', isOpen: false),
    ];
  }

  Future<void> _pickTime(ScheduleDay day, bool isOpening) async {
    if (!day.isOpen) return;
    final initialTime = isOpening ? day.openTime : day.closeTime;
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AvooColors.green,
                onPrimary: Colors.white,
                onSurface: AvooColors.ink,
              ),
              timePickerTheme: TimePickerThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          day.openTime = picked;
        } else {
          day.closeTime = picked;
        }
        _autoSwapIfInvalid(day);
      });
    }
  }

  // Prevent invalid ranges
  void _autoSwapIfInvalid(ScheduleDay day) {
    if (!day.isOpen) return;
    final int startMins = day.openTime.hour * 60 + day.openTime.minute;
    final int endMins = day.closeTime.hour * 60 + day.closeTime.minute;
    if (startMins >= endMins) {
      final temp = day.openTime;
      day.openTime = day.closeTime;
      day.closeTime = temp;
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _generateSummary() {
    final openDays = _days.where((d) => d.isOpen).toList();
    if (openDays.isEmpty) return 'Fermé tous les jours';
    if (openDays.length == 7) return 'Ouvert tous les jours';

    final grouped = <String>[];
    for (final day in openDays) {
      grouped.add('${day.shortName}: ${_formatTime(day.openTime)}-${_formatTime(day.closeTime)}');
    }
    return grouped.join(', ');
  }

  // --- Quick Actions / Presets ---
  
  void _applyToAll() {
    final openDays = _days.where((d) => d.isOpen).toList();
    if (openDays.isEmpty) return;
    final reference = openDays.first;
    setState(() {
      for (final day in openDays) {
        day.openTime = reference.openTime;
        day.closeTime = reference.closeTime;
      }
    });
  }

  void _applyLunVenPreset() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        _days[i].isOpen = true;
        _days[i].openTime = const TimeOfDay(hour: 9, minute: 0);
        _days[i].closeTime = const TimeOfDay(hour: 22, minute: 0);
      }
    });
  }

  void _applyWeekendClosed() {
    setState(() {
      _days[5].isOpen = false;
      _days[6].isOpen = false;
    });
  }

  void _copyMondayToWeekdays() {
    if (!_days[0].isOpen) return;
    setState(() {
      for (int i = 1; i < 5; i++) {
        _days[i].isOpen = true;
        _days[i].openTime = _days[0].openTime;
        _days[i].closeTime = _days[0].closeTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AvooColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Horaires d'ouverture",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AvooColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _PresetChip(label: 'Appliquer à tous', icon: Icons.copy_all, onTap: _applyToAll),
                  const SizedBox(width: 8),
                  _PresetChip(label: 'Lun-Ven', icon: Icons.calendar_today, onTap: _applyLunVenPreset),
                  const SizedBox(width: 8),
                  _PresetChip(label: 'Week-end fermé', icon: Icons.weekend, onTap: _applyWeekendClosed),
                  const SizedBox(width: 8),
                  _PresetChip(label: 'Copier lundi', icon: Icons.copy, onTap: _copyMondayToWeekdays),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // List of grouped days
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _SectionCard(
                    title: 'Semaine',
                    days: _days.sublist(0, 5),
                    onToggle: (day, val) => setState(() => day.isOpen = val),
                    onPickTime: _pickTime,
                    formatTime: _formatTime,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Week-end',
                    days: _days.sublist(5, 7),
                    onToggle: (day, val) => setState(() => day.isOpen = val),
                    onPickTime: _pickTime,
                    formatTime: _formatTime,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Sticky CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AvooColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Vous pourrez les modifier plus tard dans vos paramètres.",
                    style: TextStyle(color: AvooColors.muted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  PrimaryStickyButton(
                    label: 'Valider',
                    onPressed: () {
                      Navigator.of(context).pop(_generateSummary());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AvooColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AvooColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AvooColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.days,
    required this.onToggle,
    required this.onPickTime,
    required this.formatTime,
  });

  final String title;
  final List<ScheduleDay> days;
  final void Function(ScheduleDay, bool) onToggle;
  final void Function(ScheduleDay, bool) onPickTime;
  final String Function(TimeOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AvooColors.muted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AvooColors.line),
          ),
          child: Column(
            children: days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              return Column(
                children: [
                  _DayRow(
                    day: day,
                    onToggle: onToggle,
                    onPickTime: onPickTime,
                    formatTime: formatTime,
                  ),
                  if (index < days.length - 1)
                    const Divider(height: 1, indent: 16, color: AvooColors.line),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.onToggle,
    required this.onPickTime,
    required this.formatTime,
  });

  final ScheduleDay day;
  final void Function(ScheduleDay, bool) onToggle;
  final void Function(ScheduleDay, bool) onPickTime;
  final String Function(TimeOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: day.isOpen ? AvooColors.ink : AvooColors.muted,
              ),
            ),
          ),
          Switch(
            value: day.isOpen,
            activeColor: AvooColors.green,
            onChanged: (val) => onToggle(day, val),
          ),
          const Spacer(),
          if (day.isOpen) ...[
            _TimeChip(
              time: formatTime(day.openTime),
              onTap: () => onPickTime(day, true),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('à', style: TextStyle(color: AvooColors.muted, fontSize: 13)),
            ),
            _TimeChip(
              time: formatTime(day.closeTime),
              onTap: () => onPickTime(day, false),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AvooColors.line.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Fermé',
                style: TextStyle(
                  color: AvooColors.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.onTap});

  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AvooColors.line),
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AvooColors.ink,
          ),
        ),
      ),
    );
  }
}
