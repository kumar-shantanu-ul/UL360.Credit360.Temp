-- Please update version.sql too -- this keeps clean builds in sync
define version=2876
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
  28172, 17, 'TJ/ton', 0.000000000907184740760757, 1, 0, 1
);
-- ** New package grants **

-- *** Packages ***

@update_tail
