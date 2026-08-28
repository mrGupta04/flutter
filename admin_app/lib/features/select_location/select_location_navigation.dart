import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import 'selected_location.dart';

Future<SelectedLocationResult?> openSelectLocation(
  BuildContext context, {
  SelectLocationArgs? args,
}) {
  return context.push<SelectedLocationResult>(
    AppConstants.routeSelectLocation,
    extra: args,
  );
}
