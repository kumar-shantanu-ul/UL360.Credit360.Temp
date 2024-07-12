-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=20
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
-- FB93844 : Rate per million kilometres
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible)
VALUES (28181,3,'1/1000000km',0.000000000001,1,0,1);

-- FB93844 : Rate per 200,000 hours
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible)
VALUES (28182,3,'1/200000hrs',0.00000000138889,1,0,1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
