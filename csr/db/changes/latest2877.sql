-- Please update version.sql too -- this keeps clean builds in sync
define version=2877
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
INSERT INTO csr.std_measure_conversion (
  std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
) VALUES (
  28173, 17, 'TJ/t', 0.000000001, 1, 0, 1
);
-- ** New package grants **

-- *** Packages ***

@update_tail
