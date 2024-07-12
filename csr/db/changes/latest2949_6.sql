-- Please update version.sql too -- this keeps clean builds in sync
define version=2949
define minor_version=6
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
INSERT INTO csr.std_measure_conversion (
	std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
) VALUES (
	28186, 16, '1/ft^2', 0.09290304, 1, 0, 1
);
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
