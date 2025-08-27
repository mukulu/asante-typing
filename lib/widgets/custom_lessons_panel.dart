import 'package:asante_typing/services/custom_lessons_service.dart';
import 'package:flutter/material.dart';

/// A panel that displays a list of custom lessons with controls to add,
/// edit, delete and bulk upload lessons. When a lesson is tapped its
/// contents are selected for typing practice. Each chip has a small
/// overflow menu for editing or deleting the corresponding lesson.
///
/// This widget is intended to be used for the special "Custom lessons"
/// unit appended to the built‑in units. It remains agnostic about data
/// persistence; callers are responsible for saving and loading the lesson
/// list. See also [CustomLessonsService].
class CustomLessonsPanel extends StatelessWidget {
  /// Creates a [CustomLessonsPanel].
  const CustomLessonsPanel({
    required this.lessons, 
    required this.selectedTitle, 
    required this.accent, 
    required this.onSelect, 
    required this.onAdd, 
    required this.onEdit, 
    required this.onDelete, 
    required this.onBulkUpload,
    required this.onResetAll,
    super.key,
  });

  /// The list of lessons to display. Each item is a map containing
  /// a `title` and `content` entry. Order defines display order.
  final List<Map<String, String>> lessons;

  /// The title of the currently selected custom lesson, or `null` if none
  /// are selected.
  final String? selectedTitle;

  /// Accent colour to apply to selected chips.
  final Color accent;

  /// Called when a lesson is tapped. The argument is the lesson title.
  final void Function(String title) onSelect;

  /// Called when the user requests to add a new lesson.
  final VoidCallback onAdd;

  /// Called when the user requests to edit the lesson at the given index.
  final void Function(int index) onEdit;

  /// Called when the user requests to delete the lesson at the given index.
  final void Function(int index) onDelete;

  /// Called when the user requests to bulk upload lessons.
  final VoidCallback onBulkUpload;
  
  final VoidCallback onResetAll; 

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NEW: Always-visible tip about two-column CSV support for bulk upload.
        _csvSupportHint(),

        const SizedBox(height: 8),

        // Existing chips + buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < lessons.length; i++)
              _buildLessonChip(context, i),
            _buildAddButton(),
            _buildBulkUploadButton(),
            _buildResetButton(),
          ],
        ),
      ],
    );
  }

  // NEW: small banner to inform users about CSV format.
  Widget _csvSupportHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12), // subtle hint tint
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Tip: Bulk upload supports a two-column CSV for "Title","Passage". Each new line becomes a separate lesson.',
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  /// Builds a chip for the lesson at the given [index]. Each chip shows
  /// the lesson title and a small overflow menu. When tapped the lesson
  /// becomes selected.
  Widget _buildLessonChip(BuildContext context, int index) {
    final lesson = lessons[index];
    final isSelected = selectedTitle != null && selectedTitle == lesson['title'];
    final bgColor = isSelected ? accent.withValues(alpha: 0.12) : Colors.grey.shade200;
    final textColor = isSelected ? accent : Colors.black;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onSelect(lesson['title'] ?? ''),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lesson['title'] ?? '',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Options',
                icon: Icon(Icons.more_vert, size: 16, color: textColor),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit(index);
                    case 'delete':
                      onDelete(index);
                    default:
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the button that triggers the add lesson dialog.
  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: const Text('Add lesson'),
    );
  }

  /// Builds the button that triggers the bulk upload dialog.
  Widget _buildBulkUploadButton() {
    return Tooltip(
      message: 'Also supports two-column CSV: "Title","Passage".',
      child: ElevatedButton.icon(
        onPressed: onBulkUpload,
        icon: const Icon(Icons.file_upload),
        label: const Text('Bulk upload'),
      ),
    );
  }

  // NEW: big red â€œreset allâ€ button, disabled when list is empty
  Widget _buildResetButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
      ),
      onPressed: lessons.isEmpty ? null : onResetAll,
      icon: const Icon(Icons.delete_sweep),
      label: const Text('Reset all'),
    );
  }

}
