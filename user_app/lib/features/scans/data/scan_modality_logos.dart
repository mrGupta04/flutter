import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/scan_procedure_model.dart';

/// Recognizable modality logos for MRI, CT, X-Ray, Ultrasound, etc.
enum ScanModalityLogo {
  mri,
  ct,
  xray,
  ultrasound,
  pet,
  mammography,
  ecg,
  eeg,
  echo,
  doppler,
  dexa,
  fluoroscopy,
  endoscopy,
  colonoscopy,
  bronchoscopy,
  tmt,
  ncv,
  emg,
  brain,
  spine,
  knee,
  abdomen,
  chest,
  dental,
  pregnancy,
  thyroid,
  generic,
}

ScanModalityLogo scanLogoForCategory(ScanCategory category) {
  return switch (category) {
    ScanCategory.mri => ScanModalityLogo.mri,
    ScanCategory.ct => ScanModalityLogo.ct,
    ScanCategory.xray => ScanModalityLogo.xray,
    ScanCategory.ultrasound => ScanModalityLogo.ultrasound,
    ScanCategory.pet => ScanModalityLogo.pet,
    ScanCategory.mammography => ScanModalityLogo.mammography,
    ScanCategory.ecg => ScanModalityLogo.ecg,
    ScanCategory.eeg => ScanModalityLogo.eeg,
    ScanCategory.echo => ScanModalityLogo.echo,
    ScanCategory.doppler => ScanModalityLogo.doppler,
    ScanCategory.dexa => ScanModalityLogo.dexa,
    ScanCategory.fluoroscopy => ScanModalityLogo.fluoroscopy,
    ScanCategory.endoscopy => ScanModalityLogo.endoscopy,
    ScanCategory.colonoscopy => ScanModalityLogo.colonoscopy,
    ScanCategory.bronchoscopy => ScanModalityLogo.bronchoscopy,
    ScanCategory.tmt => ScanModalityLogo.tmt,
    ScanCategory.ncv => ScanModalityLogo.ncv,
    ScanCategory.emg => ScanModalityLogo.emg,
    ScanCategory.other => ScanModalityLogo.generic,
  };
}

ScanModalityLogo scanLogoForProcedure(ScanProcedure procedure) {
  return switch (procedure.id) {
    'mri-brain' || 'ct-brain' => ScanModalityLogo.brain,
    'mri-spine' || 'xray-spine' => ScanModalityLogo.spine,
    'mri-knee' || 'xray-knee' => ScanModalityLogo.knee,
    'mri-abdomen' || 'ct-abdomen' || 'usg-abdomen' => ScanModalityLogo.abdomen,
    'xray-chest' || 'ct-chest' => ScanModalityLogo.chest,
    'xray-dental' => ScanModalityLogo.dental,
    'usg-pregnancy' => ScanModalityLogo.pregnancy,
    'usg-thyroid' => ScanModalityLogo.thyroid,
    'usg-pelvis' => ScanModalityLogo.ultrasound,
    'echo-2d' => ScanModalityLogo.echo,
    'dexa-scan' => ScanModalityLogo.dexa,
    'pet-whole-body' => ScanModalityLogo.pet,
    'mammography-bilateral' => ScanModalityLogo.mammography,
    _ => scanLogoForCategory(procedure.category),
  };
}

class ScanModalityLogoPainter extends CustomPainter {
  ScanModalityLogoPainter({
    required this.logo,
    required this.color,
  });

  final ScanModalityLogo logo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
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
      case ScanModalityLogo.mri:
        _drawMri(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.ct:
        _drawCt(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.xray:
        _drawXray(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.ultrasound:
        _drawUltrasound(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.pet:
        _drawPet(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.mammography:
        _drawMammo(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.ecg:
        _drawEcg(canvas, stroke, w, h, cx, cy);
      case ScanModalityLogo.eeg:
        _drawEeg(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.echo:
        _drawEcho(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.doppler:
        _drawDoppler(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.dexa:
        _drawDexa(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.fluoroscopy:
        _drawFluoro(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.endoscopy:
        _drawScope(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.colonoscopy:
        _drawScope(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.bronchoscopy:
        _drawLungs(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.tmt:
        _drawTmt(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.ncv:
        _drawNerve(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.emg:
        _drawBolt(canvas, fill, w, h);
      case ScanModalityLogo.brain:
        _drawBrain(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.spine:
        _drawSpine(canvas, fill, w, h, cx);
      case ScanModalityLogo.knee:
        _drawKnee(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.abdomen:
        _drawAbdomen(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.chest:
        _drawLungs(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.dental:
        _drawTooth(canvas, fill, stroke, w, h, cx, cy);
      case ScanModalityLogo.pregnancy:
        _drawPregnancy(canvas, fill, w, h, cx);
      case ScanModalityLogo.thyroid:
        _drawThyroid(canvas, fill, w, h, cx, cy);
      case ScanModalityLogo.generic:
        _drawGeneric(canvas, fill, stroke, w, h, cx, cy);
    }
  }

  void _drawMri(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // MRI bore / donut magnet.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.78, height: h * 0.70),
      stroke,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.48, height: h * 0.42),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.86), width: w * 0.55, height: h * 0.10),
        Radius.circular(w * 0.04),
      ),
      fill,
    );
    // Patient bed.
    canvas.drawLine(Offset(w * 0.18, h * 0.78), Offset(w * 0.82, h * 0.78), stroke);
  }

  void _drawCt(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // CT gantry ring with slice lines.
    canvas.drawCircle(Offset(cx, cy), w * 0.34, stroke);
    canvas.drawCircle(Offset(cx, cy), w * 0.18, stroke);
    for (var i = 0; i < 6; i++) {
      final a = (i / 6) * math.pi * 2;
      canvas.drawLine(
        Offset(cx + math.cos(a) * w * 0.18, cy + math.sin(a) * h * 0.18),
        Offset(cx + math.cos(a) * w * 0.34, cy + math.sin(a) * h * 0.34),
        stroke,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.86), width: w * 0.50, height: h * 0.10),
        Radius.circular(w * 0.04),
      ),
      fill,
    );
  }

  void _drawXray(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // X-ray tube / crosshair with beam.
    canvas.drawCircle(Offset(cx, h * 0.28), w * 0.12, fill);
    canvas.drawLine(Offset(cx, h * 0.38), Offset(cx, h * 0.72), stroke);
    canvas.drawLine(Offset(w * 0.22, h * 0.55), Offset(w * 0.78, h * 0.55), stroke);
    // Film cassette.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.82), width: w * 0.55, height: h * 0.14),
        Radius.circular(w * 0.04),
      ),
      stroke,
    );
    // Beam cone.
    final beam = Path()
      ..moveTo(cx, h * 0.38)
      ..lineTo(w * 0.28, h * 0.74)
      ..lineTo(w * 0.72, h * 0.74)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawUltrasound(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Probe head + sound waves.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.68), width: w * 0.28, height: h * 0.36),
        Radius.circular(w * 0.08),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.48), width: w * 0.42, height: h * 0.16),
        Radius.circular(w * 0.06),
      ),
      fill,
    );
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, h * 0.38),
          width: w * (0.28 + i * 0.18),
          height: h * (0.22 + i * 0.14),
        ),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        stroke,
      );
    }
  }

  void _drawPet(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, cy), w * 0.22, fill);
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      canvas.drawLine(
        Offset(cx + math.cos(a) * w * 0.24, cy + math.sin(a) * h * 0.24),
        Offset(cx + math.cos(a) * w * 0.40, cy + math.sin(a) * h * 0.40),
        stroke,
      );
      canvas.drawCircle(
        Offset(cx + math.cos(a) * w * 0.42, cy + math.sin(a) * h * 0.42),
        w * 0.05,
        fill,
      );
    }
  }

  void _drawMammo(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path();
    path.moveTo(cx, h * 0.78);
    path.cubicTo(w * 0.18, h * 0.58, w * 0.18, h * 0.28, w * 0.40, h * 0.22);
    path.cubicTo(w * 0.48, h * 0.18, cx, h * 0.30, cx, h * 0.38);
    path.cubicTo(cx, h * 0.30, w * 0.52, h * 0.18, w * 0.60, h * 0.22);
    path.cubicTo(w * 0.82, h * 0.28, w * 0.82, h * 0.58, cx, h * 0.78);
    path.close();
    canvas.drawPath(path, fill);
  }

  void _drawEcg(
    Canvas canvas,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path()
      ..moveTo(w * 0.08, cy)
      ..lineTo(w * 0.28, cy)
      ..lineTo(w * 0.36, h * 0.28)
      ..lineTo(w * 0.46, h * 0.78)
      ..lineTo(w * 0.56, h * 0.22)
      ..lineTo(w * 0.66, cy)
      ..lineTo(w * 0.92, cy);
    canvas.drawPath(path, stroke);
  }

  void _drawEeg(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    _drawBrain(canvas, fill, stroke, w, h, cx, cy);
    canvas.drawLine(Offset(w * 0.30, h * 0.42), Offset(w * 0.70, h * 0.42), stroke);
    canvas.drawLine(Offset(w * 0.34, h * 0.55), Offset(w * 0.66, h * 0.55), stroke);
  }

  void _drawEcho(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path();
    path.moveTo(cx, h * 0.78);
    path.cubicTo(w * 0.12, h * 0.55, w * 0.12, h * 0.28, w * 0.36, h * 0.22);
    path.cubicTo(w * 0.46, h * 0.18, cx, h * 0.32, cx, h * 0.40);
    path.cubicTo(cx, h * 0.32, w * 0.54, h * 0.18, w * 0.64, h * 0.22);
    path.cubicTo(w * 0.88, h * 0.28, w * 0.88, h * 0.55, cx, h * 0.78);
    path.close();
    canvas.drawPath(path, fill);
    // Echo arcs.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, h * 0.48), width: w * 0.35, height: h * 0.28),
      math.pi * 0.2,
      math.pi * 0.6,
      false,
      stroke,
    );
  }

  void _drawDoppler(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.28, height: h * 0.55),
      fill,
    );
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w * 0.72, cy),
          width: w * (0.18 + i * 0.14),
          height: h * (0.22 + i * 0.12),
        ),
        -math.pi / 2.5,
        math.pi / 1.4,
        false,
        stroke,
      );
    }
  }

  void _drawDexa(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Bone density bone silhouette.
    canvas.drawCircle(Offset(w * 0.28, h * 0.28), w * 0.12, fill);
    canvas.drawCircle(Offset(w * 0.28, h * 0.72), w * 0.12, fill);
    canvas.drawCircle(Offset(w * 0.72, h * 0.28), w * 0.12, fill);
    canvas.drawCircle(Offset(w * 0.72, h * 0.72), w * 0.12, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.52, height: h * 0.20),
        Radius.circular(w * 0.08),
      ),
      fill,
    );
  }

  void _drawFluoro(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.72, height: h * 0.55),
        Radius.circular(w * 0.08),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(cx, cy), w * 0.12, fill);
    canvas.drawLine(Offset(w * 0.22, h * 0.35), Offset(w * 0.78, h * 0.65), stroke);
  }

  void _drawScope(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path()
      ..moveTo(w * 0.22, h * 0.78)
      ..quadraticBezierTo(w * 0.18, h * 0.40, w * 0.45, h * 0.28)
      ..quadraticBezierTo(w * 0.78, h * 0.18, w * 0.72, h * 0.42);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(Offset(w * 0.72, h * 0.42), w * 0.10, fill);
    canvas.drawCircle(Offset(w * 0.22, h * 0.78), w * 0.08, fill);
  }

  void _drawLungs(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.30, h * 0.55),
        Radius.circular(w * 0.14),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.22, w * 0.30, h * 0.55),
        Radius.circular(w * 0.14),
      ),
      fill,
    );
    canvas.drawLine(Offset(cx, h * 0.16), Offset(cx, h * 0.50), stroke);
  }

  void _drawTmt(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    // Treadmill + figure.
    canvas.drawLine(Offset(w * 0.12, h * 0.78), Offset(w * 0.88, h * 0.78), stroke);
    canvas.drawLine(Offset(w * 0.20, h * 0.78), Offset(w * 0.35, h * 0.55), stroke);
    canvas.drawCircle(Offset(w * 0.42, h * 0.32), w * 0.08, fill);
    canvas.drawLine(Offset(w * 0.42, h * 0.40), Offset(w * 0.42, h * 0.58), stroke);
    canvas.drawLine(Offset(w * 0.42, h * 0.58), Offset(w * 0.30, h * 0.72), stroke);
    canvas.drawLine(Offset(w * 0.42, h * 0.58), Offset(w * 0.58, h * 0.72), stroke);
  }

  void _drawNerve(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawLine(Offset(w * 0.20, h * 0.75), Offset(w * 0.80, h * 0.25), stroke);
    for (var i = 0; i < 4; i++) {
      final t = 0.2 + i * 0.2;
      final x = w * (0.20 + (0.60 * t));
      final y = h * (0.75 - (0.50 * t));
      canvas.drawCircle(Offset(x, y), w * 0.05, fill);
    }
  }

  void _drawBolt(Canvas canvas, Paint fill, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.58, h * 0.12)
      ..lineTo(w * 0.32, h * 0.48)
      ..lineTo(w * 0.50, h * 0.48)
      ..lineTo(w * 0.38, h * 0.88)
      ..lineTo(w * 0.72, h * 0.42)
      ..lineTo(w * 0.52, h * 0.42)
      ..close();
    canvas.drawPath(path, fill);
  }

  void _drawBrain(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy * 0.95), width: w * 0.72, height: h * 0.60),
      fill,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy * 0.88), width: w * 0.50, height: h * 0.36),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      stroke,
    );
  }

  void _drawSpine(Canvas canvas, Paint fill, double w, double h, double cx) {
    for (var i = 0; i < 5; i++) {
      final y = h * (0.16 + i * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y), width: w * (0.42 - i * 0.02), height: h * 0.11),
          Radius.circular(w * 0.04),
        ),
        fill,
      );
    }
  }

  void _drawKnee(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.28), width: w * 0.28, height: h * 0.36),
        Radius.circular(w * 0.1),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.72), width: w * 0.28, height: h * 0.36),
        Radius.circular(w * 0.1),
      ),
      fill,
    );
    canvas.drawCircle(Offset(cx, cy), w * 0.14, stroke);
  }

  void _drawAbdomen(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.62, height: h * 0.70),
        Radius.circular(w * 0.18),
      ),
      stroke,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.40, h * 0.48), width: w * 0.18, height: h * 0.22),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.60, h * 0.55), width: w * 0.16, height: h * 0.20),
      fill,
    );
  }

  void _drawTooth(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    final path = Path()
      ..moveTo(w * 0.30, h * 0.28)
      ..quadraticBezierTo(cx, h * 0.12, w * 0.70, h * 0.28)
      ..lineTo(w * 0.68, h * 0.55)
      ..quadraticBezierTo(w * 0.62, h * 0.85, w * 0.52, h * 0.88)
      ..quadraticBezierTo(cx, h * 0.72, w * 0.48, h * 0.88)
      ..quadraticBezierTo(w * 0.38, h * 0.85, w * 0.32, h * 0.55)
      ..close();
    canvas.drawPath(path, fill);
  }

  void _drawPregnancy(Canvas canvas, Paint fill, double w, double h, double cx) {
    canvas.drawCircle(Offset(cx, h * 0.28), w * 0.12, fill);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.62), width: w * 0.42, height: h * 0.40),
      fill,
    );
  }

  void _drawThyroid(
    Canvas canvas,
    Paint fill,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.34, cy), width: w * 0.36, height: h * 0.58),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.66, cy), width: w * 0.36, height: h * 0.58),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w * 0.20, height: h * 0.14),
        Radius.circular(w * 0.05),
      ),
      fill,
    );
  }

  void _drawGeneric(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    canvas.drawCircle(Offset(cx, cy), w * 0.28, stroke);
    canvas.drawCircle(Offset(cx, cy), w * 0.12, fill);
  }

  @override
  bool shouldRepaint(covariant ScanModalityLogoPainter oldDelegate) {
    return oldDelegate.logo != logo || oldDelegate.color != color;
  }
}

class ScanModalityLogoIcon extends StatelessWidget {
  const ScanModalityLogoIcon({
    super.key,
    required this.logo,
    this.size = 22,
    this.color = Colors.white,
  });

  final ScanModalityLogo logo;
  final double size;
  final Color color;

  factory ScanModalityLogoIcon.forCategory(
    ScanCategory category, {
    double size = 22,
    Color color = Colors.white,
  }) {
    return ScanModalityLogoIcon(
      logo: scanLogoForCategory(category),
      size: size,
      color: color,
    );
  }

  factory ScanModalityLogoIcon.forProcedure(
    ScanProcedure procedure, {
    double size = 22,
    Color color = Colors.white,
  }) {
    return ScanModalityLogoIcon(
      logo: scanLogoForProcedure(procedure),
      size: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ScanModalityLogoPainter(logo: logo, color: color),
      ),
    );
  }
}
