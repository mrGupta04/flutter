import 'package:flutter/material.dart';

/// App bar title that ellipsizes instead of clipping mid-word on narrow screens.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge;
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: style,
    );
  }
}
