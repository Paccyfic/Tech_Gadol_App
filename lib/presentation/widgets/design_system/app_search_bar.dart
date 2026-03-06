import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search products...',
    this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: Icon(Icons.search_rounded, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: AnimatedSwitcher(
          duration: AppDuration.fast,
          child: _hasText
              ? GestureDetector(
                  key: const ValueKey('clear'),
                  onTap: _onClear,
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(Icons.cancel_rounded, size: 18),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}
