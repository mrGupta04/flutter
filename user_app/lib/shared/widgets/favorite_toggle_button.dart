import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/favorites_repository.dart';

/// Heart toggle for doctor/nurse profiles.
class FavoriteToggleButton extends ConsumerStatefulWidget {
  const FavoriteToggleButton({
    super.key,
    required this.providerType,
    required this.providerId,
  });

  final String providerType;
  final String providerId;

  @override
  ConsumerState<FavoriteToggleButton> createState() =>
      _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends ConsumerState<FavoriteToggleButton> {
  final _repo = FavoritesRepository();
  bool? _isFavorite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final favored =
          await _repo.isFavorite(widget.providerType, widget.providerId);
      if (mounted) setState(() => _isFavorite = favored);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggle() async {
    if (_busy || _isFavorite == null) return;
    setState(() => _busy = true);
    try {
      if (_isFavorite!) {
        await _repo.remove(widget.providerType, widget.providerId);
        setState(() => _isFavorite = false);
      } else {
        await _repo.add(widget.providerType, widget.providerId);
        setState(() => _isFavorite = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favored = _isFavorite == true;
    return IconButton(
      tooltip: favored ? 'Remove favorite' : 'Add to favorites',
      onPressed: _busy ? null : _toggle,
      icon: Icon(
        favored ? Icons.favorite : Icons.favorite_border,
        color: favored ? Colors.redAccent : null,
      ),
    );
  }
}
