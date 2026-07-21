import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Recognizable organ / health logos for lab browse cards.
enum LabOrganLogo {
  kidney,
  liver,
  thyroid,
  heart,
  lungs,
  brain,
  stomach,
  bloodDrop,
  bone,
  eye,
  skin,
  sugar,
  thermometer,
  mosquito,
  virus,
  pregnancy,
  sun,
  bolt,
  lungsAir,
  allergy,
  weight,
  pressure,
  cholesterol,
  cancer,
  hormone,
  generic,
}

LabOrganLogo labOrganLogoForId(String id) {
  return switch (id) {
    // Body organs
    'kidney-risk' || 'kidney' || 'kidney-disease' || 'kft' => LabOrganLogo.kidney,
    'liver-risk' || 'liver' || 'fatty-liver' || 'lft' => LabOrganLogo.liver,
    'thyroid-risk' || 'thyroid' || 'thyroid-organ' => LabOrganLogo.thyroid,
    'heart-risk' || 'heart' || 'cholesterol' || 'cholesterol-risk' || 'lipid' =>
      LabOrganLogo.heart,
    'lungs' || 'asthma' => LabOrganLogo.lungs,
    'brain' => LabOrganLogo.brain,
    'stomach' => LabOrganLogo.stomach,
    'blood' || 'anemia' => LabOrganLogo.bloodDrop,
    'bones' || 'bone-risk' || 'arthritis' => LabOrganLogo.bone,
    'eyes' => LabOrganLogo.eye,
    'skin' => LabOrganLogo.skin,
    'hormonal-risk' || 'hormones' || 'hormone' => LabOrganLogo.hormone,

    // Health conditions & risks
    'diabetes-risk' || 'diabetes' => LabOrganLogo.sugar,
    'fever' => LabOrganLogo.thermometer,
    'dengue' || 'malaria' => LabOrganLogo.mosquito,
    'covid' => LabOrganLogo.virus,
    'pregnancy' || 'pcos' => LabOrganLogo.pregnancy,
    'vitamin-risk' || 'vitamin-d' || 'vitamin' => LabOrganLogo.sun,
    'vitamin-b12' => LabOrganLogo.bolt,
    'allergy' => LabOrganLogo.allergy,
    'obesity-risk' => LabOrganLogo.weight,
    'hypertension-risk' || 'hypertension' => LabOrganLogo.pressure,
    'cancer-risk' => LabOrganLogo.cancer,
    'urine' => LabOrganLogo.bloodDrop,

    // Health packages
    'heart-pkg' => LabOrganLogo.heart,
    'liver-pkg' => LabOrganLogo.liver,
    'kidney-pkg' => LabOrganLogo.kidney,
    'diabetes-pkg' => LabOrganLogo.sugar,
    'thyroid-pkg' => LabOrganLogo.thyroid,
    'vitamin-pkg' => LabOrganLogo.sun,
    'cancer-pkg' => LabOrganLogo.cancer,
    'womens' => LabOrganLogo.pregnancy,
    'mens' => LabOrganLogo.heart,
    'senior' => LabOrganLogo.bone,
    'full-body' || 'popular' => LabOrganLogo.generic,
    'checkup' || 'other' => LabOrganLogo.generic,
    _ => LabOrganLogo.generic,
  };
}

/// Organ logo for an individual lab test id.
LabOrganLogo labOrganLogoForTestId(String testId) {
  return switch (testId) {
    'cbc' || 'esr' || 'blood-group' || 'iron-studies' => LabOrganLogo.bloodDrop,
    'urine-routine' || 'urine-culture' || 'urine-microalbumin' =>
      LabOrganLogo.kidney,
    'thyroid-profile' || 'tsh' || 'anti-tpo' => LabOrganLogo.thyroid,
    'fbs' || 'ppbs' || 'hba1c' || 'glucose-tolerance' => LabOrganLogo.sugar,
    'lft-basic' || 'lft-advanced' => LabOrganLogo.liver,
    'kft-basic' || 'kft-advanced' => LabOrganLogo.kidney,
    'lipid-basic' || 'lipid-advanced' => LabOrganLogo.heart,
    'vitamin-d' || 'vitamin-panel' => LabOrganLogo.sun,
    'vitamin-b12' => LabOrganLogo.bolt,
    'testosterone' || 'progesterone' || 'cortisol' => LabOrganLogo.hormone,
    'ige-total' || 'food-allergy-panel' => LabOrganLogo.allergy,
    'inhalant-allergy' => LabOrganLogo.lungs,
    'rt-pcr' || 'rapid-antigen' || 'covid-antibody' => LabOrganLogo.virus,
    'senior-checkup' => LabOrganLogo.bone,
    'womens-checkup' => LabOrganLogo.pregnancy,
    'crp' => LabOrganLogo.heart,
    'psa' => LabOrganLogo.cancer,
    'stool-routine' => LabOrganLogo.stomach,
    'dengue-ns1' => LabOrganLogo.mosquito,
    _ => labOrganLogoForId(testId),
  };
}

class LabOrganLogoPainter extends CustomPainter {
  LabOrganLogoPainter({
    required this.logo,
    required this.color,
  });

  final LabOrganLogo logo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    switch (logo) {
      case LabOrganLogo.kidney:
        _drawKidney(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.liver:
        _drawLiver(canvas, paint, w, h);
      case LabOrganLogo.thyroid:
        _drawThyroid(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.heart:
        _drawHeart(canvas, paint, w, h, cx, cy);
      case LabOrganLogo.lungs:
        _drawLungs(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.brain:
        _drawBrain(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.stomach:
        _drawStomach(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.bloodDrop:
        _drawBloodDrop(canvas, paint, w, h, cx, cy);
      case LabOrganLogo.bone:
        _drawBone(canvas, paint, w, h, cx, cy);
      case LabOrganLogo.eye:
        _drawEye(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.skin:
        _drawSkin(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.sugar:
        _drawBloodDrop(canvas, paint, w, h, cx, cy);
      case LabOrganLogo.thermometer:
        _drawThermometer(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.mosquito:
        _drawBug(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.virus:
        _drawVirus(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.pregnancy:
        _drawPregnancy(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.sun:
        _drawSun(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.bolt:
        _drawBolt(canvas, paint, w, h, cx, cy);
      case LabOrganLogo.lungsAir:
        _drawLungs(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.allergy:
        _drawAllergy(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.weight:
        _drawWeight(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.pressure:
        _drawPressure(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.cholesterol:
        _drawHeart(canvas, paint, w, h, cx, cy);
      case LabOrganLogo.cancer:
        _drawCancer(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.hormone:
        _drawHormone(canvas, paint, stroke, w, h, cx, cy);
      case LabOrganLogo.generic:
        _drawGeneric(canvas, paint, stroke, w, h, cx, cy);
    }
  }

  void _drawKidney(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Bean-shaped kidney.
    final path = Path();
    path.moveTo(w * 0.28, h * 0.22);
    path.cubicTo(w * 0.08, h * 0.32, w * 0.08, h * 0.72, w * 0.30, h * 0.84);
    path.cubicTo(w * 0.48, h * 0.92, w * 0.62, h * 0.78, w * 0.58, h * 0.58);
    path.cubicTo(w * 0.54, h * 0.42, w * 0.70, h * 0.34, w * 0.62, h * 0.22);
    path.cubicTo(w * 0.52, h * 0.12, w * 0.40, h * 0.14, w * 0.28, h * 0.22);
    path.close();
    canvas.drawPath(path, paint);

    // Inner crease for kidney hilum.
    final crease = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sizeShortest(w, h) * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.55, cy),
        width: w * 0.22,
        height: h * 0.36,
      ),
      -math.pi / 2.2,
      math.pi,
      false,
      crease,
    );
  }

  double sizeShortest(double w, double h) => w < h ? w : h;

  void _drawLiver(Canvas canvas, Paint paint, double w, double h) {
    final path = Path();
    path.moveTo(w * 0.18, h * 0.38);
    path.cubicTo(w * 0.12, h * 0.18, w * 0.38, h * 0.10, w * 0.55, h * 0.18);
    path.cubicTo(w * 0.72, h * 0.10, w * 0.92, h * 0.22, w * 0.88, h * 0.42);
    path.cubicTo(w * 0.96, h * 0.58, w * 0.86, h * 0.78, w * 0.68, h * 0.84);
    path.cubicTo(w * 0.50, h * 0.90, w * 0.34, h * 0.82, w * 0.26, h * 0.68);
    path.cubicTo(w * 0.14, h * 0.58, w * 0.14, h * 0.48, w * 0.18, h * 0.38);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawThyroid(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Butterfly / two lobes connected by isthmus.
    final left = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.34, cy),
        width: w * 0.38,
        height: h * 0.62,
      ));
    final right = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.66, cy),
        width: w * 0.38,
        height: h * 0.62,
      ));
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.22, height: h * 0.16),
        Radius.circular(w * 0.06),
      ),
      paint,
    );
  }

  void _drawHeart(
    Canvas canvas,
    Paint paint,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path();
    path.moveTo(cx, h * 0.82);
    path.cubicTo(w * 0.10, h * 0.58, w * 0.05, h * 0.28, w * 0.30, h * 0.20);
    path.cubicTo(w * 0.42, h * 0.14, w * 0.50, h * 0.28, cx, h * 0.40);
    path.cubicTo(w * 0.50, h * 0.28, w * 0.58, h * 0.14, w * 0.70, h * 0.20);
    path.cubicTo(w * 0.95, h * 0.28, w * 0.90, h * 0.58, cx, h * 0.82);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLungs(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final left = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.30, h * 0.62),
        Radius.circular(w * 0.14),
      ));
    final right = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.30, h * 0.62),
        Radius.circular(w * 0.14),
      ));
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawLine(Offset(cx, h * 0.12), Offset(cx, h * 0.55), stroke);
  }

  void _drawBrain(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy * 0.95), width: w * 0.72, height: h * 0.62),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy * 0.85), width: w * 0.55, height: h * 0.40),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      stroke,
    );
  }

  void _drawStomach(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path();
    path.moveTo(w * 0.35, h * 0.18);
    path.cubicTo(w * 0.55, h * 0.10, w * 0.78, h * 0.28, w * 0.72, h * 0.48);
    path.cubicTo(w * 0.88, h * 0.62, w * 0.70, h * 0.88, w * 0.42, h * 0.82);
    path.cubicTo(w * 0.22, h * 0.78, w * 0.18, h * 0.50, w * 0.30, h * 0.38);
    path.cubicTo(w * 0.22, h * 0.28, w * 0.26, h * 0.20, w * 0.35, h * 0.18);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawBloodDrop(
    Canvas canvas,
    Paint paint,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path();
    path.moveTo(cx, h * 0.12);
    path.cubicTo(w * 0.72, h * 0.38, w * 0.82, h * 0.62, cx, h * 0.86);
    path.cubicTo(w * 0.18, h * 0.62, w * 0.28, h * 0.38, cx, h * 0.12);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawBone(
    Canvas canvas,
    Paint paint,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(w * 0.28, h * 0.30), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.70), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.30), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.70), w * 0.14, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.55, height: h * 0.22),
        Radius.circular(w * 0.1),
      ),
      paint,
    );
  }

  void _drawEye(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path();
    path.moveTo(w * 0.12, cy);
    path.quadraticBezierTo(cx, h * 0.18, w * 0.88, cy);
    path.quadraticBezierTo(cx, h * 0.82, w * 0.12, cy);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, cy), w * 0.14, Paint()..color = color.withValues(alpha: 0.35));
  }

  void _drawSkin(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.42), width: w * 0.55, height: h * 0.55),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.40, h * 0.40), w * 0.04, stroke);
    canvas.drawCircle(Offset(w * 0.60, h * 0.40), w * 0.04, stroke);
  }

  void _drawThermometer(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.40), width: w * 0.18, height: h * 0.55),
        Radius.circular(w * 0.09),
      ),
      paint,
    );
    canvas.drawCircle(Offset(cx, h * 0.72), w * 0.18, paint);
  }

  void _drawBug(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.42, height: h * 0.55),
      paint,
    );
    canvas.drawLine(Offset(w * 0.22, h * 0.30), Offset(w * 0.08, h * 0.18), stroke);
    canvas.drawLine(Offset(w * 0.78, h * 0.30), Offset(w * 0.92, h * 0.18), stroke);
    canvas.drawLine(Offset(w * 0.20, h * 0.55), Offset(w * 0.06, h * 0.62), stroke);
    canvas.drawLine(Offset(w * 0.80, h * 0.55), Offset(w * 0.94, h * 0.62), stroke);
  }

  void _drawVirus(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      final x1 = cx + math.cos(a) * w * 0.28;
      final y1 = cy + math.sin(a) * h * 0.28;
      final x2 = cx + math.cos(a) * w * 0.42;
      final y2 = cy + math.sin(a) * h * 0.42;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke);
      canvas.drawCircle(Offset(x2, y2), w * 0.05, paint);
    }
  }

  void _drawPregnancy(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, h * 0.28), w * 0.14, paint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.62), width: w * 0.42, height: h * 0.40),
      paint,
    );
  }

  void _drawSun(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, cy), w * 0.22, paint);
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      canvas.drawLine(
        Offset(cx + math.cos(a) * w * 0.30, cy + math.sin(a) * h * 0.30),
        Offset(cx + math.cos(a) * w * 0.42, cy + math.sin(a) * h * 0.42),
        stroke,
      );
    }
  }

  void _drawBolt(
    Canvas canvas,
    Paint paint,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path()
      ..moveTo(w * 0.58, h * 0.12)
      ..lineTo(w * 0.32, h * 0.48)
      ..lineTo(w * 0.50, h * 0.48)
      ..lineTo(w * 0.38, h * 0.88)
      ..lineTo(w * 0.72, h * 0.42)
      ..lineTo(w * 0.52, h * 0.42)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawAllergy(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Flower / pollen.
    for (var i = 0; i < 5; i++) {
      final a = (i / 5) * math.pi * 2 - math.pi / 2;
      canvas.drawCircle(
        Offset(cx + math.cos(a) * w * 0.22, cy + math.sin(a) * h * 0.22),
        w * 0.12,
        paint,
      );
    }
    canvas.drawCircle(Offset(cx, cy), w * 0.12, paint);
  }

  void _drawWeight(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.58), width: w * 0.62, height: h * 0.42),
        Radius.circular(w * 0.08),
      ),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, h * 0.42), width: w * 0.40, height: h * 0.28),
      math.pi,
      math.pi,
      false,
      stroke,
    );
  }

  void _drawPressure(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Gauge / speedometer style.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, h * 0.58), width: w * 0.70, height: h * 0.70),
      math.pi,
      math.pi,
      false,
      stroke,
    );
    canvas.drawCircle(Offset(cx, h * 0.58), w * 0.06, paint);
    canvas.drawLine(Offset(cx, h * 0.58), Offset(w * 0.70, h * 0.32), stroke);
  }

  void _drawCancer(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, cy), w * 0.22, paint);
    for (var i = 0; i < 6; i++) {
      final a = (i / 6) * math.pi * 2;
      canvas.drawCircle(
        Offset(cx + math.cos(a) * w * 0.28, cy + math.sin(a) * h * 0.28),
        w * 0.08,
        paint,
      );
    }
  }

  void _drawHormone(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(w * 0.30, h * 0.35), w * 0.12, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.65), w * 0.12, paint);
    canvas.drawLine(Offset(w * 0.36, h * 0.40), Offset(w * 0.64, h * 0.60), stroke);
  }

  void _drawGeneric(
    Canvas canvas,
    Paint paint,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);
    canvas.drawCircle(Offset(cx, cy), w * 0.12, stroke);
  }

  @override
  bool shouldRepaint(covariant LabOrganLogoPainter oldDelegate) {
    return oldDelegate.logo != logo || oldDelegate.color != color;
  }
}

/// Renders a white organ logo sized for browse badges.
class LabOrganLogoIcon extends StatelessWidget {
  const LabOrganLogoIcon({
    super.key,
    this.groupId,
    this.testId,
    this.logo,
    this.size = 22,
    this.color = Colors.white,
  }) : assert(
          groupId != null || testId != null || logo != null,
          'Provide groupId, testId, or logo',
        );

  final String? groupId;
  final String? testId;
  final LabOrganLogo? logo;
  final double size;
  final Color color;

  LabOrganLogo get _resolvedLogo {
    if (logo != null) return logo!;
    if (testId != null) return labOrganLogoForTestId(testId!);
    return labOrganLogoForId(groupId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: LabOrganLogoPainter(
          logo: _resolvedLogo,
          color: color,
        ),
      ),
    );
  }
}
