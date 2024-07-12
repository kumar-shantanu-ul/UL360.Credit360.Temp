-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=17
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
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28221, 13, '1/m', 1, 1, 0, 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
