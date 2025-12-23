import 'package:flutter/material.dart';

/// Common UI helper widgets for consistent styling and preventing text overflow
class UIHelpers {
  /// Wraps content with proper padding and scroll if needed
  static Widget safeScrollWrapper({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16.0),
  }) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(children: children),
    );
  }

  /// ListTile with proper text wrapping and no overflow
  static Widget customListTile({
    required BuildContext context,
    IconData? leading,
    Color? leadingColor,
    required String title,
    String? subtitle,
    IconData? trailingIcon,
    VoidCallback? onTap,
    VoidCallback? onTrailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  Icon(leading, color: leadingColor, size: 24),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onTrailing,
                    icon: Icon(trailingIcon),
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: const EdgeInsets.all(0),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card with proper constraints and padding
  static Widget safeCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 16,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  /// Full width button wrapper
  static Widget fullWidthButton({required Widget child}) {
    return SizedBox(width: double.infinity, child: child);
  }

  /// Creates a standard page body with proper constraints
  static Widget pageBody({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return SingleChildScrollView(
      child: Padding(padding: padding, child: Column(children: children)),
    );
  }

  /// Creates a constrained input field with label
  static Widget constrainedTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText, hintText: hintText),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
