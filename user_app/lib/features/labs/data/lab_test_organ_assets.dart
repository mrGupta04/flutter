import 'health_package_visuals.dart';
import 'models/lab_test_model.dart';

/// PNG organ hero assets for individual lab test list thumbnails.
String labTestOrganAssetFor(LabTest test) =>
    labTestOrganAssetForTestId(test.id, test.category);

String labTestOrganAssetForTestId(String testId, LabTestCategory category) {
  return switch (testId) {
    'cbc' ||
    'esr' ||
    'blood-group' ||
    'iron-studies' ||
    'crp' =>
      OrganAssets.blood,
    'urine-routine' ||
    'urine-culture' ||
    'urine-microalbumin' =>
      OrganAssets.kidney,
    'thyroid-profile' || 'tsh' || 'anti-tpo' => OrganAssets.thyroid,
    'fbs' ||
    'ppbs' ||
    'hba1c' ||
    'glucose-tolerance' =>
      OrganAssets.diabetes,
    'lft-basic' || 'lft-advanced' => OrganAssets.liver,
    'kft-basic' || 'kft-advanced' => OrganAssets.kidney,
    'lipid-basic' || 'lipid-advanced' => OrganAssets.cholesterol,
    'vitamin-d' || 'vitamin-panel' => OrganAssets.vitamin,
    'vitamin-b12' => OrganAssets.vitamin,
    'testosterone' || 'cortisol' => OrganAssets.muscle,
    'progesterone' => OrganAssets.pregnancy,
    'ige-total' || 'food-allergy-panel' => OrganAssets.allergy,
    'inhalant-allergy' => OrganAssets.lungs,
    'rt-pcr' || 'rapid-antigen' || 'covid-antibody' => OrganAssets.immuneSystem,
    'basic-checkup' ||
    'comprehensive-checkup' ||
    'senior-checkup' ||
    'womens-checkup' =>
      OrganAssets.dna,
    'psa' => OrganAssets.immuneCell,
    'stool-routine' => OrganAssets.stomach,
    'dengue-ns1' => OrganAssets.dengue,
    _ => _organAssetForCategory(category),
  };
}

String _organAssetForCategory(LabTestCategory category) {
  return switch (category) {
    LabTestCategory.bloodTests => OrganAssets.blood,
    LabTestCategory.coagulationTests => OrganAssets.blood,
    LabTestCategory.urineTests => OrganAssets.kidney,
    LabTestCategory.stoolTests => OrganAssets.stomach,
    LabTestCategory.thyroidTests => OrganAssets.thyroid,
    LabTestCategory.diabetesTests => OrganAssets.diabetes,
    LabTestCategory.liverFunctionTests => OrganAssets.liver,
    LabTestCategory.kidneyFunctionTests => OrganAssets.kidney,
    LabTestCategory.lipidProfile => OrganAssets.cholesterol,
    LabTestCategory.cardiacTests => OrganAssets.cholesterol,
    LabTestCategory.vitaminTests => OrganAssets.vitamin,
    LabTestCategory.hormoneTests => OrganAssets.spine,
    LabTestCategory.pregnancyTests => OrganAssets.pregnancy,
    LabTestCategory.cancerMarkerTests => OrganAssets.immuneCell,
    LabTestCategory.serologyTests => OrganAssets.immuneSystem,
    LabTestCategory.microbiologyTests => OrganAssets.immuneSystem,
    LabTestCategory.cytopathologyTests => OrganAssets.dna,
    LabTestCategory.allergyTests => OrganAssets.allergy,
    LabTestCategory.covid19Tests => OrganAssets.immuneSystem,
    LabTestCategory.fullBodyCheckups => OrganAssets.dna,
    LabTestCategory.other => OrganAssets.blood,
  };
}
