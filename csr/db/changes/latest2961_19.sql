-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=19
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
BEGIN
	UPDATE csr.std_measure_conversion
	   SET std_measure_id = 13,
	       a = 0.000000001
	 WHERE std_measure_conversion_id = 28181;

	UPDATE csr.std_measure_conversion
	   SET std_measure_id = 21
	 WHERE std_measure_conversion_id = 28182;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
