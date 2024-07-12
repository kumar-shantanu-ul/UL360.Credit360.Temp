-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id,std_measure_id,description,a,b,c) VALUES (28174,10,'kg/(short ton.mile)',1,1,0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id,std_measure_id,description,a,b,c) VALUES (28175,10,'g/(short ton.mile)',1,1,0);

UPDATE csr.std_factor SET std_measure_conversion_id = 28174 WHERE std_measure_conversion_id = 1237 AND std_factor_set_id = 51;
UPDATE csr.std_factor SET std_measure_conversion_id = 28175 WHERE std_measure_conversion_id = 1293 AND std_factor_set_id = 51;

-- ** New package grants **

-- *** Packages ***

@update_tail
