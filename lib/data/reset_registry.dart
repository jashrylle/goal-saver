/// Auto-registering system for reset actions.
library;

/// Every reset-able feature in Goal Saver registers a [ResetEntry] into
/// [ResetRegistry] at module initialization time. This means:
///
/// - **New features automatically participate in reset** without editing
///   `resetSelectedProgress` or `ResetFlags`.
/// - The `resetSelectedProgress` method iterates the registry and calls
///   each entry whose flag is selected.
///
/// ## How to add a new feature
///
/// 1. Add a `bool` property to [ResetFlags] (or reuse an existing one).
/// 2. Call `ResetRegistry.register(ResetEntry(...))` at the top of the
///    controller method that owns the data.
/// 3. The reset system will automatically discover and execute the new
///    entry whenever the corresponding flag is selected.
///
/// ## Example
///
/// ```dart
/// // In your feature's initializer:
/// ResetRegistry.register(ResetEntry(
///   name: 'My New Feature',
///   isSelected: (flags) => flags.myNewFeature,
///   execute: (ctrl) async {
///     ctrl.myData.clear();
///     await ctrl.myStorageWrite([]);
///   },
/// ));
/// ```
import '../models/savings_plan_model.dart' show ResetFlags;
import '../state/goal_saver_controller.dart';

class ResetRegistry {
  ResetRegistry._();
  static final List<ResetEntry> _entries = [];

  static void register(ResetEntry entry) {
    _entries.add(entry);
  }

  static List<ResetEntry> get entries => List.unmodifiable(_entries);

  /// Remove all entries (useful for testing or re-initialization).
  static void clear() => _entries.clear();
}

/// A single reset action that maps a [ResetFlags] field to a reset function.
///
/// [isSelected] is a function that checks whether the corresponding flag
/// is `true` on the [ResetFlags] instance.
///
/// [execute] is an async function that receives the controller and performs
/// the actual reset (clear memory, clear storage, recalculate dependents).
class ResetEntry {
  final String name;
  final bool Function(ResetFlags flags) isSelected;
  final Future<void> Function(GoalSaverController controller) execute;

  const ResetEntry({
    required this.name,
    required this.isSelected,
    required this.execute,
  });
}

// ── Forward reference to GoalSaverController ──────────────────────────────
//
// ResetEntry.execute receives the controller so it can access private fields.
// Import goal_saver_controller.dart when registering entries.
