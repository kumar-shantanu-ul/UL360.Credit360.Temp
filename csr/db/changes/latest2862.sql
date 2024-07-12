-- Please update version.sql too -- this keeps clean builds in sync
define version=2862
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
UPDATE csr.std_measure_conversion SET a=0.45359237 WHERE std_measure_conversion_id = 26046;
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
