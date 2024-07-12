-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
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
BEGIN
	INSERT INTO csr.std_measure (
		std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd
	) VALUES (
		41, 'm.s^2/kg', 'm.s^2/kg', 0, '#,##0', 'sum', NULL, 0, 1, -1, 2, 0, 0, 0, 0
	);

	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28195, 3, 'm^3/m^2', 1, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28196, 5, 'cGal (UK)', 2.1997360, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28197, 5, 'cGal (US)', 2.64200793, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28198, 5, 'kcf', 0.03531073, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28199, 5, 'Kcm', 0.001, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28200, 5, 'MCF', 0.0000353144754, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28201, 5, 'MGal (UK)', 0.0002199736, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28202, 5, 'MGal (US)', 0.0002642008, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28203, 27, 'g/m^2', 1000, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28204, 3, 'cm', 100, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28205, 41, 'l/MJ', 1000000000, 1, 0, 1);
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
