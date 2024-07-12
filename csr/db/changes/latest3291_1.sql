-- Please update version.sql too -- this keeps clean builds in sync
define version=3291
define minor_version=1
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
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1000,1,'gresb_asset_id','integer','Unique GRESB Asset ID. Generated automatically when creating a new asset. Can be uploaded into 360 for pre-existing assets.','',NULL,1,'Property''s GRESB asset id. The asset ID is recorded when a GRESB asset is created or can be uploaded for pre-existing assets. If we have an ID, we will update the specified asset, otherwise we will attempt to create it.');
UPDATE csr.gresb_indicator
	SET description='Gross asset value of the asset at the end of the reporting period. This is in millions of the relevant currency.'
	WHERE gresb_indicator_id=1011;
-- en_data_from
UPDATE csr.gresb_indicator
	SET sm_description='The first date within the reporting year for which any field beginning with en_ has data'
	WHERE gresb_indicator_id=1054;
-- en_data_to
UPDATE csr.gresb_indicator
	SET sm_description='The last date within the reporting year for which any field beginning with en_ has data'
	WHERE gresb_indicator_id=1055; 
-- wat_data_from
UPDATE csr.gresb_indicator
	SET sm_description='The first date within the reporting year for which any field beginning with wat_ has data'
	WHERE gresb_indicator_id=1125; 
-- wat_data_to
UPDATE csr.gresb_indicator
	SET sm_description='The last date within the reporting year for which any field beginning with wat_ has data'
	WHERE gresb_indicator_id=1126; 
-- was_data_from
UPDATE csr.gresb_indicator
	SET sm_description='The first date within the reporting year for which any field beginning with was_ has data'
	WHERE gresb_indicator_id=1148; 
-- was_data_to
UPDATE csr.gresb_indicator
	SET sm_description='The last date within the reporting year for which any field beginning with was_ has data'
	WHERE gresb_indicator_id=1149; 
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1159,1,'partners_id','integer','360 provided Asset ID to ensure correct mapping within 360.','',NULL,1,'Property''s region sid.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
