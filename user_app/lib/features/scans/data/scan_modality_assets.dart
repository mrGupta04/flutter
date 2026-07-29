import '../../labs/data/health_package_visuals.dart';
import 'models/scan_procedure_model.dart';

/// Real PNG illustrations for scan procedure / modality cards.
abstract final class ScanModalityAssets {
  static const _home = 'assets/images/home_cards';

  static const diagnostic = '$_home/diagnostic_scans.png';
  static const scanCard = '$_home/scan_card-removebg-preview.png';
  static const scanService = '$_home/scan_service_card.png';
}

/// Returns a local organ / modality illustration path for a procedure.
String scanProcedureAssetFor(ScanProcedure procedure) {
  return scanProcedureAssetForId(
    procedure.id,
    procedure.name,
    procedure.category,
  );
}

String scanProcedureAssetForId(
  String id,
  String name,
  ScanCategory category,
) {
  final key = '${id.toLowerCase()} ${name.toLowerCase()}';

  if (key.contains('brain') || key.contains('head') || key.contains('skull')) {
    return OrganAssets.eye; // closest soft organ hero for cranial scans
  }
  if (key.contains('spine') || key.contains('cervical') || key.contains('lumbar')) {
    return OrganAssets.spine;
  }
  if (key.contains('knee') || key.contains('joint') || key.contains('ortho')) {
    return OrganAssets.bone;
  }
  if (key.contains('chest') ||
      key.contains('lung') ||
      key.contains('hrct') ||
      key.contains('thorax')) {
    return OrganAssets.lungs;
  }
  if (key.contains('thyroid') || key.contains('neck')) {
    return OrganAssets.thyroid;
  }
  if (key.contains('dental') || key.contains('opg') || key.contains('tooth')) {
    return OrganAssets.tooth;
  }
  if (key.contains('pregnancy') ||
      key.contains('obstetric') ||
      key.contains('anomaly') ||
      key.contains('fetal') ||
      key.contains('pelvis') ||
      key.contains('mammo')) {
    return OrganAssets.pregnancy;
  }
  if (key.contains('heart') ||
      key.contains('echo') ||
      key.contains('cardiac') ||
      key.contains('ecg') ||
      key.contains('tmt')) {
    return OrganAssets.heart;
  }
  if (key.contains('abdomen') ||
      key.contains('liver') ||
      key.contains('gall') ||
      key.contains('stomach')) {
    return OrganAssets.liver;
  }
  if (key.contains('kidney') || key.contains('renal') || key.contains('kub')) {
    return OrganAssets.kidney;
  }
  if (key.contains('dexa') || key.contains('bone') || key.contains('density')) {
    return OrganAssets.bone;
  }
  if (key.contains('skin') || key.contains('derm')) {
    return OrganAssets.skin;
  }
  if (key.contains('muscle') || key.contains('emg') || key.contains('ncv')) {
    return OrganAssets.muscle;
  }

  return scanCategoryAssetFor(category);
}

String scanCategoryAssetFor(ScanCategory category) {
  return switch (category) {
    ScanCategory.mri => ScanModalityAssets.diagnostic,
    ScanCategory.ct => OrganAssets.lungs,
    ScanCategory.xray => OrganAssets.bone,
    ScanCategory.ultrasound => OrganAssets.pregnancy,
    ScanCategory.pet => OrganAssets.immuneSystem,
    ScanCategory.mammography => OrganAssets.pregnancy,
    ScanCategory.ecg => OrganAssets.heart,
    ScanCategory.eeg => OrganAssets.eye,
    ScanCategory.echo => OrganAssets.heart,
    ScanCategory.doppler => OrganAssets.bloodPressure,
    ScanCategory.dexa => OrganAssets.bone,
    ScanCategory.fluoroscopy => ScanModalityAssets.scanCard,
    ScanCategory.endoscopy => OrganAssets.stomach,
    ScanCategory.colonoscopy => OrganAssets.stomach,
    ScanCategory.bronchoscopy => OrganAssets.lungs,
    ScanCategory.tmt => OrganAssets.heart,
    ScanCategory.ncv => OrganAssets.muscle,
    ScanCategory.emg => OrganAssets.muscle,
    ScanCategory.other => ScanModalityAssets.scanService,
  };
}

/// Prefer API-uploaded image, else local modality illustration.
String? scanProcedureNetworkImage(ScanProcedure procedure) {
  for (final url in procedure.images) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? scanOfferedNetworkImage(List<String> images) {
  for (final url in images) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
