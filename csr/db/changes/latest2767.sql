-- Please update version.sql too -- this keeps clean builds in sync
define version=2767
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
-- RLS

-- Data
UPDATE csr.std_measure_conversion 
   SET description = 'MWh/t' 
 WHERE std_measure_conversion_id = 28132;
 
-- ** New package grants **

-- *** Packages ***

@update_tail
