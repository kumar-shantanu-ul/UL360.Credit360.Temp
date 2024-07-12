-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=8
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
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28213, 30, 'Kelvin', 1, 1, 0, 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
