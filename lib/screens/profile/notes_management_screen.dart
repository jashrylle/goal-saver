import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../utils/timestamp_formatter.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

/// Full-screen dialog for managing all user notes without expanding the profile page.
/// Displays creation and last-edited timestamps in 12-hour AM/PM format.
class NotesManagementScreen extends StatefulWidget {
  const NotesManagementScreen({super.key});

  @override
  State<NotesManagementScreen> createState() => _NotesManagementScreenState();
}

class _NotesManagementScreenState extends State<NotesManagementScreen> {
  final TextEditingController _newNoteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _addNote(GoalSaverController controller) async {
    final content = _newNoteController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await controller.addNote(content);
      if (mounted) {
        _newNoteController.clear();
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note added!'),
            backgroundColor: controller.accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteNote(String id, GoalSaverController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.panel : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
    if (confirm == true && mounted) {
      await controller.deleteNote(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note deleted!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _editNote(String id, String currentContent, GoalSaverController controller) async {
    final editController = TextEditingController(text: currentContent);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = controller.accentColor;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.panel : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Note'),
        content: TextField(
          controller: editController,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit your note...',
            filled: true,
            fillColor: isDark ? AppColors.muted.withValues(alpha: 0.08) : AppColors.lightMuted.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.muted.withValues(alpha: 0.2) : AppColors.lightMuted.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            child: Text('Save', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
    editController.dispose();
    if (result != null && result.isNotEmpty && mounted) {
      await controller.updateNote(id, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note updated!'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// Format a note's timestamp showing creation time and last edited time.
  Widget _buildTimestamp(Map<String, dynamic> note, Color mutedColor, Color accentColor) {
    final createdAt = TimestampFormatter.parseStored(note['createdAt'] as String?);
    final updatedAt = TimestampFormatter.parseStored(note['updatedAt'] as String?);

    if (createdAt == null) return const SizedBox.shrink();

    final isEdited = updatedAt != null && updatedAt.difference(createdAt).inSeconds > 5;

    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 12, color: mutedColor),
        const SizedBox(width: 4),
        Text(
          TimestampFormatter.relative(createdAt),
          style: TextStyle(fontSize: 11, color: mutedColor),
        ),
        if (isEdited) ...[
          const SizedBox(width: 8),
          Icon(Icons.edit_note_rounded, size: 12, color: accentColor.withValues(alpha: 0.6)),
          const SizedBox(width: 2),
          Text(
            'Edited ${TimestampFormatter.timeOnly(updatedAt)}',
            style: TextStyle(fontSize: 10, color: accentColor.withValues(alpha: 0.6)),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Consumer<GoalSaverController>(
              builder: (context, controller, _) {
                final notes = controller.savedNotes;
                final accentColor = controller.accentColor;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.pagePadding, 18, metrics.pagePadding, 48,
                      ),
                      sliver: SliverList.list(
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.arrow_back_rounded, color: accentColor),
                              ),
                              const Expanded(
                                child: DashboardHeader(
                                  eyebrow: 'Profile',
                                  title: 'Manage Notes',
                                ),
                              ),
                              if (notes.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${notes.length}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Add new note input
                          GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.note_add_rounded, color: accentColor, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'New Note',
                                      style: AppText.body.copyWith(color: textColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _newNoteController,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  maxLines: 3,
                                  minLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Write your note here...',
                                    hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDark ? AppColors.muted.withValues(alpha: 0.2) : AppColors.lightMuted.withValues(alpha: 0.3)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDark ? AppColors.muted.withValues(alpha: 0.2) : AppColors.lightMuted.withValues(alpha: 0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: accentColor, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? AppColors.muted.withValues(alpha: 0.08) : AppColors.lightMuted.withValues(alpha: 0.08),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: _isSaving ? null : () => _addNote(controller),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: AppColors.ink,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_rounded, size: 18),
                                              SizedBox(width: 6),
                                              Text('Add Note', style: TextStyle(fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Notes header
                          Row(
                            children: [
                              Icon(Icons.note_alt_rounded, color: accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text('All Notes', style: AppText.titleMedium.copyWith(color: textColor)),
                              const Spacer(),
                              if (notes.isNotEmpty)
                                Text('${notes.length} total', style: TextStyle(fontSize: 12, color: mutedColor)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Notes list
                          if (notes.isEmpty)
                            EmptyState(
                              icon: Icons.note_add_rounded,
                              title: 'No notes yet',
                              subtitle: 'Write your first note above to track reminders and ideas',
                            )
                          else
                            ...notes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final note = entry.value;
                              final id = note['id'] as String;
                              final content = note['content'] as String;

                              return Padding(
                                padding: EdgeInsets.only(bottom: index < notes.length - 1 ? 10 : 0),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              content,
                                              style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            children: [
                                              Pressable(
                                                onTap: () => _editNote(id, content, controller),
                                                child: Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: accentColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(Icons.edit_rounded, size: 15, color: accentColor),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Pressable(
                                                onTap: () => _deleteNote(id, controller),
                                                child: Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Timestamp with 12-hour AM/PM format
                                      _buildTimestamp(note, mutedColor, accentColor),
                                    ],
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 40),
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
