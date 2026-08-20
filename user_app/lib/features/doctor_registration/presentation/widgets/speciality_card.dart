import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/medical_specialities.dart';

/// Clickable speciality tile used in the Find Doctors by Speciality grid.
class SpecialityCard extends StatefulWidget {
  const SpecialityCard({
    super.key,
    required this.speciality,
    required this.onTap,
    this.selected = false,
  });

  final MedicalSpeciality speciality;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<SpecialityCard> createState() => _SpecialityCardState();
}

class _SpecialityCardState extends State<SpecialityCard> {
  bool _hovered = false;
  bool _pressed = false;

  MedicalSpeciality get _item => widget.speciality;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _item.accent;
    final selected = widget.selected;
    final scale = _pressed ? 0.97 : (_hovered ? 1.02 : 1.0);
    final lift = _hovered && !_pressed ? -3.0 : 0.0;

    return Semantics(
      button: true,
      selected: selected,
      label: '${_item.name}. ${_item.description}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, lift, 0),
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppDecorations.borderRadiusXl,
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.55)
                      : (_hovered
                          ? accent.withValues(alpha: 0.28)
                          : AppColors.border),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(
                      alpha: _hovered || selected ? 0.16 : 0.07,
                    ),
                    blurRadius: _hovered ? 18 : 10,
                    offset: Offset(0, _hovered ? 8 : 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SpecialityIconBadge(speciality: _item),
                      const Spacer(),
                      _ChevronButton(
                        color: accent,
                        highlighted: selected || _hovered,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialityIconBadge extends StatelessWidget {
  const _SpecialityIconBadge({required this.speciality});

  final MedicalSpeciality speciality;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final accent = speciality.accent;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: _icon(size * 0.78)),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(double size) {
    final image = speciality.imageAsset;
    if (image.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          image,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _illustrationOrIcon(size),
        ),
      );
    }

    return _illustrationOrIcon(size);
  }

  Widget _illustrationOrIcon(double size) {
    final illustration = speciality.illustration;
    if (illustration != null) {
      return SvgPicture.asset(
        illustration,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(speciality.accent, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(
          speciality.icon,
          size: size,
          color: speciality.accent,
        ),
      );
    }

    return Icon(speciality.icon, size: size, color: speciality.accent);
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.color,
    required this.highlighted,
  });

  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: highlighted ? 0.18 : 0.10),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: color,
      ),
    );
  }
}
