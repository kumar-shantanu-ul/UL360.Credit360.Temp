-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=11
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
UPDATE csr.factor_type
   SET std_measure_id = 1
 WHERE name like '%(Mass)%'
   AND std_measure_id != 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
