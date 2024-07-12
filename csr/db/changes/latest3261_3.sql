-- Please update version.sql too -- this keeps clean builds in sync
define version=3261
define minor_version=3
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

UPDATE csr.factor_type
   SET std_measure_id = (SELECT std_measure_id from csr.std_measure WHERE name = 'kg/m')
 WHERE name = 'Air Passenger Distance - International - Average Class (+8% uplift) (Direct)';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
