import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/accidental_selection_binder.dart';
import '../../core/theme/app_text_styles.dart';

/// Optional heading + options for grouped searchable pickers.
class SearchableOptionSection {
  const SearchableOptionSection({
    required this.title,
    required this.options,
  });

  final String title;
  final List<String> options;
}

/// Dropdown-style field that opens a searchable picker sheet.
class SearchableFilterDropdown extends StatelessWidget {
  const SearchableFilterDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.allLabel = 'All',
    this.searchHint = 'Search...',
    this.sections,
    this.matchOption,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String allLabel;
  final String searchHint;
  final List<SearchableOptionSection>? sections;
  final bool Function(String option, String query)? matchOption;

  String get _displayValue => value ?? allLabel;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SearchablePickerSheet(
        title: label,
        options: options,
        selected: value,
        allLabel: allLabel,
        searchHint: searchHint,
        sections: sections,
        matchOption: matchOption,
      ),
    );

    if (!context.mounted || selected == null) return;
    onChanged(selected.isEmpty ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        ),
        child: Text(
          _displayValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: value == null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SearchablePickerSheet extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.allLabel,
    required this.searchHint,
    this.sections,
    this.matchOption,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final String allLabel;
  final String searchHint;
  final List<SearchableOptionSection>? sections;
  final bool Function(String option, String query)? matchOption;

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String option) {
    if (_query.isEmpty) return true;
    if (widget.matchOption != null) {
      return widget.matchOption!(option, _query);
    }
    return option.toLowerCase().contains(_query);
  }

  List<String> get _allOptions {
    final sections = widget.sections;
    if (sections != null && sections.isNotEmpty) {
      return [
        for (final section in sections) ...section.options,
      ];
    }
    return widget.options;
  }

  List<String> get _filteredOptions {
    if (_query.isEmpty) return _allOptions;
    return _allOptions.where(_matches).toList();
  }

  List<SearchableOptionSection> get _visibleSections {
    final sections = widget.sections;
    if (sections == null || sections.isEmpty) return const [];
    if (_query.isEmpty) {
      return [
        for (final section in sections)
          if (section.options.isNotEmpty) section,
      ];
    }
    return [
      for (final section in sections)
        if (section.options.any(_matches))
          SearchableOptionSection(
            title: section.title,
            options: section.options.where(_matches).toList(),
          ),
    ];
  }

  String get _typedCity {
    final parts = _searchController.text.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              CaretOnTapTextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _PickerTile(
                      label: widget.allLabel,
                      selected: widget.selected == null,
                      onTap: () => Navigator.pop(context, ''),
                    ),
                    if (_visibleSections.isNotEmpty)
                      for (final section in _visibleSections) ...[
                        _SectionHeader(section.title),
                        for (final option in section.options)
                          _PickerTile(
                            label: option,
                            selected: widget.selected == option,
                            onTap: () => Navigator.pop(context, option),
                          ),
                      ]
                    else
                      for (final option in _filteredOptions)
                        _PickerTile(
                          label: option,
                          selected: widget.selected == option,
                          onTap: () => Navigator.pop(context, option),
                        ),
                    if (_query.isNotEmpty &&
                        !_filteredOptions.any(
                          (option) => option.toLowerCase() == _query,
                        ))
                      _PickerTile(
                        label: 'Use "$_typedCity"',
                        selected: false,
                        onTap: () => Navigator.pop(context, _typedCity),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
    );
  }
}

/// Simple dropdown for fixed option lists (e.g. years of experience).
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T?> items;
  final String Function(T? value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      itemHeight: kMinInteractiveDimension,
      menuMaxHeight: 280,
      borderRadius: BorderRadius.circular(12),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T?>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
