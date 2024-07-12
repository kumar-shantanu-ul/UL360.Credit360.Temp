-- Please update version.sql too -- this keeps clean builds in sync
define version=3154
define minor_version=0
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
BEGIN
	UPDATE csr.batch_job_type
	   SET max_retries = 3
	 WHERE batch_job_type_id = 34;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
