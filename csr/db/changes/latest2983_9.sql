-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=9
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
	security.user_pkg.LogonAdmin;
	
	UPDATE chain.higg_question_option
	   SET std_measure_conversion_id = 4
	 WHERE measure_conversion = 'tonnes (metric)';
	
	UPDATE chain.higg_question_option
	   SET std_measure_conversion_id = 32,
	       measure_conversion = 'MMBTU'
	 WHERE higg_question_option_id = 2852; /* MMBTU (UK) */
	 
	UPDATE chain.higg_question_option
	   SET std_measure_conversion_id = 50,
	       measure_conversion = 'TJ'
	 WHERE higg_question_option_id = 2855; /* TJ */
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
