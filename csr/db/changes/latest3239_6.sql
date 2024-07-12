-- Please update version.sql too -- this keeps clean builds in sync
define version=3239
define minor_version=6
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

INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (113, 1, 'asset_gav', 'x > 0', 'Gross asset value of the asset at the end of the reporting period. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (114, 1, 'directly_managed', '[Y, N, null]', 'Did the company/fund manager have operational control over the asset?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (115, 1, 'whole_building', '[Y, N, null]', 'Is the energy consumption data of the asset collected for the whole building (TRUE) or separately for base building and tenant space (FALSE)?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (116, 1, 'dc_change_energy', '[Y, N, null]', 'Did the energy data coverage for this asset change over the last two years? ', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (117, 1, 'dc_change_water', '[Y, N, null]', 'Did the water data coverage for this asset change over the last two years?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (118, 1, 'asset_vacancy', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Average annual vacancy.', '%', NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
