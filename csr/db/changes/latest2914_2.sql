-- Please update version.sql too -- this keeps clean builds in sync
define version=2914
define minor_version=2
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
BEGIN
	INSERT INTO CSR.STD_MEASURE (STD_MEASURE_ID, NAME, DESCRIPTION, SCALE, FORMAT_MASK, REGIONAL_AGGREGATION, CUSTOM_FIELD, PCT_OWNERSHIP_APPLIES, M, KG, S, A, K, MOL, CD) VALUES (38, 'kg.s^-1', 'kg.s^-1', 0, '#,##0', 'sum', NULL, 0, 0, 1, -1, 0, 0, 0, 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28176, 38, 'tonne/minute', 0.05999999988, 1, 0, 1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28177, 38, 'ton/minute', 0.06613867850965, 1, 0, 1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
