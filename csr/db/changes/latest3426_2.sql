-- Please update version.sql too -- this keeps clean builds in sync
define version=3426
define minor_version=2
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
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1162,1,'asset_ownership','Decimal','Percentage of the asset owned by the reporting entity.','%',NULL);
	
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
