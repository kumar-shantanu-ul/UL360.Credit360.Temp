-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28214, 4, 'GBTU (UK)', 1/1055055852620, 1, 0, 1);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28215, 4, 'GBTU (US)', 1/1054804000000, 1, 0, 1);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28216, 4, 'GBTU (EC)', 1/1055060000000, 1, 0, 1);
	
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28217, 9, 'kg/GBTU (UK)', 1055055852620, 1, 0, 0);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28218, 9, 'kg/GBTU (US)', 1054804000000, 1, 0, 0);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28219, 9, 'kg/GBTU (EC)', 1055060000000, 1, 0, 0);
	
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
