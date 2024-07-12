-- Please update version.sql too -- this keeps clean builds in sync
define version=3239
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.gresb_submission_log MODIFY (gresb_response_id NULL);
ALTER TABLE csr.gresb_submission_log ADD gresb_entity_id VARCHAR2(255);
ALTER TABLE csr.gresb_submission_log ADD gresb_asset_id VARCHAR2(255);
ALTER TABLE csr.gresb_submission_log ADD
CONSTRAINT CK_GRESB_SL_ID_VALID CHECK ((gresb_response_id IS NOT NULL AND gresb_entity_id IS NULL) OR (gresb_response_id IS NULL AND gresb_entity_id IS NOT NULL));

ALTER TABLE csrimp.gresb_submission_log MODIFY (gresb_response_id NULL);
ALTER TABLE csrimp.gresb_submission_log ADD gresb_entity_id VARCHAR2(255);
ALTER TABLE csrimp.gresb_submission_log ADD gresb_asset_id VARCHAR2(255);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.gresb_service_config 
   SET client_id = '0344060dc551526374f7cc9ed81f1f4fdfe91aeb9583702bebfe22e0b6ee354a',
	   client_secret = 'c87b4fbf1a47dae958ac885818708c6e322457bce2c7060a745eca9545063bdc'
 WHERE name = 'sandbox';

INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (105, 1, 'new_construction', '[Y, N, null]', 'Was the asset under construction during the reporting period?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (106, 1, 'new_construction_completed', '[Y, N, null]', 'Was the new construction project completed during the last year of the reporting period?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (107, 1, 'major_renovation_completed', '[Y, N, null]', 'Was the major renovation completed during the last year of the reporting period?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (108, 1, 'asset_size_common', 'x > 0', 'Floor area size of the common areas in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (109, 1, 'asset_size_shared', 'x > 0', 'Floor area size of the shared service areas in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (110, 1, 'asset_size_tenant', 'x > 0', 'Floor area size of the entire Tenant Space in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (111, 1, 'asset_size_tenant_landlord', 'x > 0', 'Floor area size of the tenant space areas where energy was purchased by the landlord in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (112, 1, 'asset_size_tenant_tenant', 'x > 0', 'Floor area size of the tenant space areas where energy was purchased by the tenant in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../gresb_config_pkg

@../csr_app_body
@../enable_body
@../gresb_config_body
@../indicator_body
@../scenario_body
@../scenario_run_body
@../schema_body

@../csrimp/imp_body

@update_tail
