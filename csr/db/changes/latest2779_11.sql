-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=11
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
-- FB 73431
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
	VALUES (28168, 5, 'BBL', 6.28981056977507008421427, 1, 0, 1);
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
	VALUES (28169, 24, '1/BBL', 0.1589873, 1, 0, 1);

-- FB 72407
INSERT INTO csr.STD_MEASURE (STD_MEASURE_ID, NAME, DESCRIPTION, SCALE, FORMAT_MASK, REGIONAL_AGGREGATION, CUSTOM_FIELD, PCT_OWNERSHIP_APPLIES, M, KG, S, A, K, MOL, CD) 
	VALUES (37, 'm.kg^-1', 'm.kg^-1', 0, '#,##0', 'sum', NULL, 0, 1, -1, 0, 0, 0, 0, 0);
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
	VALUES (28170, 13, 'mm/hectare', 10000000, 1, 0, 1);	
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) 
	VALUES (28171, 37, 'mm/tonne', 1000000, 1, 0, 1);
-- ** New package grants **

-- *** Packages ***

@update_tail
