-- Please update version.sql too -- this keeps clean builds in sync
define version=3384
define minor_version=5
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
	VALUES (1160,1,'certifications','Certifications','GRESB asset certifications.',NULL,NULL,1,'Property certifications');

INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1161, 1, 'ratings', 'Ratings', 'GRESB asset ratings.', NULL, NULL, 1, 'Property ratings');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
