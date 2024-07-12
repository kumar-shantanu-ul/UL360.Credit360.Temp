-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=3
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
DECLARE
	v_has_measure	NUMBER:=0;
BEGIN
	SELECT COUNT(*)
	  INTO v_has_measure
	  FROM csr.std_measure
	 WHERE std_measure_id = 42;
	 
	IF v_has_measure > 0 THEN
		GOTO has_measure;
	END IF;
	
	INSERT INTO csr.std_measure (
		std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd
	) VALUES (
		42, 's^2/m^5', 's^2/m^5', 0, '#,##0', 'sum', NULL, 0, -5, 0, 2, 0, 0, 0, 0
	);

	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28206, 18, 'GJ/m^2', 0.000000001, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28207, 24, 'GJ/(m^3.PJ)', 1000000, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28208, 42, 'kg/(m^3.PJ)', 1000000000000000, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28209, 24, 'kWh/(m^3.PJ)', 277777777.78, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28210, 35, 'm^3/day', 86400, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28211, 35, 'MGal (UK)/day', 19.005335, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28212, 35, 'MGal (US)/day', 22.824465, 1, 0, 1);
	
	<<has_measure>>
	NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
