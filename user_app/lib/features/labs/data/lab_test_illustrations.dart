import '../presentation/widgets/lab_organ_logos.dart';

/// Outline SVG illustrations for lab tests, browse groups, and categories.
abstract final class LabTestIllustrations {
  static const _base = 'assets/illustrations';

  static const blood = '$_base/blood.svg';
  static const bone = '$_base/bone.svg';
  static const diabetes = '$_base/diabetes.svg';
  static const heart = '$_base/heart.svg';
  static const kidney = '$_base/kidney.svg';
  static const liver = '$_base/liver.svg';
  static const lungs = '$_base/lungs.svg';
  static const thyroid = '$_base/thyroid.svg';
  static const vitamin = '$_base/vitamin.svg';
  static const energy = '$_base/energy.svg';
  static const hormones = '$_base/hormones.svg';
  static const pregnancy = '$_base/pregnancy.svg';
  static const reproductive = '$_base/reproductive.svg';
  static const allergy = '$_base/allergy.svg';
  static const virus = '$_base/virus.svg';
  static const mosquito = '$_base/mosquito.svg';
  static const stomach = '$_base/stomach.svg';
  static const brain = '$_base/brain.svg';
  static const eye = '$_base/eye.svg';
  static const skin = '$_base/skin.svg';
  static const shield = '$_base/shield.svg';
  static const fullBody = '$_base/full_body.svg';
  static const thermometer = '$_base/thermometer.svg';
  static const tooth = '$_base/tooth.svg';
  static const ecg = '$_base/ecg.svg';
}

/// SVG illustration path for a browse group, package, or category id.
String labTestIllustrationForId(String id) {
  return switch (id) {
    'diabetes' ||
    'diabetes-risk' ||
    'diabetes-pkg' =>
      LabTestIllustrations.diabetes,
    'heart' ||
    'heart-risk' ||
    'heart-pkg' ||
    'cholesterol' ||
    'cholesterol-risk' ||
    'lipid' ||
    'cardiac' ||
    'hypertension' ||
    'hypertension-risk' =>
      LabTestIllustrations.heart,
    'kidney' ||
    'kidney-risk' ||
    'kidney-disease' ||
    'kidney-pkg' ||
    'urine' ||
    'kft' =>
      LabTestIllustrations.kidney,
    'liver' ||
    'liver-risk' ||
    'fatty-liver' ||
    'liver-pkg' ||
    'stomach' ||
    'stool' ||
    'lft' =>
      LabTestIllustrations.liver,
    'thyroid' ||
    'thyroid-risk' ||
    'thyroid-organ' ||
    'thyroid-pkg' =>
      LabTestIllustrations.thyroid,
    'bones' ||
    'bone-risk' ||
    'arthritis' ||
    'senior' =>
      LabTestIllustrations.bone,
    'blood' || 'anemia' || 'coagulation' => LabTestIllustrations.blood,
    'lungs' || 'asthma' => LabTestIllustrations.lungs,
    'vitamin-risk' ||
    'vitamin-d' ||
    'vitamin' ||
    'vitamin-pkg' ||
    'vitamin-b12' =>
      LabTestIllustrations.vitamin,
    'cancer-risk' || 'cancer-pkg' => LabTestIllustrations.shield,
    'fever' => LabTestIllustrations.thermometer,
    'dengue' || 'malaria' => LabTestIllustrations.mosquito,
    'covid' || 'serology' || 'microbiology' => LabTestIllustrations.virus,
    'pregnancy' => LabTestIllustrations.pregnancy,
    'cancer' || 'cytopathology' => LabTestIllustrations.shield,
    'pcos' => LabTestIllustrations.reproductive,
    'allergy' => LabTestIllustrations.allergy,
    'obesity-risk' => LabTestIllustrations.fullBody,
    'womens' => LabTestIllustrations.reproductive,
    'mens' => LabTestIllustrations.heart,
    'full-body' || 'popular' || 'checkup' => LabTestIllustrations.fullBody,
    'hormonal-risk' || 'hormones' || 'hormone' => LabTestIllustrations.hormones,
    'brain' => LabTestIllustrations.brain,
    'eyes' => LabTestIllustrations.eye,
    'skin' => LabTestIllustrations.skin,
    'dental' => LabTestIllustrations.shield,
    _ => LabTestIllustrations.fullBody,
  };
}

/// SVG illustration for an individual lab test id.
String labTestIllustrationForTestId(String testId) {
  return switch (testId) {
    'cbc' ||
    'esr' ||
    'blood-group' ||
    'iron-studies' =>
      LabTestIllustrations.blood,
    'urine-routine' ||
    'urine-culture' ||
    'urine-microalbumin' =>
      LabTestIllustrations.kidney,
    'thyroid-profile' || 'tsh' || 'anti-tpo' => LabTestIllustrations.thyroid,
    'fbs' ||
    'ppbs' ||
    'hba1c' ||
    'glucose-tolerance' =>
      LabTestIllustrations.diabetes,
    'lft-basic' || 'lft-advanced' => LabTestIllustrations.liver,
    'kft-basic' || 'kft-advanced' => LabTestIllustrations.kidney,
    'lipid-basic' || 'lipid-advanced' || 'crp' => LabTestIllustrations.heart,
    'vitamin-d' || 'vitamin-panel' => LabTestIllustrations.vitamin,
    'vitamin-b12' => LabTestIllustrations.energy,
    'testosterone' || 'cortisol' => LabTestIllustrations.hormones,
    'progesterone' => LabTestIllustrations.pregnancy,
    'ige-total' || 'food-allergy-panel' => LabTestIllustrations.allergy,
    'inhalant-allergy' => LabTestIllustrations.lungs,
    'rt-pcr' || 'rapid-antigen' || 'covid-antibody' =>
      LabTestIllustrations.virus,
    'basic-checkup' ||
    'comprehensive-checkup' ||
    'senior-checkup' ||
    'womens-checkup' =>
      LabTestIllustrations.fullBody,
    'psa' => LabTestIllustrations.shield,
    'stool-routine' => LabTestIllustrations.stomach,
    'dengue-ns1' => LabTestIllustrations.mosquito,
    _ => labTestIllustrationForId(testId),
  };
}

/// SVG illustration when only the painted-logo enum is known.
String labTestIllustrationForOrgan(LabOrganLogo logo) {
  return switch (logo) {
    LabOrganLogo.kidney => LabTestIllustrations.kidney,
    LabOrganLogo.liver || LabOrganLogo.stomach => LabTestIllustrations.liver,
    LabOrganLogo.thyroid => LabTestIllustrations.thyroid,
    LabOrganLogo.heart || LabOrganLogo.cholesterol => LabTestIllustrations.heart,
    LabOrganLogo.bone => LabTestIllustrations.bone,
    LabOrganLogo.bloodDrop => LabTestIllustrations.blood,
    LabOrganLogo.sugar => LabTestIllustrations.diabetes,
    LabOrganLogo.lungs || LabOrganLogo.lungsAir => LabTestIllustrations.lungs,
    LabOrganLogo.brain => LabTestIllustrations.brain,
    LabOrganLogo.eye => LabTestIllustrations.eye,
    LabOrganLogo.skin => LabTestIllustrations.skin,
    LabOrganLogo.thermometer => LabTestIllustrations.thermometer,
    LabOrganLogo.mosquito => LabTestIllustrations.mosquito,
    LabOrganLogo.virus => LabTestIllustrations.virus,
    LabOrganLogo.pregnancy => LabTestIllustrations.pregnancy,
    LabOrganLogo.sun || LabOrganLogo.bolt => LabTestIllustrations.vitamin,
    LabOrganLogo.allergy => LabTestIllustrations.allergy,
    LabOrganLogo.cancer => LabTestIllustrations.shield,
    LabOrganLogo.hormone => LabTestIllustrations.hormones,
    LabOrganLogo.pressure => LabTestIllustrations.heart,
    LabOrganLogo.weight => LabTestIllustrations.fullBody,
    LabOrganLogo.generic => LabTestIllustrations.fullBody,
  };
}
