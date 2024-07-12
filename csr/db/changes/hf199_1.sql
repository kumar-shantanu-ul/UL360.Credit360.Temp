-- Please update version.sql too -- this keeps clean builds in sync
define version=0
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- totalGHGEmissions
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('totalLocationBasedGHGEmissions', 'Metric Tons CO2e', 0, 'Total (Location-Based) GHG Emissions');

UPDATE csr.est_building_metric SET metric_name = 'totalLocationBasedGHGEmissions' WHERE metric_name = 'totalGHGEmissions';
UPDATE csr.est_building_metric_mapping SET metric_name = 'totalLocationBasedGHGEmissions' WHERE metric_name = 'totalGHGEmissions';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'totalGHGEmissions';

-- totalGHGEmissionsIntensity
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('totalLocationBasedGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Total (Location-Based) GHG Emissions Intensity');

UPDATE csr.est_building_metric SET metric_name = 'totalLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'totalGHGEmissionsIntensity';
UPDATE csr.est_building_metric_mapping SET metric_name = 'totalLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'totalGHGEmissionsIntensity';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'totalGHGEmissionsIntensity';

-- medianTotalGHGEmissions
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('medianTotalLocationBasedGHGEmissions', 'Metric Tons CO2e', 0, 'National Median Total (Location-Based) GHG Emissions');

UPDATE csr.est_building_metric SET metric_name = 'medianTotalLocationBasedGHGEmissions' WHERE metric_name = 'medianTotalGHGEmissions';
UPDATE csr.est_building_metric_mapping SET metric_name = 'medianTotalLocationBasedGHGEmissions' WHERE metric_name = 'medianTotalGHGEmissions';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'medianTotalGHGEmissions';

-- indirectGHGEmissions
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('indirectLocationBasedGHGEmissions', 'Metric Tons CO2e', 0, 'Indirect (Location-Based) GHG Emissions');

UPDATE csr.est_building_metric SET metric_name = 'indirectLocationBasedGHGEmissions' WHERE metric_name = 'indirectGHGEmissions';
UPDATE csr.est_building_metric_mapping SET metric_name = 'indirectLocationBasedGHGEmissions' WHERE metric_name = 'indirectGHGEmissions';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'indirectGHGEmissions';

-- indirectGHGEmissionsIntensity
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('indirectLocationBasedGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Indirect (Location-Based) GHG Emissions Intensity');

UPDATE csr.est_building_metric SET metric_name = 'indirectLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'indirectGHGEmissionsIntensity';
UPDATE csr.est_building_metric_mapping SET metric_name = 'indirectLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'indirectGHGEmissionsIntensity';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'indirectGHGEmissionsIntensity';

-- egridOutputEmissionsRate
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('emissionsFactorLocationBasedElectricity', 'kgCO2e/GJ', 0, 'Emissions Factor (Location-Based) – Electricity/eGRID');

UPDATE csr.est_building_metric SET metric_name = 'emissionsFactorLocationBasedElectricity' WHERE metric_name = 'egridOutputEmissionsRate';
UPDATE csr.est_building_metric_mapping SET metric_name = 'emissionsFactorLocationBasedElectricity' WHERE metric_name = 'egridOutputEmissionsRate';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'egridOutputEmissionsRate';

-- targetTotalGHGEmissions
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('targetTotalLocationBasedGHGEmissions', 'Metric Tons CO2e', 0, 'Target Total (Location-Based) GHG Emissions');

UPDATE csr.est_building_metric SET metric_name = 'targetTotalLocationBasedGHGEmissions' WHERE metric_name = 'targetTotalGHGEmissions';
UPDATE csr.est_building_metric_mapping SET metric_name = 'targetTotalLocationBasedGHGEmissions' WHERE metric_name = 'targetTotalGHGEmissions';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'targetTotalGHGEmissions';

-- targetTotalGHGEmissionsIntensity
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('targetTotalLocationBasedGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Target Total (Location-Based) GHG Emissions Intensity');

UPDATE csr.est_building_metric SET metric_name = 'targetTotalLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'targetTotalGHGEmissionsIntensity';
UPDATE csr.est_building_metric_mapping SET metric_name = 'targetTotalLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'targetTotalGHGEmissionsIntensity';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'targetTotalGHGEmissionsIntensity';

-- designTargetTotalGHGEmissions
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('designTargetTotalLocationBasedGHGEmissions', 'Metric Tons CO2e', 0, 'Design Target Total (Location-Based) GHG Emissions');

UPDATE csr.est_building_metric SET metric_name = 'designTargetTotalLocationBasedGHGEmissions' WHERE metric_name = 'designTargetTotalGHGEmissions';
UPDATE csr.est_building_metric_mapping SET metric_name = 'designTargetTotalLocationBasedGHGEmissions' WHERE metric_name = 'designTargetTotalGHGEmissions';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'designTargetTotalGHGEmissions';

-- designTargetTotalGHGEmissionsIntensity
INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
VALUES ('designTargetTotalLocationBasedGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Design Target Total (Location-Based) GHG Emissions Intensity');

UPDATE csr.est_building_metric SET metric_name = 'designTargetTotalLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'designTargetTotalGHGEmissionsIntensity';
UPDATE csr.est_building_metric_mapping SET metric_name = 'designTargetTotalLocationBasedGHGEmissionsIntensity' WHERE metric_name = 'designTargetTotalGHGEmissionsIntensity';

DELETE FROM csr.est_attr_for_building WHERE attr_name = 'designTargetTotalGHGEmissionsIntensity';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
