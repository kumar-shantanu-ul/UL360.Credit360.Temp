-- Please update version.sql too -- this keeps clean builds in sync
define version=3145
define minor_version=2
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
UPDATE CSR.STD_MEASURE_CONVERSION
   SET A = 0.000000277777777780
 WHERE STD_MEASURE_CONVERSION_ID = 105;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
