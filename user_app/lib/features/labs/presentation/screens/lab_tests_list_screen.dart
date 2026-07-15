import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lab_model.dart';
import '../../data/models/lab_test_model.dart';
import '../../data/lab_catalog_metadata.dart';
import '../../data/lab_tests_catalog.dart';
import '../widgets/lab_browse_group_card.dart';
import '../widgets/lab_package_card.dart';
import '../widgets/lab_test_tile.dart';

class LabTestsListScreen extends ConsumerStatefulWidget {
  const LabTestsListScreen({
    super.key,
    required this.lab,
    required this.title,
    this.testIds,
    this.browseType,
  });

  final LabModel lab;
  final String title;
  final List<String>? testIds;
  final LabBrowseGroupType? browseType;

  @override
  ConsumerState<LabTestsListScreen> createState() =>
      _LabTestsListScreenState();
}

class _LabTestsListScreenState extends ConsumerState<LabTestsListScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _browseGroups {
    if (widget.browseType == null) return const [];
    return switch (widget.browseType!) {
      LabBrowseGroupType.healthRisk => LabCatalogMetadata.healthRisks,
      LabBrowseGroupType.healthCondition => LabCatalogMetadata.healthConditions,
      LabBrowseGroupType.bodyOrgan => LabCatalogMetadata.bodyOrgans,
      LabBrowseGroupType.package => LabCatalogMetadata.healthPackages,
    };
  }

  List<LabTest> get _tests {
    if (widget.browseType != null) return const [];
    final ids = widget.testIds;
    if (ids != null) return LabTestsCatalog.byIds(ids);
    return labTestsForLab(widget.lab, query: _query.isEmpty ? null : _query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: widget.browseType != null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: widget.browseType == LabBrowseGroupType.package
                  ? LabCatalogMetadata.healthPackages
                      .map(
                        (pkg) => LabPackageCard(
                          package: pkg,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => LabTestsListScreen(
                                  lab: widget.lab,
                                  title: pkg.name,
                                  testIds: pkg.testIds,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList()
                  : _browseGroups.map((group) {
                      final g = group as LabBrowseGroup;
                      return LabBrowseGroupListTile(
                        group: g,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LabTestsListScreen(
                                lab: widget.lab,
                                title: g.name,
                                testIds: g.testIds,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
            )
          : Column(
              children: [
                if (widget.testIds == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tests...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 350), () {
                          if (mounted) setState(() => _query = v.trim());
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tests.length,
                    itemBuilder: (context, index) {
                      final test = _tests[index];
                      return LabTestTile(
                        lab: widget.lab,
                        test: test,
                        offered: resolveOfferedTest(widget.lab, test),
                        onBookNow: () => context.push(AppConstants.routeLabCart),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
