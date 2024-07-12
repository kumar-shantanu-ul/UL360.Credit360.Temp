-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3, is_standard)
	VALUES ('cw', 'Curacao', 12.7, -68.6, 444, 'SA', 'ANG', 'cuw', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
	INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3, is_standard)
	VALUES ('bq', 'Bonaire, Sint Eustatius and Saba', 12.11, -68.14, 328, 'SA', 'USD', 'bes', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
	INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3, is_standard)
	VALUES ('sx', 'Sint Maarten', 18.02, -63.03, 34, 'SA', 'ANG', 'sxm', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- ** New package grants **

-- *** Packages ***

@update_tail
