-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=8
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

	UPDATE csr.batch_job
	   SET result ='Cancelled by cr360, ref: DE4660',
	   	   completed_dtm = SYSDATE
	 WHERE batch_job_type_id = 47
	   AND attempts > 1
	   AND completed_dtm IS NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
