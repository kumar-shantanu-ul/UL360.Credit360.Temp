-- Please update version.sql too -- this keeps clean builds in sync
define version=2962
define minor_version=0
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
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28184, 17, 'TJ/Gg', 0.000001, 1, 0, 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\approval_dashboard_body

@update_tail
