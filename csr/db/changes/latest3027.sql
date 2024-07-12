-- Please update version.sql too -- this keeps clean builds in sync
define version=3027
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
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.period_interval
	   SET single_interval_no_year_label = 'Q{0:I}'
	 WHERE period_set_id = 1
	   AND period_interval_id = 2
	   AND label ='Quarterly' 
	   AND single_interval_no_year_label = 'H{0:I}';

	UPDATE csr.period_interval
	   SET single_interval_no_year_label = 'H{0:I}'
	 WHERE period_set_id = 1
	   AND period_interval_id = 3
	   AND label ='Half-yearly'
	   AND single_interval_no_year_label = 'Q{0:I}';

	security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/
   
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
