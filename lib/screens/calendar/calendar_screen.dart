import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/goal_model.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddEventDialog(BuildContext context, GoalSaverController controller, DateTime date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    _titleController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text('Add Event', style: AppText.titleMedium.copyWith(color: textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${date.day}/${date.month}/${date.year}', style: AppText.caption.copyWith(color: AppColors.lime)),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: goalInputDecoration('Event Title', Icons.event_rounded, context: context),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                style: TextStyle(color: textColor),
                decoration: goalInputDecoration('Notes (optional)', Icons.notes_rounded, context: context),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.muted))),
          FilledButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              controller.addCalendarEvent(CalendarEvent(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                title: title,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                date: date,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Event "$title" added!'), backgroundColor: AppColors.lime, behavior: SnackBarBehavior.floating),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.lime),
            child: Text('Add Event', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, GoalSaverController controller, CalendarEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final bgColor = isDark ? AppColors.panel : Colors.white;
    _titleController.text = event.title;
    _notesController.text = event.notes ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: Text('Edit Event', style: AppText.titleMedium.copyWith(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: textColor),
              decoration: goalInputDecoration('Event Title', Icons.event_rounded, context: context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              style: TextStyle(color: textColor),
              decoration: goalInputDecoration('Notes', Icons.notes_rounded, context: context),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () {
              controller.deleteCalendarEvent(event);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Event deleted!'), backgroundColor: AppColors.error.withValues(alpha: 0.8), behavior: SnackBarBehavior.floating),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
          FilledButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              controller.updateCalendarEvent(event.copyWith(
                title: title,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Event updated!'), backgroundColor: AppColors.lime, behavior: SnackBarBehavior.floating),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.lime),
            child: Text('Save', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Consumer<GoalSaverController>(
              builder: (context, controller, _) {
                final goals = controller.goals;
                final selectedDate = _selectedDay ?? _focusedDay;
                final customEvents = controller.getEventsForDate(selectedDate);
                final goalDueDates = goals.where((g) =>
                  g.dueDate != null &&
                  g.dueDate!.day == selectedDate.day &&
                  g.dueDate!.month == selectedDate.month &&
                  g.dueDate!.year == selectedDate.year
                ).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(metrics.pagePadding, 18, metrics.pagePadding, 24),
                      sliver: SliverList.list(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Calendar', style: AppText.caption.copyWith(color: AppColors.lime, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Your Schedule', style: AppText.titleLarge),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, color: AppColors.lime),
                                tooltip: 'Add Event',
                                onPressed: () => _showAddEventDialog(context, controller, selectedDate),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              eventLoader: (day) {
                                final events = controller.getEventsForDate(day);
                                final dueGoals = goals.where((g) =>
                                  g.dueDate != null &&
                                  g.dueDate!.day == day.day &&
                                  g.dueDate!.month == day.month &&
                                  g.dueDate!.year == day.year
                                );
                                return [...events, ...dueGoals];
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(color: AppColors.lime.withValues(alpha: 0.3), shape: BoxShape.circle),
                                selectedDecoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                                markerDecoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                                outsideDaysVisible: false,
                              ),
                              headerStyle: HeaderStyle(
                                titleTextStyle: AppText.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                                formatButtonTextStyle: AppText.caption.copyWith(color: AppColors.lime),
                                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.lime),
                                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.lime),
                              ),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              onFormatChanged: (format) => setState(() => _calendarFormat = format),
                              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedDay != null) ...[
                            Row(
                              children: [
                                Text('${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}', style: AppText.titleMedium),
                                const Spacer(),
                                Text('${customEvents.length} event${customEvents.length != 1 ? "s" : ""}', style: AppText.caption.copyWith(color: AppColors.lime)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (customEvents.isEmpty && goalDueDates.isEmpty)
                              GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.event_busy_rounded, color: AppColors.muted, size: 36),
                                        const SizedBox(height: 8),
                                        Text('No events on this day', style: AppText.body.copyWith(color: AppColors.muted)),
                                        const SizedBox(height: 12),
                                        TextButton.icon(
                                          onPressed: () => _showAddEventDialog(context, controller, _selectedDay!),
                                          icon: const Icon(Icons.add_rounded, color: AppColors.lime),
                                          label: const Text('Add Event', style: TextStyle(color: AppColors.lime)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              ...customEvents.map((event) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  onTap: () => _showEditEventDialog(context, controller, event),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(width: 36, height: 36, decoration: BoxDecoration(color: event.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(event.icon, color: event.color, size: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(event.title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                            if (event.notes != null && event.notes!.isNotEmpty)
                                              Text(event.notes!, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      if (event.formattedTime.isNotEmpty)
                                        Text(event.formattedTime, style: AppText.caption.copyWith(color: AppColors.lime)),
                                      const SizedBox(width: 8),
                                      Pressable(
                                        onTap: () {
                                          controller.deleteCalendarEvent(event);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Event deleted!"), backgroundColor: AppColors.error.withValues(alpha: 0.8), behavior: SnackBarBehavior.floating));
                                        },
                                        child: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                              if (goalDueDates.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text("Goal Deadlines", style: AppText.caption.copyWith(color: AppColors.lime)),
                                const SizedBox(height: 8),
                                ...goalDueDates.map((goal) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(width: 36, height: 36, decoration: BoxDecoration(color: goal.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(goal.icon, color: goal.color, size: 18)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Due: ${goal.title}", style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                              Text(
                                                controller.showBalance
                                                    ? '${controller.formatMoney(goal.saved)} / ${controller.formatMoney(goal.target)}'
                                                    : '${controller.currencySymbol} \u2022\u2022\u2022 / \u2022\u2022\u2022',
                                                style: AppText.caption.copyWith(color: goal.color),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (goal.completed)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: Icon(Icons.check_circle_rounded, color: const Color(0xFF00E676), size: 16),
                                              ),
                                            Text(
                                              goal.completed ? 'Done' : goal.progressPercent,
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: goal.completed ? const Color(0xFF00E676) : goal.color),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                              ],
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
